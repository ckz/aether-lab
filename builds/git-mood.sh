#!/usr/bin/env bash
# git-mood — What's your coding mood today?
# Analyzes recent git history and tells you about your coding personality.
# Usage: git-mood [days] [repo-path]
#   days      — how many days to look back (default: 7)
#   repo-path — path to git repo (default: current directory)

set -euo pipefail

DAYS="${1:-7}"
REPO="${2:-.}"
cd "$REPO" 2>/dev/null || { echo "❌ Can't access: $REPO"; exit 1; }

# Check it's actually a git repo
git rev-parse --git-dir > /dev/null 2>&1 || { echo "❌ Not a git repository: $REPO"; exit 1; }

# ── Gather data ──────────────────────────────────────────────
SINCE=$(date -d "$DAYS days ago" '+%Y-%m-%d' 2>/dev/null || date -v-${DAYS}d '+%Y-%m-%d' 2>/dev/null || echo "2 weeks ago")
COMMITS=$(git log --since="$SINCE" --format="%H|%ai|%s" 2>/dev/null | wc -l)
AUTHORS=$(git log --since="$SINCE" --format="%an" 2>/dev/null | sort -u | wc -l)
FILES=$(git log --since="$SINCE" --format="" --name-only 2>/dev/null | grep -v '^$' | sort -u | wc -l)

# Hour distribution — when does this person code?
HOURS=$(git log --since="$SINCE" --format="%ai" 2>/dev/null | awk '{print $2}' | cut -d: -f1 | sort | uniq -c | sort -rn)

# Night owl? (22–05)
NIGHT_COMMITS=$(git log --since="$SINCE" --format="%ai" 2>/dev/null | awk '{split($2,a,":"); if(a[1]>=22 || a[1]<5) print}' | wc -l)
DAY_COMMITS=$((COMMITS - NIGHT_COMMITS))

# Weekend warrior?
WEEKEND_COMMITS=$(git log --since="$SINCE" --format="%ai" 2>/dev/null | awk '{print $1}' | while read d; do day=$(date -d "$d" +%u 2>/dev/null || date -jf "%Y-%m-%d" "$d" +%u 2>/dev/null || echo "0"); if [ "$day" -ge 6 ]; then echo "1"; fi; done | wc -l)

# Commit message sentiment — positive / negative / neutral
POSITIVE=$(git log --since="$SINCE" --format="%s" 2>/dev/null | grep -iE '\b(fix|bug|broken|error|fail|wtf|ugh|damn|shit|broken|hotfix|urgent|critical|refucktor|rework)\b' | wc -l)
NEGATIVE=$(git log --since="$SINCE" --format="%s" 2>/dev/null | grep -iE '\b(add|feat|feature|improve|enhance|awesome|love|great|clean|polish|refactor|optimize|perf|update|new|wip)\b' | wc -l)
NEUTRAL=$((COMMITS - POSITIVE - NEGATIVE))

# Most active hour
PEAK_HOUR=$(echo "$HOURS" | head -1 | awk '{print $2}')
PEAK_COUNT=$(echo "$HOURS" | head -1 | awk '{print $1}')

# Top languages by file changes
LANG_DIST=$(git log --since="$SINCE" --format="" --name-only 2>/dev/null | grep -v '^$' | awk -F. 'NF>1{print $NF}' | sort | uniq -c | sort -rn | head -5)

# WIP commits?
WIP=$(git log --since="$SINCE" --format="%s" 2>/dev/null | grep -ciE '^(wip|temp|tmp|scratch|test|xxx)' || true)

# Repo age
REPO_AGE=$(git log --reverse --format="%ci" 2>/dev/null | head -1 | cut -d' ' -f1)

# ── Mood calculation ─────────────────────────────────────────
SCORE=0
MOOD_TAGS=()

# Night owl vs early bird
if [ "$NIGHT_COMMITS" -gt "$DAY_COMMITS" ]; then
  SCORE=$((SCORE + 3))
  MOOD_TAGS+=("🦉 Night Owl")
else
  SCORE=$((SCORE + 1))
  MOOD_TAGS+=("☀️ Early Bird")
fi

# Weekend coder
if [ "$WEEKEND_COMMITS" -gt 0 ]; then
  SCORE=$((SCORE + 2))
  MOOD_TAGS+=("🔥 Weekend Warrior")
fi

# Sentiment
if [ "$POSITIVE" -gt "$NEGATIVE" ]; then
  SCORE=$((SCORE + 1))
  MOOD_TAGS+=("🛠️ Battle-Scarred")
elif [ "$NEGATIVE" -gt "$POSITIVE" ]; then
  SCORE=$((SCORE + 2))
  MOOD_TAGS+=("✨ Feature Dreamer")
else
  SCORE=$((SCORE + 0))
  MOOD_TAGS+=("⚖️ Balanced Builder")
fi

# Volume
if [ "$COMMITS" -gt 30 ]; then
  SCORE=$((SCORE + 2))
  MOOD_TAGS+=("🚀 Shipping Machine")
elif [ "$COMMITS" -gt 10 ]; then
  SCORE=$((SCORE + 1))
  MOOD_TAGS+=("📦 Consistent Crafter")
else
  MOOD_TAGS+=("🧘 Minimalist")
fi

# WIP tendency
if [ "$WIP" -gt 2 ]; then
  SCORE=$((SCORE + 1))
  MOOD_TAGS+=("🔄 WIP Collector")
fi

# Solo or team?
if [ "$AUTHORS" -gt 1 ]; then
  SCORE=$((SCORE + 1))
  MOOD_TAGS+=("🤝 Team Player")
else
  MOOD_TAGS+=("🧑‍💻 Lone Wolf")
fi

# Determine archetype
ARCHETYPE=""
if [ "$SCORE" -ge 7 ]; then
  ARCHETYPE="🔥 LEGENDARY DEV 🔥"
elif [ "$SCORE" -ge 5 ]; then
  ARCHETYPE="⚡ POWER CODER ⚡"
elif [ "$SCORE" -ge 3 ]; then
  ARCHETYPE="🌱 GROWTH MODE 🌱"
else
  ARCHETYPE="🍃 ZEN CODER 🍃"
fi

# ── Output ───────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🔮  GIT MOOD READING — $DAYS days"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  $ARCHETYPE"
echo ""
echo "  📊 Stats"
echo "     $COMMITS commits  |  $AUTHORS author(s)  |  $FILES files touched"
echo "     Peak hour: ${PEAK_HOUR:-??}:00 (${PEAK_COUNT:-0} commits)"
echo "     Repo age: ${REPO_AGE:-unknown}"
echo ""
echo "  🏷️  Mood tags"

for tag in "${MOOD_TAGS[@]}"; do
  echo "     $tag"
done

echo ""
echo "  📈 Top languages touched"

if [ -n "$LANG_DIST" ]; then
  echo "$LANG_DIST" | while read count ext; do
    echo "     .$ext  ($count files)"
  done
else
  echo "     (no file extensions detected)"
fi

echo ""
echo "  🕐 Time breakdown"
echo "     Day commits: $DAY_COMMITS  |  Night commits: $NIGHT_COMMITS"
echo "     Weekend commits: $WEEKEND_COMMITS"

echo ""
echo "  💬 Your commit vibe"
if [ "$POSITIVE" -gt "$NEGATIVE" ] && [ "$POSITIVE" -gt 3 ]; then
  echo "     \"I broke it so I could fix it properly.\" — ${POSITIVE} fix commits"
elif [ "$NEGATIVE" -gt "$POSITIVE" ] && [ "$NEGATIVE" -gt 3 ]; then
  echo "     \"Just ship it.\" — ${NEGATIVE} feature/improve commits"
elif [ "$WIP" -gt 2 ]; then
  echo "     \"I'll clean this up later.\" — ${WIP} WIP commits"
elif [ "$COMMITS" -gt 20 ]; then
  echo "     \"Fast fingers, fast commits.\" — $COMMITS in $DAYS days"
else
  echo "     \"Quality over quantity.\" — thoughtful, measured pace"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  Run \`git-mood 30\` for a month of vibes."
echo "  Run \`git-mood 14 /path/to/repo\` for a different repo."
echo ""
