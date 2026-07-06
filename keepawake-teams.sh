#!/usr/bin/env bash

# keepawake-teams.sh
# macOS keep-awake helper that also refreshes Microsoft Teams status

set -u

START="07:00"
END="17:30"
MIN_INTERVAL=120  # tuned to stay under Teams' 5-minute away timeout
MAX_INTERVAL=240
MODE=""
NOW_MINUTES=""

usage() {
  cat <<'EOF'
Usage:
  keepawake-teams.sh --today [--override-hours <HH:MM> <HH:MM>]
  keepawake-teams.sh --now <minutes>

Options:
  --today                      Run until end of current work window
  --now <minutes>              Run for a fixed number of minutes
  --override-hours <start> <end>
                               Override the default work window for this run
                               Example: --override-hours 08:00 18:00
  --help                       Show this help

Examples:
  ./keepawake-teams.sh --today
  ./keepawake-teams.sh --now 90
  ./keepawake-teams.sh --today --override-hours 08:00 18:00
EOF
}

is_valid_time() {
  [[ "$1" =~ ^([01][0-9]|2[0-3]):[0-5][0-9]$ ]]
}

to_timestamp() {
  date -j -f "%Y-%m-%d %H:%M" "$1 $2" +%s
}

refresh_teams() {
  # process binary is MSTeams, not "Microsoft Teams"
  if pgrep -x "MSTeams" >/dev/null 2>&1; then
    # save and restore focus — activate would permanently steal the foreground otherwise
    osascript <<'SCRIPT'
      set frontApp to name of (info for (path to frontmost application))
      tell application "Microsoft Teams" to activate
      tell application "System Events" to keystroke "2" using {command down}
      tell application frontApp to activate
SCRIPT
    echo "Teams Status Refreshed"
  else
    echo "Teams not running, skipping refresh"
  fi
}

run_loop() {
  local end_ts="$1"
  local now duration sleep_seconds remaining

  now=$(date +%s)
  duration=$(( end_ts - now ))

  caffeinate -d -t "$duration" &
  local caffeinate_pid=$!
  trap "kill $caffeinate_pid 2>/dev/null" EXIT
  trap "kill $caffeinate_pid 2>/dev/null; echo 'Caffeinate process killed'; exit" SIGINT

  while [[ $(date +%s) -lt $end_ts ]]; do
    refresh_teams

    sleep_seconds=$(( ( RANDOM % (MAX_INTERVAL - MIN_INTERVAL + 1) ) + MIN_INTERVAL ))
    remaining=$(( end_ts - $(date +%s) ))
    [[ $remaining -le 0 ]] && break
    [[ $sleep_seconds -gt $remaining ]] && sleep_seconds=$remaining
    echo "Sleeping for $sleep_seconds seconds..."
    sleep $sleep_seconds
  done

  echo "Done."
}

run_today() {
  local now today start_ts end_ts

  now=$(date +%s)
  today=$(date +%Y-%m-%d)
  start_ts=$(to_timestamp "$today" "$START")
  end_ts=$(to_timestamp "$today" "$END")

  if [[ $end_ts -le $start_ts ]]; then
    echo "Error: end time must be after start time."
    exit 1
  fi

  if [[ $now -lt $start_ts ]]; then
    echo "Current time is before the work window ($START to $END). Nothing started."
    exit 0
  fi

  if [[ $now -ge $end_ts ]]; then
    echo "Current time is after the work window ($START to $END). Nothing started."
    exit 0
  fi

  echo "Keeping system awake and refreshing Teams until $END today."
  echo "Remaining: $(( (end_ts - now) / 60 )) minutes"
  run_loop "$end_ts"
}

run_now() {
  local minutes="$1"

  if ! [[ "$minutes" =~ ^[0-9]+$ ]] || [[ "$minutes" -le 0 ]]; then
    echo "Error: --now requires a positive integer number of minutes."
    exit 1
  fi

  local end_ts=$(( $(date +%s) + minutes * 60 ))
  echo "Keeping system awake and refreshing Teams for $minutes minutes."
  run_loop "$end_ts"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --today) MODE="today"; shift ;;
    --now)
      MODE="now"
      NOW_MINUTES="${2:-}"
      [[ -z "${NOW_MINUTES:-}" ]] && { echo "Error: --now requires a value."; usage; exit 1; }
      shift 2
      ;;
    --override-hours)
      [[ $# -lt 3 ]] && { echo "Error: --override-hours requires <start> <end>."; usage; exit 1; }
      START="$2"; END="$3"; shift 3
      ;;
    --help|-h) usage; exit 0 ;;
    *) echo "Error: unknown option: $1"; usage; exit 1 ;;
  esac
done

if ! is_valid_time "$START"; then echo "Error: invalid start time: $START"; exit 1; fi
if ! is_valid_time "$END"; then echo "Error: invalid end time: $END"; exit 1; fi

case "$MODE" in
  today) run_today ;;
  now)   run_now "$NOW_MINUTES" ;;
  *)     echo "Error: you must specify --today or --now <minutes>."; echo; usage; exit 1 ;;
esac
