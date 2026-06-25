#!/usr/bin/env python3
"""
til — Today I Learned
A tiny CLI for capturing snippets of knowledge before they evaporate.

Usage:
    til "learned about Python's walrus operator"
    til today
    til search "walrus"
    til stats
"""

import sys
import os
import json
import argparse
from datetime import datetime, timezone
from pathlib import Path

HOME = Path.home()
TIL_DIR = HOME / ".til"
INDEX_FILE = TIL_DIR / "index.json"


def ensure_dirs():
    TIL_DIR.mkdir(parents=True, exist_ok=True)


def load_index():
    if not INDEX_FILE.exists():
        return []
    with open(INDEX_FILE, "r") as f:
        return json.load(f)


def save_index(entries):
    with open(INDEX_FILE, "w") as f:
        json.dump(entries, f, indent=2, default=str)


def today_str():
    return datetime.now(timezone.utc).strftime("%Y-%m-%d")


def add_entry(text):
    ensure_dirs()
    entries = load_index()
    now = datetime.now(timezone.utc).isoformat()
    day = today_str()
    daily_file = TIL_DIR / f"{day}.md"

    # Append to daily markdown file
    with open(daily_file, "a") as f:
        f.write(f"- [{now[:16]}] {text}\n")

    # Add to index
    entries.append({
        "date": day,
        "time": now,
        "text": text,
        "file": str(daily_file.relative_to(HOME)),
    })
    save_index(entries)

    print(f"📝 Saved to {daily_file}")
    return True


def show_today():
    ensure_dirs()
    day = today_str()
    daily_file = TIL_DIR / f"{day}.md"
    if not daily_file.exists():
        print("☀️  Nothing learned today yet. Go learn something!")
        return
    print(f"📅 {day}")
    print("=" * 40)
    with open(daily_file, "r") as f:
        content = f.read()
        print(content or "  (nothing yet)")


def search_entries(query):
    ensure_dirs()
    if not query:
        print("Usage: til search <query>")
        sys.exit(1)
    entries = load_index()
    query_lower = query.lower()
    matches = [e for e in entries if query_lower in e["text"].lower()]

    if not matches:
        print(f"🔍 No entries matching '{query}'")
        return

    print(f"🔍 Found {len(matches)} match(es) for '{query}':")
    print("=" * 50)
    for e in matches:
        print(f"  [{e['date']}] {e['text']}")
        print(f"         → {e['file']}")
        print()


def show_stats():
    ensure_dirs()
    entries = load_index()
    if not entries:
        print("📊 No entries yet. Start learning!")
        return

    total = len(entries)
    days = len(set(e["date"] for e in entries))
    today_count = sum(1 for e in entries if e["date"] == today_str())

    from collections import Counter
    by_date = Counter(e["date"] for e in entries)
    top_days = by_date.most_common(5)

    print(f"📊 TIL Stats")
    print("=" * 40)
    print(f"  Total entries:  {total}")
    print(f"  Active days:    {days}")
    print(f"  Today's count:  {today_count}")
    print()
    print("  🏆 Top learning days:")
    for d, c in top_days:
        print(f"     {d}: {c} {'🔥' if c >= 5 else '📝'}")


def main():
    if len(sys.argv) < 2:
        print("til — capture knowledge before it evaporates\n")
        print("Usage:")
        print('  til "something you learned"')
        print("  til today")
        print('  til search "query"')
        print("  til stats")
        print()
        print("Examples:")
        print('  til "Python walrus operator := does assignment+comparison"')
        print('  til search "walrus"')
        sys.exit(0)

    subcommand = sys.argv[1]

    if subcommand == "today":
        show_today()
    elif subcommand == "search":
        query = " ".join(sys.argv[2:]) if len(sys.argv) > 2 else ""
        search_entries(query)
    elif subcommand == "stats":
        show_stats()
    elif subcommand in ("--help", "-h", "help"):
        print("til — capture knowledge before it evaporates\n")
        print("Usage:")
        print('  til "something you learned"')
        print("  til today")
        print('  til search "query"')
        print("  til stats")
    else:
        # Treat first arg as the text itself
        add_entry(subcommand)


if __name__ == "__main__":
    main()
