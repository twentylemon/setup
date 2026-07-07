#!/usr/bin/env bash
# Claude Code status line — semantic gradient color scheme
# Wraps dynamically based on terminal width.

input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name // "Claude"')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
context_window_size=$(echo "$input" | jq -r '.context_window.context_window_size // 200000')

# CWD and git branch
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
display_cwd="${cwd/#$HOME/\~}"
branch=""
[ -n "$cwd" ] && branch=$(git -C "$cwd" branch --show-current 2>/dev/null)
if [ -n "$branch" ]; then
  location="${display_cwd} (${branch})"
else
  location="$display_cwd"
fi

# Token fields
cache_read=$(echo "$input" | jq -r '.context_window.current_usage.cache_read_input_tokens // 0')
cache_creation=$(echo "$input" | jq -r '.context_window.current_usage.cache_creation_input_tokens // 0')
input_tokens=$(echo "$input" | jq -r '.context_window.current_usage.input_tokens // 0')
output_tokens=$(echo "$input" | jq -r '.context_window.current_usage.output_tokens // 0')

# Cost
total_cost=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')

# ── Color codes ───────────────────────────────────────────────────────────────
ESC=$'\033'
RESET=$'\033[0m'
DIM=$'\033[2m'
BOLD=$'\033[1m'
RED=$'\033[31m'
BRIGHT_RED=$'\033[1;31m'
GREEN=$'\033[32m'
YELLOW=$'\033[33m'

# ── Gradient palette (10 slots, green → lime → yellow → orange → red) ────────
PALETTE="46 82 118 154 190 226 220 214 202 196"

palette_color() {
  echo "$PALETTE" | tr ' ' '\n' | sed -n "$(($1+1))p"
}

# ── Warning tier ──────────────────────────────────────────────────────────────
tier="none"; pct_int=0
if [ -n "$used_pct" ]; then
  pct_int=$(printf '%.0f' "$used_pct")
  [ "$pct_int" -ge 90 ] && tier="critical"
  [ "$pct_int" -ge 70 ] && [ "$pct_int" -lt 90 ] && tier="warning"
fi

# ── Cache hit rate + color ────────────────────────────────────────────────────
cache_total=$((cache_read + cache_creation + input_tokens))
cache_part=""
if [ "$cache_total" -gt 0 ]; then
  cache_pct=$(awk "BEGIN {printf \"%.0f\", ($cache_read / $cache_total) * 100}")
  if   [ "$cache_pct" -ge 80 ]; then cache_color="$GREEN"
  elif [ "$cache_pct" -ge 30 ]; then cache_color="$YELLOW"
  else                                cache_color="$RED"
  fi
  cache_part="${cache_color}Cache: ${cache_pct}%${RESET}"
fi

# ── Cost + color ──────────────────────────────────────────────────────────────
cost_part=""
if [ -n "$total_cost" ]; then
  if   awk "BEGIN {exit !($total_cost < 3)}"; then cost_color="$GREEN"
  elif awk "BEGIN {exit !($total_cost < 5)}"; then cost_color="$YELLOW"
  else                                             cost_color="$RED"
  fi
  cost_part="${cost_color}\$$(printf '%.2f' "$total_cost")${RESET}"
fi

# ── Format window size ────────────────────────────────────────────────────────
if [ "$context_window_size" -ge 1000 ]; then
  window_display=$(awk "BEGIN {v=$context_window_size/1000; if(v==int(v)) printf \"%dk\",v; else printf \"%.1fk\",v}")
else
  window_display="$context_window_size"
fi

# ── Build gradient progress bar ───────────────────────────────────────────────
BAR_WIDTH=10
pct_label="n/a"; token_display="0"; pct_color=""; bar_filled=""; bar_empty=""

if [ -n "$used_pct" ]; then
  filled=$(echo "$used_pct $BAR_WIDTH" | awk '{printf "%d", ($1/100)*$2 + 0.5}')
  [ "$filled" -gt "$BAR_WIDTH" ] && filled=$BAR_WIDTH
  [ "$filled" -lt 0 ]           && filled=0
  empty=$((BAR_WIDTH - filled))

  for ((i=0; i<filled; i++)); do
    c=$(palette_color $i)
    bar_filled+="${ESC}[38;5;${c}m█${RESET}"
  done
  for ((i=0; i<empty; i++)); do bar_empty+="${DIM}░${RESET}"; done

  if [ "$filled" -gt 0 ]; then
    pc=$(palette_color $((filled-1)))
    pct_color="${ESC}[38;5;${pc}m"
  fi

  used_tokens=$((input_tokens + cache_creation + cache_read + output_tokens))
  if [ "$used_tokens" -ge 1000 ]; then
    token_display=$(awk "BEGIN {v=$used_tokens/1000; if(v==int(v)) printf \"%dk\",v; else printf \"%.1fk\",v}")
  else
    token_display="$used_tokens"
  fi
  pct_label=$(printf '%.0f%%' "$used_pct")
else
  for ((i=0; i<BAR_WIDTH; i++)); do bar_empty+="${DIM}░${RESET}"; done
  pct_label="0%"; token_display="0"
fi

# ── Output ────────────────────────────────────────────────────────────────────
# Always use multi-line layout (~60 chars line 1) since terminal width
# cannot be detected reliably from a status line subprocess.
printf "${BOLD}%s${RESET} | [%s%s] ${pct_color}%s${RESET} | ${pct_color}%s/%s${RESET}\n" \
  "$model" "$bar_filled" "$bar_empty" "$pct_label" "$token_display" "$window_display"
[ -n "$location" ] && printf "${DIM}%s${RESET}\n" "$location"

# ── Cache + Cost ──────────────────────────────────────────────────────────────
if [ -n "$cache_part" ] || [ -n "$cost_part" ]; then
  if [ -n "$cache_part" ] && [ -n "$cost_part" ]; then
    printf "%s | %s\n" "$cache_part" "$cost_part"
  else
    printf "%s\n" "${cache_part}${cost_part}"
  fi
fi

# ── Warning ───────────────────────────────────────────────────────────────────
if [ "$tier" = "warning" ]; then
  printf "${RED}⚠ Context %d%% full — consider summarizing and starting a new session.${RESET}\n" "$pct_int"
elif [ "$tier" = "critical" ]; then
  printf "${BRIGHT_RED}⚠ Context %d%% full — start a new session now to avoid truncation.${RESET}\n" "$pct_int"
fi
