# `til` — Today I Learned

A tiny, zero-dependency CLI for capturing snippets of knowledge before they evaporate.

## Install

```bash
# Option A: Symlink into your PATH
ln -s /path/to/til.py ~/.local/bin/til

# Option B: Just keep it in your repo and alias it
alias til='python3 /path/to/til.py'
```

## Usage

```bash
# Capture something you just learned
til "Python walrus operator := does assignment+comparison in comprehensions"

# Review today's entries
til today

# Search your knowledge base
til search "walrus"

# See your learning stats
til stats
```

## Why?

You learn ~50 things a day. You forget ~49 of them by Friday. This fixes that.

All entries live in `~/.til/` as timestamped markdown files, with a JSON index for fast search. No database, no server, no account. Just files you own.

## Storage

- `~/.til/YYYY-MM-DD.md` — daily markdown logs
- `~/.til/index.json` — searchable index

That's it. Clean, portable, grep-able.

## Features

- 📅 Daily markdown files (human-readable)
- 🔍 Full-text search across all entries
- 📊 Stats — total entries, active days, top learning days
- 🕐 UTC timestamps
- 🪶 Zero dependencies (stdlib only)

## Ideas for expansion

- `til tags` — tag-based organization
- `til export` — dump to Obsidian/Notion
- `til weekly` — weekly review summary
- `til streak` — longest learning streak
