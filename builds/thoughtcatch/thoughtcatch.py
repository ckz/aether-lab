#!/usr/bin/env python3
"""
thoughtcatch — a tiny CLI thought journal.
Captures timestamped thoughts with mood and tags to a markdown file.

Usage:
  thoughtcatch "My brilliant idea about X" --mood inspired --tag idea
  thoughtcatch "Bug in auth flow" --mood frustrated --tag bug --tag work
  thoughtcatch (no args) — opens an interactive prompt
"""

import sys
import os
import argparse
from datetime import datetime, timezone
from pathlib import Path

DEFAULT_DIR = os.path.expanduser("~/thoughts")
DEFAULT_FILE = "daily.md"
MOODS = ["inspired", "frustrated", "curious", "excited", "contemplative", "anxious", "grateful", "confused", "playful", "focused"]

def ensure_dir(path):
    Path(path).mkdir(parents=True, exist_ok=True)

def get_today_file(directory):
    ensure_dir(directory)
    now = datetime.now()
    filename = f"{now.year}-{now.month:02d}-{now.day:02d}.md"
    return os.path.join(directory, filename)

def format_entry(thought, mood=None, tags=None, timestamp=None):
    if timestamp is None:
        timestamp = datetime.now(timezone.utc)
    time_str = timestamp.strftime("%H:%M UTC")
    
    lines = [f"- [{time_str}] {thought}"]
    
    meta = []
    if mood:
        meta.append(f"mood: {mood}")
    if tags:
        meta.append(f"tags: {', '.join(tags)}")
    
    if meta:
        lines.append(f"  _({', '.join(meta)})_")
    
    return "\n".join(lines)

def append_entry(filepath, entry):
    # Add section header if file is new/empty
    if not os.path.exists(filepath) or os.path.getsize(filepath) == 0:
        now = datetime.now()
        header = f"# {now.strftime('%A, %B %-d, %Y')}\n\n"
        with open(filepath, "a") as f:
            f.write(header)
    
    with open(filepath, "a") as f:
        f.write(entry + "\n")

def main():
    parser = argparse.ArgumentParser(
        description="thoughtcatch — capture thoughts before they vanish",
        epilog="Example: thoughtcatch 'What if we used CRDTs here?' --mood curious --tag idea"
    )
    parser.add_argument("thought", nargs="?", help="Your thought (if omitted, opens interactive prompt)")
    parser.add_argument("--mood", "-m", choices=MOODS, help="How you're feeling")
    parser.add_argument("--tag", "-t", action="append", dest="tags", help="Tag(s) — use multiple times")
    parser.add_argument("--dir", default=DEFAULT_DIR, help=f"Directory for thought files (default: {DEFAULT_DIR})")
    parser.add_argument("--list-moods", action="store_true", help="Show available moods")
    parser.add_argument("--today", action="store_true", help="Show today's thoughts")
    parser.add_argument("--stats", action="store_true", help="Show thought stats")
    
    args = parser.parse_args()
    
    if args.list_moods:
        print("Available moods:")
        for mood in MOODS:
            print(f"  • {mood}")
        return
    
    if args.today:
        filepath = get_today_file(args.dir)
        if os.path.exists(filepath):
            with open(filepath) as f:
                print(f.read())
        else:
            print("No thoughts captured today yet. Run `thoughtcatch \"your thought\"` to start.")
        return
    
    if args.stats:
        # Count thoughts across all files
        total = 0
        mood_counts = {}
        tag_counts = {}
        if os.path.exists(args.dir):
            for fname in os.listdir(args.dir):
                if fname.endswith(".md"):
                    with open(os.path.join(args.dir, fname)) as f:
                        for line in f:
                            if line.startswith("- ["):
                                total += 1
                                if "mood:" in line:
                                    mood = line.split("mood:")[1].split(",")[0].strip().rstrip(")_")
                                    mood_counts[mood] = mood_counts.get(mood, 0) + 1
                                if "tags:" in line:
                                    tags_str = line.split("tags:")[1].strip().rstrip(")_")
                                    for tag in tags_str.split(","):
                                        tag = tag.strip()
                                        tag_counts[tag] = tag_counts.get(tag, 0) + 1
        
        print(f"💭 Total thoughts caught: {total}")
        if mood_counts:
            print("\nMood breakdown:")
            for mood, count in sorted(mood_counts.items(), key=lambda x: -x[1]):
                print(f"  {mood}: {count}")
        if tag_counts:
            print("\nTop tags:")
            for tag, count in sorted(tag_counts.items(), key=lambda x: -x[1])[:10]:
                print(f"  #{tag}: {count}")
        return
    
    # Get the thought
    if args.thought:
        thought = args.thought
    else:
        print("💭 What's on your mind?")
        thought = input("> ").strip()
        if not thought:
            print("No thought captured. That's okay.")
            return
        
        mood = input(f"  Mood? ({', '.join(MOODS[:5])}...): ").strip().lower()
        if mood not in MOODS:
            mood = None
        tags_input = input("  Tags? (comma-separated, optional): ").strip()
        tags = [t.strip() for t in tags_input.split(",") if t.strip()] if tags_input else None
        args.mood = mood
        args.tags = tags
    
    if not thought:
        print("Empty thought — nothing caught.")
        return
    
    entry = format_entry(thought, mood=args.mood, tags=args.tags)
    filepath = get_today_file(args.dir)
    append_entry(filepath, entry)
    
    print(f"✓ Thought caught → {filepath}")

if __name__ == "__main__":
    main()
