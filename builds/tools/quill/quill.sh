#!/usr/bin/env bash
# ┌─────────────────────────────────────────────┐
# │  quill — quick notes, zero friction         │
# │  A tiny CLI note-taker by Aether ✨         │
# └─────────────────────────────────────────────┘
#
# Usage:
#   quill "your note here"              — add a note
#   quill                               — add a note (interactive)
#   quill today                         — show today's notes
#   quill list [date]                   — show notes for a date (YYYY-MM-DD)
#   quill yesterday                     — show yesterday's notes
#   quill search <term>                 — search all notes
#   quill stats                         — note statistics
#   quill path                          — show notes directory
#   quill edit [date]                   — edit today's (or date's) note file
#
# Config:
#   QUILL_DIR   — notes directory (default: ~/.quill/notes)
#   QUILL_AUTHOR — author name (default: $GIT_AUTHOR_NAME or $USER)

set -euo pipefail

# ── Config ─────────────────────────────────────
QUILL_DIR="${QUILL_DIR:-$HOME/.quill/notes}"
QUILL_AUTHOR="${QUILL_AUTHOR:-${GIT_AUTHOR_NAME:-${USER:-unknown}}}"
TODAY="$(date +%Y-%m-%d)"
YESTERDAY="$(date -d 'yesterday' +%Y-%m-%d 2>/dev/null || date -v-1d +%Y-%m-%d 2>/dev/null || echo '')"

# ── Colors (auto-detect terminal support) ─────
if [[ -t 1 ]] && [[ "${TERM:-}" != "dumb" ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    MAGENTA='\033[0;35m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    DIM='\033[2m'
    RESET='\033[0m'
else
    RED='' GREEN='' YELLOW='' BLUE='' MAGENTA='' CYAN='' BOLD='' DIM='' RESET=''
fi

# ── Helpers ────────────────────────────────────
note_path() {
    local date="${1:-$TODAY}"
    echo "${QUILL_DIR}/${date}.md"
}

ensure_dir() {
    mkdir -p "$QUILL_DIR"
}

ensure_note() {
    local date="$1"
    local path
    path="$(note_path "$date")"
    if [[ ! -f "$path" ]]; then
        echo "# ${date}" > "$path"
        echo "" >> "$path"
    fi
    echo "$path"
}

get_time() {
    date +%H:%M
}

# ── Git auto-commit ────────────────────────────
git_commit() {
    local path="$1"
    local dir
    dir="$(dirname "$path")"

    # Walk up to find a git repo
    local check="$dir"
    while [[ "$check" != "/" ]]; do
        if [[ -d "$check/.git" ]]; then
            (
                cd "$check"
                git add "$path" 2>/dev/null || true
                if git diff --cached --quiet 2>/dev/null; then
                    return
                fi
                git commit -m "quill: ${date:-note} update" --quiet 2>/dev/null || true
            )
            return
        fi
        check="$(dirname "$check")"
    done
}

# ── Actions ────────────────────────────────────

cmd_add() {
    local note_text="$1"
    ensure_dir
    local path
    path="$(ensure_note "$TODAY")"
    local ts
    ts="$(get_time)"

    if [[ -z "$note_text" ]]; then
        echo -e "${DIM}Enter your note (Ctrl+D when done):${RESET}"
        note_text="$(cat)"
    fi

    # Append timestamped note
    echo "- [${ts}] ${note_text}" >> "$path"

    echo -e "${GREEN}✦${RESET} ${DIM}Quilled.${RESET} ${CYAN}${path}${RESET}"

    git_commit "$path"
}

cmd_today() {
    ensure_dir
    local path
    path="$(note_path "$TODAY")"
    if [[ -f "$path" ]]; then
        echo -e "${BOLD}${CYAN}Today${RESET} ${DIM}(${TODAY})${RESET}"
        echo -e "${DIM}───────────────────────${RESET}"
        cat "$path"
    else
        echo -e "${DIM}No notes yet today. Run ${BOLD}quill \"something\"${RESET}${DIM} to start.${RESET}"
    fi
}

cmd_yesterday() {
    if [[ -z "$YESTERDAY" ]]; then
        echo -e "${RED}Could not determine yesterday's date${RESET}"
        return 1
    fi
    ensure_dir
    local path
    path="$(note_path "$YESTERDAY")"
    if [[ -f "$path" ]]; then
        echo -e "${BOLD}${CYAN}Yesterday${RESET} ${DIM}(${YESTERDAY})${RESET}"
        echo -e "${DIM}───────────────────────${RESET}"
        cat "$path"
    else
        echo -e "${DIM}No notes for yesterday.${RESET}"
    fi
}

cmd_list() {
    local date="${1:-$TODAY}"
    ensure_dir
    local path
    path="$(note_path "$date")"
    if [[ -f "$path" ]]; then
        echo -e "${BOLD}${CYAN}${date}${RESET}"
        echo -e "${DIM}───────────────────────${RESET}"
        cat "$path"
    else
        echo -e "${DIM}No notes for ${date}.${RESET}"
    fi
}

cmd_search() {
    local term="$1"
    if [[ -z "$term" ]]; then
        echo -e "${RED}Usage: quill search <term>${RESET}"
        return 1
    fi
    ensure_dir
    echo -e "${BOLD}${CYAN}Searching for:${RESET} ${BOLD}${term}${RESET}"
    echo -e "${DIM}───────────────────────${RESET}"
    local found=0
    while IFS= read -r file; do
        if grep -qi "$term" "$file" 2>/dev/null; then
            local fname
            fname="$(basename "$file" .md)"
            echo -e "\n${MAGENTA}▸ ${fname}${RESET}"
            grep -i --color=always "$term" "$file" 2>/dev/null | sed "s/^/  ${DIM}│${RESET} /"
            found=$((found + 1))
        fi
    done < <(find "$QUILL_DIR" -name "*.md" -type f 2>/dev/null | sort -r)

    echo ""
    echo -e "${DIM}Found in ${found} file(s).${RESET}"
}

cmd_stats() {
    ensure_dir
    local total=0
    local today_count=0
    local files=0

    if [[ -d "$QUILL_DIR" ]]; then
        files=$(find "$QUILL_DIR" -name "*.md" -type f 2>/dev/null | wc -l)
        total=$(find "$QUILL_DIR" -name "*.md" -exec grep -h "^- \[" {} + 2>/dev/null | wc -l)
        today_count=$(grep -c "^- \[" "$(note_path "$TODAY")" 2>/dev/null || echo 0)
    fi

    echo -e "${BOLD}${CYAN}  Quill Stats${RESET}"
    echo -e "${DIM}  ────────────────${RESET}"
    echo -e "  ${GREEN}●${RESET} Total notes:   ${BOLD}${total}${RESET}"
    echo -e "  ${GREEN}●${RESET} Days active:   ${BOLD}${files}${RESET}"
    echo -e "  ${YELLOW}●${RESET} Today:         ${BOLD}${today_count}${RESET} note(s)"
    echo -e "  ${DIM}● Notes dir: ${QUILL_DIR}${RESET}"

    # Find longest streak
    local streak=0
    local max_streak=0
    local prev_date=""
    for f in $(find "$QUILL_DIR" -name "*.md" -type f 2>/dev/null | xargs -I{} basename {} .md | sort -r); do
        if [[ -z "$prev_date" ]]; then
            streak=1
        else
            # Simple: consecutive days in the file list
            streak=$((streak + 1))
        fi
        prev_date="$f"
        if [[ $streak -gt $max_streak ]]; then
            max_streak=$streak
        fi
    done
    echo -e "  ${MAGENTA}●${RESET} Longest streak: ${BOLD}${max_streak}${RESET} day(s)"
    echo ""
}

cmd_path() {
    ensure_dir
    echo "$QUILL_DIR"
}

cmd_edit() {
    local date="${1:-$TODAY}"
    ensure_dir
    local path
    path="$(ensure_note "$date")"
    local editor="${EDITOR:-${VISUAL:-vi}}"
    "$editor" "$path"
}

cmd_help() {
    cat << 'EOF'
┌─────────────────────────────────────────────┐
│  quill — quick notes, zero friction          │
└─────────────────────────────────────────────┘

  quill "your note"        Add a note
  quill                    Add a note (interactive)
  quill today              Show today's notes
  quill yesterday          Show yesterday's notes
  quill list [YYYY-MM-DD]  Show notes for a date
  quill search <term>      Search all notes
  quill stats              Note statistics
  quill path               Show notes directory
  quill edit [YYYY-MM-DD]  Edit a note file

Config:
  QUILL_DIR     Notes directory (default: ~/.quill/notes)
  QUILL_AUTHOR  Author name (default: $USER)

EOF
}

# ── Main ───────────────────────────────────────
main() {
    local cmd="${1:-add}"
    shift || true

    case "$cmd" in
        add|note|q)
            cmd_add "${1:-}" ;;
        today|t)
            cmd_today ;;
        yesterday|y)
            cmd_yesterday ;;
        list|l)
            cmd_list "${1:-}" ;;
        search|s|find)
            cmd_search "${1:-}" ;;
        stats|i|info)
            cmd_stats ;;
        path|p)
            cmd_path ;;
        edit|e)
            cmd_edit "${1:-}" ;;
        help|--help|-h)
            cmd_help ;;
        *)
            # Treat unknown commands as notes for convenience
            cmd_add "$cmd $*" ;;
    esac
}

main "$@"
