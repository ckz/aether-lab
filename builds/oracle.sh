#!/usr/bin/env bash
# ╔══════════════════════════════════════════════╗
# ║           THE ORACLE OF FORTUNE             ║
# ║     (A dramatic decision-making engine)     ║
# ╚══════════════════════════════════════════════╝
#
# Usage:
#   ./oracle.sh option1 option2 option3 ...
#   ./oracle.sh --preset deploy
#   ./oracle.sh --preset lunch
#   ./oracle.sh --preset weekend
#   ./oracle.sh --preset project
#   ./oracle.sh --preset snack
#   ./oracle.sh --help

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

PRESETS=(
  "deploy:Push to production::Skip it::Hotfix first::Ask the team::Ship it and monitor"
  "lunch:Tacos::Pizza::Sushi::That weird leftover::Actually just coffee::The salad you won't eat"
  "weekend:Hack on side project::Go outside (crazy)::Sleep for 14 hours::Game all night::Read a book::Pretend you don't have FOMO"
  "project:React::Svelte::Vue::Vanilla JS::Flutter::Rust::Just use jQuery::The new framework from 2 weeks ago::COBOL"
  "snack:Apple::Chips::That one granola bar::Nothing (lie to yourself)::Cookie::Popcorn::More coffee::The expired yogurt in the back"
)

show_help() {
  echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════╗${RESET}"
  echo -e "${BOLD}${CYAN}║           THE ORACLE OF FORTUNE             ║${RESET}"
  echo -e "${BOLD}${CYAN}║     (A dramatic decision-making engine)     ║${RESET}"
  echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════╝${RESET}"
  echo ""
  echo -e "${BOLD}USAGE:${RESET}"
  echo "  ./oracle.sh [OPTIONS] [OPTIONS...]"
  echo ""
  echo -e "${BOLD}OPTIONS:${RESET}"
  echo "  --preset NAME    Use a preset list of options"
  echo "  --presets        Show all available presets"
  echo "  --help           Show this help"
  echo ""
  echo -e "${BOLD}PRESETS:${RESET}"
  for p in "${PRESETS[@]}"; do
    name="${p%%:*}"
    echo -e "  ${YELLOW}${name}${RESET}"
  done
  echo ""
  echo -e "${BOLD}EXAMPLES:${RESET}"
  echo "  ./oracle.sh yes no maybe"
  echo "  ./oracle.sh --preset deploy"
  echo "  ./oracle.sh fix bug add feature refactor ship"
}

show_presets() {
  echo -e "${BOLD}${CYAN}Available Presets:${RESET}"
  echo ""
  for p in "${PRESETS[@]}"; do
    name="${p%%:*}"
    rest="${p#*:}"
    desc="${rest%%::*}"
    echo -e "  ${YELLOW}${name}${RESET} — ${desc}"
  done
}

get_preset() {
  local name="$1"
  for p in "${PRESETS[@]}"; do
    if [[ "$p" == "${name}:"* ]]; then
      # Strip the name: prefix, then replace :: with newlines
      echo "${p#*:}" | sed 's/::/\n/g'
      return
    fi
  done
  echo -e "${RED}Unknown preset: ${name}${RESET}" >&2
  echo "Run with --presets to see available options" >&2
  exit 1
}

SPINNER_FRAMES=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)
SPINNER_CHARS=('|' '/' '-' '\\' '|' '/' '-' '\\')

spin_animation() {
  local duration="$1"
  local i=0
  local temp="${SPINNER_FRAMES[@]}"
  while (( i < duration )); do
    for frame in "${SPINNER_FRAMES[@]}"; do
      printf "\r${CYAN}${frame}${RESET} Consulting the ancient algorithms... "
      sleep 0.08
      ((i++)) || true
      (( i >= duration )) && break
    done
  done
}

dramatic_pause() {
  printf "\r${DIM}...${RESET}"
  sleep 0.3
  printf "\r${DIM}.${RESET} "
  sleep 0.2
  printf "\r${DIM}.${RESET}"
  sleep 0.2
}

validate_numeric() {
  local val="$1"
  [[ "$val" =~ ^[0-9]+$ ]]
}

# Parse arguments
ARGS=()
USE_PRESET=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h)
      show_help
      exit 0
      ;;
    --presets)
      show_presets
      exit 0
      ;;
    --preset)
      if [[ -z "${2:-}" ]]; then
        echo -e "${RED}Error: --preset requires a name${RESET}" >&2
        exit 1
      fi
      USE_PRESET="$2"
      shift 2
      ;;
    *)
      ARGS+=("$1")
      shift
      ;;
  esac
done

# Load options
if [[ -n "$USE_PRESET" ]]; then
  mapfile -t OPTIONS < <(get_preset "$USE_PRESET")
else
  OPTIONS=("${ARGS[@]}")
fi

# Validate
if [[ ${#OPTIONS[@]} -lt 2 ]]; then
  echo -e "${RED}The Oracle requires at least 2 options to divine your fate.${RESET}"
  echo ""
  echo -e "Usage: ${BOLD}./oracle.sh option1 option2 [option3...]${RESET}"
  echo -e "       ${BOLD}./oracle.sh --preset NAME${RESET}"
  echo -e "       ${BOLD}./oracle.sh --presets${RESET} to see all"
  exit 1
fi

# Clear and set up
echo ""
echo -e "${BOLD}${MAGENTA}═══════════════════════════════════════════════════${RESET}"
echo -e "${BOLD}${MAGENTA}              🜏  THE ORACLE SPEAKS  🜏              ${RESET}"
echo -e "${BOLD}${MAGENTA}═══════════════════════════════════════════════════${RESET}"
echo ""
echo -e "${DIM}You ask the cosmos:${RESET}"
for i in "${!OPTIONS[@]}"; do
  num=$((i + 1))
  echo -e "  ${CYAN}${num}.${RESET} ${OPTIONS[$i]}"
done
echo ""

# The dramatic moment
echo -ne "${BOLD}${YELLOW}Consulting the fates${RESET}"
spin_animation 12
dramatic_pause

# The reveal
CHOSEN_INDEX=$((RANDOM % ${#OPTIONS[@]}))
CHOSEN="${OPTIONS[$CHOSEN_INDEX]}"

echo ""
echo ""
echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${GREEN}║                                          ║${RESET}"
echo -e "${BOLD}${GREEN}║   ✦  THE ORACLE HAS DECIDED  ✦          ║${RESET}"
echo -e "${BOLD}${GREEN}║                                          ║${RESET}"
echo -e "${BOLD}${GREEN}║   ${RESET}${BOLD}${CHOSEN}${RESET}${BOLD}${GREEN}                           ║${RESET}"
echo -e "${BOLD}${GREEN}║                                          ║${RESET}"
echo -e "${BOLD}${GREEN}╚══════════════════════════════════════════╝${RESET}"
echo ""
echo -e "${DIM}(The Oracle's decision is final. Argue with the universe, not me.)${RESET}"
echo ""

# Fun sigils based on choice
case $((CHOSEN_INDEX + 1)) in
  1) echo -e "${DIM}  ⟡ First light favors the bold.${RESET}" ;;
  2) echo -e "${DIM}  ⟡ The second path holds hidden gifts.${RESET}" ;;
  3) echo -e "${DIM}  ⟡ Three is the number of completion.${RESET}" ;;
  *) echo -e "${DIM}  ⟡ The stars align in mysterious ways.${RESET}" ;;
esac
echo ""
