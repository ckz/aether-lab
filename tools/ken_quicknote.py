#!/usr/bin/env python3
"""
ken_quicknote.py
A tiny CLI to quickly capture timestamped notes and instantly search recent notes.

Usage:
  python3 ken_quicknote.py add "Idea: build a tiny AI radio"
  python3 ken_quicknote.py list
  python3 ken_quicknote.py find ai
"""

from __future__ import annotations

import argparse
from datetime import datetime, timezone
from pathlib import Path
import sys

NOTE_FILE = Path.home() / "notes" / "ken-quicknotes.md"


def ensure_file() -> None:
    NOTE_FILE.parent.mkdir(parents=True, exist_ok=True)
    if not NOTE_FILE.exists():
        NOTE_FILE.write_text("# Ken Quicknotes\n\n", encoding="utf-8")


def now_utc() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")


def add_note(text: str) -> None:
    ensure_file()
    entry = f"- [{now_utc()}] {text.strip()}\n"
    with NOTE_FILE.open("a", encoding="utf-8") as f:
        f.write(entry)
    print(f"Saved: {entry.strip()}")
    print(f"File: {NOTE_FILE}")


def list_notes(limit: int = 20) -> None:
    ensure_file()
    lines = NOTE_FILE.read_text(encoding="utf-8").splitlines()
    notes = [ln for ln in lines if ln.startswith("- [")]
    for ln in notes[-limit:]:
        print(ln)
    if not notes:
        print("No notes yet.")


def find_notes(query: str, limit: int = 20) -> None:
    ensure_file()
    q = query.lower()
    lines = NOTE_FILE.read_text(encoding="utf-8").splitlines()
    matches = [ln for ln in lines if ln.startswith("- [") and q in ln.lower()]
    for ln in matches[-limit:]:
        print(ln)
    if not matches:
        print(f"No matches for: {query}")


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description="Ken's tiny quicknote tool")
    sub = p.add_subparsers(dest="cmd", required=True)

    p_add = sub.add_parser("add", help="Add a timestamped note")
    p_add.add_argument("text", nargs="+", help="Note text")

    p_list = sub.add_parser("list", help="List recent notes")
    p_list.add_argument("--limit", type=int, default=20)

    p_find = sub.add_parser("find", help="Search notes")
    p_find.add_argument("query")
    p_find.add_argument("--limit", type=int, default=20)

    return p


def main(argv: list[str]) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)

    if args.cmd == "add":
        add_note(" ".join(args.text))
    elif args.cmd == "list":
        list_notes(args.limit)
    elif args.cmd == "find":
        find_notes(args.query, args.limit)
    else:
        parser.print_help()
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
