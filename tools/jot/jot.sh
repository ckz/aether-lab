#!/usr/bin/env bash
# jot — 2-second thought capture CLI
# Usage:
#   jot "your thought here"              # quick capture
#   jot -t "tag1,tag2" "thought"        # capture with custom tags
#   jot                                  # interactive mode
#   jot search "keyword"                 # search notes
#   jot list                             # list recent notes
#   jot today                            # show today's notes
#   jot stats                            # show stats
#   jot help                             # show help

set -euo pipefail

JOT_DIR="${JOT_DIR:-$HOME/.jot}"
NOTES_DIR="$JOT_DIR/notes"
INDEX_FILE="$JOT_DIR/index.json"

# Ensure directories exist
mkdir -p "$NOTES_DIR"

# Initialize index if needed
if [[ ! -f "$INDEX_FILE" ]]; then
  echo '{"notes":[],"stats":{"total":0,"tags":{}}}' > "$INDEX_FILE"
fi

usage() {
  cat << 'EOF'
jot — 2-second thought capture

USAGE:
  jot "your thought"                    Quick capture
  jot -t "tag1,tag2" "thought"          Capture with tags
  jot                                   Interactive mode (multi-line)
  jot search "keyword"                  Search notes
  jot list [N]                          List N recent notes (default: 10)
  jot today                             Show today's notes
  jot stats                             Show capture statistics
  jot help                              Show this help

EXAMPLES:
  jot "try using simplex noise for the particle effect"
  jot -t "bug,urgent" "login fails on mobile safari"
  jot search "simplex"
  jot list 20

ENV:
  JOT_DIR   Notes directory (default: ~/.jot)
EOF
}

now_iso() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

now_date() {
  date -u +"%Y-%m-%d"
}

slugify() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/-\{2,\}/-/g' | sed 's/^-\|-$//g'
}

update_index() {
  local action="$1"  # add | remove
  local note_id="$2"
  local tags="$3"
  local date_created="$4"
  local first_line="$5"

  # Use python for JSON manipulation (stdlib, no deps)
  python3 -c "
import json, sys
from datetime import datetime

index_file = '$INDEX_FILE'
with open(index_file, 'r') as f:
    data = json.load(f)

if '$action' == 'add':
    data['notes'].insert(0, {
        'id': '$note_id',
        'date': '$date_created',
        'tags': ['$tags'],
        'preview': '''$first_line'''.strip()[:120]
    })
    data['stats']['total'] = len(data['notes'])
    # Update tag counts
    for tag in '$tags'.split(','):
        tag = tag.strip()
        if tag:
            data['stats']['tags'][tag] = data['stats']['tags'].get(tag, 0) + 1
elif '$action' == 'remove':
    data['notes'] = [n for n in data['notes'] if n['id'] != '$note_id']
    data['stats']['total'] = len(data['notes'])

with open(index_file, 'w') as f:
    json.dump(data, f, indent=2)
" 2>/dev/null || true
}

capture() {
  local text="$1"
  local tags="${2:-general}"
  local timestamp
  local date_created
  local note_id
  local note_file
  local slug

  timestamp=$(now_iso)
  date_created=$(now_date)
  slug=$(slugify "$text")
  # Truncate slug to 40 chars and add random suffix for uniqueness
  slug="${slug:0:40}"
  note_id="${date_created}-${slug}-$(date +%s | tail -c 4)"
  note_file="$NOTES_DIR/${note_id}.md"

  # Write note
  cat > "$note_file" << EOF
---
id: $note_id
date: $timestamp
tags: [$tags]
---

$text
EOF

  # Extract first line for index preview
  first_line=$(echo "$text" | head -n 1 | cut -c 1-120)
  update_index "add" "$note_id" "$tags" "$date_created" "$first_line"

  echo "✓ Captured [$tags] → $note_file"
}

search_notes() {
  local query="$1"
  if [[ -z "$query" ]]; then
    echo "Usage: jot search <keyword>"
    exit 1
  fi

  echo "🔍 Searching for: $query"
  echo ""

  local found=0
  for f in "$NOTES_DIR"/*.md; do
    [[ -f "$f" ]] || continue
    if grep -qi "$query" "$f" 2>/dev/null; then
      local id date tags preview
      id=$(grep "^id:" "$f" | sed 's/id: *//' | tr -d '\r')
      date=$(grep "^date:" "$f" | sed 's/date: *//' | tr -d '\r')
      tags=$(grep "^tags:" "$f" | sed 's/tags: *//' | tr -d '\r')
      preview=$(grep -v '^---' "$f" | grep -v '^id:' | grep -v '^date:' | grep -v '^tags:' | grep -v '^$' | head -n 1 | cut -c 1-80)

      printf "  %s\n" "$(tput setaf 6)$date$(tput sgr0) $(tput setaf 3)$tags$(tput sgr0)"
      printf "    %s\n" "$preview"
      printf "    %s\n\n" "$(tput setaf 8)$id$(tput sgr0)"
      found=$((found + 1))
    fi
  done

  echo "Found $found note(s)"
}

list_notes() {
  local count="${1:-10}"
  echo "📋 Recent notes (latest $count):"
  echo ""

  local i=0
  for f in $(ls -t "$NOTES_DIR"/*.md 2>/dev/null | head -n "$count"); do
    [[ -f "$f" ]] || continue
    local id date tags preview
    id=$(grep "^id:" "$f" | sed 's/id: *//' | tr -d '\r')
    date=$(grep "^date:" "$f" | sed 's/date: *//' | tr -d '\r')
    tags=$(grep "^tags:" "$f" | sed 's/tags: *//' | tr -d '\r')
    preview=$(grep -v '^---' "$f" | grep -v '^id:' | grep -v '^date:' | grep -v '^tags:' | grep -v '^$' | head -n 1 | cut -c 1-80)

    printf "  %s\n" "$(tput setaf 6)$date$(tput sgr0) $(tput setaf 3)$tags$(tput sgr0)"
    printf "    %s\n" "$preview"
    printf "    %s\n\n" "$(tput setaf 8)$id$(tput sgr0)"
    i=$((i + 1))
  done

  if [[ $i -eq 0 ]]; then
    echo "  No notes yet. Type: jot \"your first thought\""
  fi
}

show_today() {
  local today
  today=$(now_date)
  echo "📅 Notes from today ($today):"
  echo ""

  local count=0
  for f in "$NOTES_DIR"/*.md; do
    [[ -f "$f" ]] || continue
    if grep -q "^date: $today" "$f" 2>/dev/null; then
      local tags preview
      tags=$(grep "^tags:" "$f" | sed 's/tags: *//' | tr -d '\r')
      preview=$(grep -v '^---' "$f" | grep -v '^id:' | grep -v '^date:' | grep -v '^tags:' | grep -v '^$' | head -n 1 | cut -c 1-80)

      printf "  %s\n" "$(tput setaf 3)$tags$(tput sgr0)"
      printf "    %s\n\n" "$preview"
      count=$((count + 1))
    fi
  done

  if [[ $count -eq 0 ]]; then
    echo "  Nothing captured today. jot something!"
  fi
}

show_stats() {
  local total tags_json top_tags
  total=$(ls "$NOTES_DIR"/*.md 2>/dev/null | wc -l)
  tags_json=$(python3 -c "
import json
with open('$INDEX_FILE') as f:
    data = json.load(f)
tags = data.get('stats', {}).get('tags', {})
sorted_tags = sorted(tags.items(), key=lambda x: x[1], reverse=True)[:10]
for tag, count in sorted_tags:
    print(f'{tag}: {count}')
" 2>/dev/null || echo "  (no tags yet)")

  echo "📊 jot statistics"
  echo ""
  echo "  Total notes: $total"
  echo ""
  echo "  Top tags:"
  echo "$tags_json" | sed 's/^/    /'
  echo ""

  # Notes per day (last 7)
  echo "  Notes per day (last 7):"
  for i in $(seq 0 6); do
    local d
    d=$(date -u -d "-$i days" +"%Y-%m-%d" 2>/dev/null || date -u -v-${i}d +"%Y-%m-%d")
    local day_count
    day_count=$(grep -l "^date:.*$d" "$NOTES_DIR"/*.md 2>/dev/null | wc -l)
    local label="$d"
    [[ $i -eq 0 ]] && label="today"
    printf "    %-12s %s\n" "$label" "$day_count"
  done
}

interactive_mode() {
  echo "📝 jot — interactive mode (Ctrl+D or empty line to finish)"
  echo ""

  local lines=()
  while IFS= read -r line; do
    lines+=("$line")
  done

  local text
  text=$(printf '%s\n' "${lines[@]}")

  if [[ -z "$text" ]]; then
    echo "Nothing captured."
    exit 0
  fi

  # Ask for tags
  echo ""
  read -rp "Tags (comma-separated, Enter for 'general'): " tag_input
  local tags="${tag_input:-general}"

  capture "$text" "$tags"
}

# ── Parse arguments ──────────────────────────────────────────────

TEXT=""
TAGS=""
MODE="capture"  # capture | search | list | today | stats | interactive
SEARCH_QUERY=""
LIST_COUNT="10"
POSITIONAL=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -t|--tags)
      TAGS="$2"
      shift 2
      ;;
    search|s)
      MODE="search"
      shift
      SEARCH_QUERY="${1:-}"
      ;;
    list|l)
      MODE="list"
      shift
      LIST_COUNT="${1:-10}"
      ;;
    today)
      MODE="today"
      shift
      ;;
    stats|st)
      MODE="stats"
      shift
      ;;
    help|h|--help)
      usage
      exit 0
      ;;
    -*)
      echo "Unknown option: $1"
      usage
      exit 1
      ;;
    *)
      POSITIONAL+=("$1")
      shift
      ;;
  esac
done

TEXT="${POSITIONAL[*]:-}"

# ── Dispatch ──────────────────────────────────────────────────────

case "$MODE" in
  capture)
    if [[ -z "$TEXT" ]]; then
      interactive_mode
    else
      capture "$TEXT" "${TAGS:-general}"
    fi
    ;;
  search)
    search_notes "$SEARCH_QUERY"
    ;;
  list)
    list_notes "$LIST_COUNT"
    ;;
  today)
    show_today
    ;;
  stats)
    show_stats
    ;;
esac

exit 0
