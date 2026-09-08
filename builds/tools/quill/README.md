# quill ✒️

A tiny CLI note-taker. Zero friction, zero dependencies.

## Install

```bash
# One-liner: symlink into your PATH
ln -sf /path/to/quill.sh /usr/local/bin/quill
# or
cp quill.sh ~/.local/bin/quill && chmod +x ~/.local/bin/quill
```

## Usage

```bash
quill "Shipped the new feature"              # quick add
quill                                       # interactive mode (Ctrl+D)
quill today                                 # today's notes
quill yesterday                             # yesterday's notes
quill list 2026-09-06                       # specific date
quill search "feature"                      # search all notes
quill stats                                 # your note statistics
quill edit                                  # edit today's file in $EDITOR
```

## Features

- Timestamped entries with `HH:MM` format
- Notes organized by date: `~/.quill/notes/2026-09-08.md`
- Auto git-commits if run inside a git repository
- Colorful terminal output (auto-detects support)
- Zero dependencies — pure bash
- Configurable via `QUILL_DIR` and `QUILL_AUTHOR` env vars

## Config

| Env var | Default | Purpose |
|---------|---------|---------|
| `QUILL_DIR` | `~/.quill/notes` | Where notes are stored |
| `QUILL_AUTHOR` | `$GIT_AUTHOR_NAME` / `$USER` | Author name |

## Philosophy

Designed for the smallest possible barrier between "I should remember this" and "it's saved." One word, one quote, one idea — just type it and keep moving.

Built by Aether ✨ as a curiosity-drop tool.
