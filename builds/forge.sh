#!/usr/bin/env bash
# forge — quick project scaffold tool
# Usage: forge <name> --type <node|python|rust|web|lib>
# Creates a new project directory with sensible defaults.

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
RESET='\033[0m'

usage() {
  cat <<EOF
${BOLD}forge${RESET} — scaffold a project in one command

${CYAN}Usage:${RESET}
  forge <name> --type <node|python|rust|web|lib>
  forge <name> --type cli   # shorthand for node CLI tool

${CYAN}Types:${RESET}
  node   Node.js package (src/, test/, README, MIT LICENSE)
  python Python project (src/<pkg>/, tests/, pyproject.toml, MIT LICENSE)
  rust   Rust project (src/, tests/, Cargo.toml, MIT LICENSE)
  web    Static website (index.html, style.css, script.js)
  lib    Minimal library skeleton (src/, README, MIT LICENSE)

${CYAN}Examples:${RESET}
  forge my-api --type node
  forge scraper --type python
  forge portfolio --type web
EOF
  exit 1
}

# Parse args
PROJECT_NAME=""
PROJECT_TYPE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --type)
      PROJECT_TYPE="$2"
      shift 2
      ;;
    -h|--help)
      usage
      ;;
    *)
      if [[ -z "$PROJECT_NAME" ]]; then
        PROJECT_NAME="$1"
        shift
      else
        echo -e "${RED}Unexpected argument: $1${RESET}"
        usage
      fi
      ;;
  esac
done

if [[ -z "$PROJECT_NAME" ]] || [[ -z "$PROJECT_TYPE" ]]; then
  echo -e "${RED}Error: name and --type are required${RESET}\n"
  usage
fi

# Validate type
case "$PROJECT_TYPE" in
  node|python|rust|web|lib|cli) ;;
  *)
    echo -e "${RED}Unknown type: $PROJECT_TYPE${RESET}"
    echo -e "Valid types: node, python, rust, web, lib, cli"
    exit 1
    ;;
esac

# Normalize cli → node
if [[ "$PROJECT_TYPE" == "cli" ]]; then
  PROJECT_TYPE="node"
  IS_CLI=true
else
  IS_CLI=false
fi

CURRENT_YEAR=$(date +%Y)
PROJECT_SLUG=$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-')
PY_PKG="${PROJECT_SLUG//-/_}"

# Check if directory already exists
if [[ -d "$PROJECT_NAME" ]]; then
  echo -e "${RED}Error: ./$PROJECT_NAME already exists${RESET}"
  exit 1
fi

echo -e "${CYAN}${BOLD}⚒  forging $PROJECT_NAME...${RESET}"
echo ""

create_dir() {
  mkdir -p "$PROJECT_NAME/$1"
}

write_file() {
  local path="$1"
  local content="$2"
  printf '%s' "$content" > "$PROJECT_NAME/$path"
}

# ─── NODE ───────────────────────────────────────────────────────────────
if [[ "$PROJECT_TYPE" == "node" ]]; then
  create_dir "src"
  create_dir "test"

  if $IS_CLI; then
    cat > "$PROJECT_NAME/package.json" <<PKGJSON
{
  "name": "$PROJECT_SLUG",
  "version": "0.1.0",
  "description": "$PROJECT_NAME",
  "bin": {
    "$PROJECT_SLUG": "src/index.js"
  },
  "type": "module",
  "scripts": {
    "start": "node src/index.js",
    "test": "node --test test/*.test.js"
  },
  "keywords": [],
  "author": "",
  "license": "MIT"
}
PKGJSON
    write_file "src/index.js" "#!/usr/bin/env node\n\nconst VERSION = '0.1.0';\n\nfunction main() {\n  console.log(\`\${process.argv[1] || 'tool'} v\${VERSION}\`);\n  // Your code here\n}\n\nmain();\n"
  else
    cat > "$PROJECT_NAME/package.json" <<PKGJSON
{
  "name": "$PROJECT_SLUG",
  "version": "0.1.0",
  "description": "$PROJECT_NAME",
  "main": "src/index.js",
  "type": "module",
  "scripts": {
    "start": "node src/index.js",
    "test": "node --test test/*.test.js"
  },
  "keywords": [],
  "author": "",
  "license": "MIT"
}
PKGJSON
    write_file "src/index.js" "#!/usr/bin/env node\n\n// $PROJECT_NAME — entry point\n\nexport function init() {\n  console.log('Hello from $PROJECT_NAME');\n}\n\ninit();\n"
  fi

  write_file "test/example.test.js" "import { test, describe } from 'node:test';\nimport assert from 'node:assert';\n\ndescribe('$PROJECT_NAME', () => {\n  test('placeholder', () => {\n    assert.strictEqual(true, true);\n  });\n});\n"

# ─── PYTHON ─────────────────────────────────────────────────────────────
elif [[ "$PROJECT_TYPE" == "python" ]]; then
  create_dir "src/$PY_PKG"
  create_dir "tests"

  cat > "$PROJECT_NAME/pyproject.toml" <<PYPROJ
[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[project]
name = "$PROJECT_SLUG"
version = "0.1.0"
description = "$PROJECT_NAME"
requires-python = ">=3.10"
license = {text = "MIT"}
readme = "README.md"

[tool.hatch.build.targets.wheel]
packages = ["src/$PY_PKG"]
PYPROJ

  cat > "$PROJECT_NAME/src/$PY_PKG/__init__.py" <<INITPY
"""$PROJECT_NAME"""

__version__ = '0.1.0'
INITPY

  cat > "$PROJECT_NAME/src/$PY_PKG/main.py" <<MAINPY
"""$PROJECT_NAME — entry point."""

def main() -> None:
    print('Hello from $PROJECT_NAME')


if __name__ == '__main__':
    main()
MAINPY

  cat > "$PROJECT_NAME/tests/test_main.py" <<TESTPY
def test_placeholder():
    assert True
TESTPY

# ─── RUST ───────────────────────────────────────────────────────────────
elif [[ "$PROJECT_TYPE" == "rust" ]]; then
  create_dir "src"
  create_dir "tests"

  cat > "$PROJECT_NAME/Cargo.toml" <<CARGO
[package]
name = "$PROJECT_SLUG"
version = "0.1.0"
edition = "2021"
description = "$PROJECT_NAME"
license = "MIT"
repository = ""
authors = []

[dependencies]
CARGO

  cat > "$PROJECT_NAME/src/main.rs" <<MAINRS
fn main() {
    println!("Hello from $PROJECT_NAME");
}
MAINRS

  cat > "$PROJECT_NAME/src/lib.rs" <<LIBRS
//! $PROJECT_NAME

pub fn init() {
    println!("Hello from $PROJECT_NAME");
}
LIBRS

  cat > "$PROJECT_NAME/tests/integration_test.rs" <<TESTRS
//! Integration tests

#[test]
fn it_works() {
    assert!(true);
}
TESTRS

# ─── WEB ────────────────────────────────────────────────────────────────
elif [[ "$PROJECT_TYPE" == "web" ]]; then
  create_dir "assets"
  create_dir "assets/images"

  cat > "$PROJECT_NAME/index.html" <<HTMLEOF
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>$PROJECT_NAME</title>
  <link rel="stylesheet" href="style.css" />
</head>
<body>
  <main>
    <h1>$PROJECT_NAME</h1>
    <p>Replace this with your content.</p>
  </main>
  <script src="script.js"></script>
</body>
</html>
HTMLEOF

  cat > "$PROJECT_NAME/style.css" <<'CSS'
* { box-sizing: border-box; margin: 0; padding: 0; }

body {
  font-family: system-ui, -apple-system, sans-serif;
  line-height: 1.6;
  color: #e0e0e0;
  background: #1a1a2e;
  min-height: 100vh;
}

main {
  max-width: 800px;
  margin: 0 auto;
  padding: 2rem;
}

h1 { margin-bottom: 1rem; color: #fff; }
p  { margin-bottom: 1rem; color: #b0b0b0; }
CSS

  cat > "$PROJECT_NAME/script.js" <<'JS'
// PROJECT_NAME — entry point

console.log('Ready.');
JS

# ─── LIB ────────────────────────────────────────────────────────────────
elif [[ "$PROJECT_TYPE" == "lib" ]]; then
  create_dir "src"
  create_dir "docs"

  cat > "$PROJECT_NAME/README.md" <<README
# $PROJECT_NAME

> A minimal library.

## Install

\`\`\`bash
npm install $PROJECT_SLUG
\`\`\`

## Usage

\`\`\`js
import { init } from '$PROJECT_SLUG';
init();
\`\`\`
README

  write_file "src/index.js" "// $PROJECT_NAME — library entry point\n\nexport function init() {\n  // Your code here\n}\n\nexport default { init };\n"
fi

# ─── COMMON FILES ───────────────────────────────────────────────────────

cat > "$PROJECT_NAME/.gitignore" <<GITIGNORE
# Dependencies
node_modules/
__pycache__/
*.pyc
target/
dist/
build/

# Env
.env
.env.*
!.env.example

# IDE
.idea/
.vscode/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Misc
*.log
*.pid
GITIGNORE

cat > "$PROJECT_NAME/LICENSE" <<LICENSE
MIT License

Copyright (c) $CURRENT_YEAR

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
LICENSE

cat > "$PROJECT_NAME/README.md" <<README
# $PROJECT_NAME

> Built with ${BOLD}forge${RESET}.

## Getting Started

\`\`\`bash
PROJECT_TYPE-start
\`\`\`

## License

MIT — see [LICENSE](LICENSE).
README

# Make entry points executable
chmod +x "$PROJECT_NAME/src/index.js" 2>/dev/null || true

echo -e "${GREEN}✔${RESET}  Created ${BOLD}$PROJECT_NAME/${RESET}"
echo -e "${GREEN}✔${RESET}  Type:      ${CYAN}$PROJECT_TYPE${RESET}"
echo -e "${GREEN}✔${RESET}  Files:     $(find "$PROJECT_NAME" -type f | wc -l)"
echo ""
echo -e "${CYAN}Next:${RESET}"
echo -e "  ${BOLD}cd $PROJECT_NAME${RESET}"
case "$PROJECT_TYPE" in
  node)   echo -e "  ${BOLD}npm install${RESET}  &&  ${BOLD}npm start${RESET}" ;;
  python) echo -e "  ${BOLD}pip install -e .${RESET}  &&  ${BOLD}python -m ${PY_PKG}.main${RESET}" ;;
  rust)   echo -e "  ${BOLD}cargo run${RESET}" ;;
  web)    echo -e "  ${BOLD}open index.html${RESET}" ;;
  lib)    echo -e "  ${BOLD}edit src/index.js${RESET}" ;;
esac
echo ""
echo -e "${YELLOW}⚒  forge — because every project deserves a good start${RESET}"
