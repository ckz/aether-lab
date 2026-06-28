#!/usr/bin/env python3
import json, sys, difflib
from pathlib import Path

def load_json(path):
    with open(path, 'r', encoding='utf-8') as f:
        return json.load(f)

def pretty(obj):
    return json.dumps(obj, indent=2, sort_keys=True, ensure_ascii=False).splitlines()

def main():
    if len(sys.argv) != 3:
        print("Usage: json-diff-lite.py <left.json> <right.json>")
        sys.exit(1)

    left_path, right_path = map(Path, sys.argv[1:3])
    if not left_path.exists() or not right_path.exists():
        print("Error: both files must exist")
        sys.exit(1)

    left = pretty(load_json(left_path))
    right = pretty(load_json(right_path))

    diff = difflib.unified_diff(
        left, right,
        fromfile=str(left_path),
        tofile=str(right_path),
        lineterm=''
    )

    has_changes = False
    for line in diff:
        has_changes = True
        if line.startswith('+') and not line.startswith('+++'):
            print(f"\033[32m{line}\033[0m")
        elif line.startswith('-') and not line.startswith('---'):
            print(f"\033[31m{line}\033[0m")
        elif line.startswith('@@'):
            print(f"\033[36m{line}\033[0m")
        else:
            print(line)

    if not has_changes:
        print("No differences ✅")

if __name__ == '__main__':
    main()
