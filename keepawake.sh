#!/usr/bin/env bash

# keepawake.sh
# Manual macOS keep-awake helper using caffeinate

set -u

START="07:00"
END="17:30"
KEEP_DISPLAY=0
MODE=""
NOW_MINUTES=""
WRAP_CMD=()

usage() {
  cat <<'EOF'
Usage:
  keepawake.sh --today [--display]
  keepawake.sh --now <minutes> [--display]
  keepawake.sh --today --override-hours <HH:MM> <HH:MM> [--display]
  keepawake.sh [--display] --wrap [--] <command> [args...]

Options:
  --today                      Keep awake for the rest of the current work window
  --now <minutes>              Keep awake immediately for a fixed number of minutes
  --wrap <command> [args...]   Keep awake for exactly as long as <command> runs,
                               then release. Best for long jobs (batch/compute) so
                               you don't guess a duration. Must be the LAST option.
  --override-hours <start> <end>
                               Override the default work window for this run
                               Example: --override-hours 08:30 18:00
  --display                    Keep the display awake too
  --help                       Show this help

Sleep coverage:
  Always asserts -i (idle) -m (disk) -s (system). -s is honored only on AC power
  (ignored on battery, where -i still prevents idle sleep). PowerNap/maintenance
  sleep and thermal-emergency sleep are NOT preventable by caffeinate.

Examples:
  ./keepawake.sh --today
  ./keepawake.sh --now 90
  ./keepawake.sh --wrap -- ./long-batch-job.sh arg1 arg2
  ./keepawake.sh --display --wrap -- make release
EOF
}

is_valid_time() {
  [[ "$1" =~ ^([01][0-9]|2[0-3]):[0-5][0-9]$ ]]
}

to_timestamp() {
  local day="$1"
  local hhmm="$2"
  date -j -f "%Y-%m-%d %H:%M" "$day $hhmm" +%s
}

# Assertion flags shared by all modes. -i (idle) + -m (disk) apply on AC *and*
# battery; -s (full system sleep) is honored only on AC but is harmless on
# battery — so we ALWAYS pass it. That way plugging in mid-run activates it
# automatically (powerd re-evaluates live), with no restart. --display adds -d.
ASSERT_ARGS=()
build_args() {
  ASSERT_ARGS=(-i -m -s)
  [[ $KEEP_DISPLAY -eq 1 ]] && ASSERT_ARGS=(-d "${ASSERT_ARGS[@]}")
}

# Report the current power source and caffeinate's hard limits, so the tool
# never over-promises.
warn_power() {
  if pmset -g batt 2>/dev/null | grep -q "AC Power"; then
    echo "Power: AC — full system-sleep prevention (-s) is in effect."
  else
    echo "WARNING: on BATTERY — -s (system sleep) is ignored until you're on AC."
    echo "         Idle sleep is still prevented (-i); plug in for full coverage."
  fi
  echo "Note: PowerNap/maintenance sleep and thermal-emergency sleep CANNOT be"
  echo "      prevented by caffeinate. To disable PowerNap: sudo pmset -a powernap 0"
}

# Confirm which assertions actually took effect — don't just assume success.
verify_assertions() {
  sleep 1
  echo "Active sleep assertions:"
  pmset -g assertions 2>/dev/null \
    | grep -E "PreventSystemSleep|PreventUserIdleSystemSleep|PreventUserIdleDisplaySleep" \
    || echo "  (none reported yet)"
}

run_caffeinate() {
  local seconds="$1"
  build_args
  local -a args=("${ASSERT_ARGS[@]}" -t "$seconds")
  warn_power
  echo "Running: caffeinate ${args[*]}"
  caffeinate "${args[@]}" &
  local caf=$!
  trap 'kill "$caf" 2>/dev/null' INT TERM
  verify_assertions
  wait "$caf"
}

# Keep awake for exactly as long as the wrapped command runs, then release the
# assertion automatically. No duration guessing — ideal for batch/compute jobs.
run_wrap() {
  build_args
  warn_power
  echo "Running: caffeinate ${ASSERT_ARGS[*]} ${WRAP_CMD[*]}"
  caffeinate "${ASSERT_ARGS[@]}" "${WRAP_CMD[@]}"
}

run_today() {
  local now today start_ts end_ts remaining

  now=$(date +%s)
  today=$(date +%Y-%m-%d)

  start_ts=$(to_timestamp "$today" "$START")
  end_ts=$(to_timestamp "$today" "$END")

  if [[ $end_ts -le $start_ts ]]; then
    echo "Error: end time must be after start time for same-day windows."
    exit 1
  fi

  if [[ $now -lt $start_ts ]]; then
    echo "Current time is before the work window."
    echo "Window: $START to $END"
    echo "Nothing started."
    exit 0
  fi

  if [[ $now -ge $end_ts ]]; then
    echo "Current time is after the work window."
    echo "Window: $START to $END"
    echo "Nothing started."
    exit 0
  fi

  remaining=$((end_ts - now))

  clear
  echo "Keeping system awake until $END today."
  echo "Remaining: $((remaining / 60)) minutes"

  run_caffeinate "$remaining"
}

run_now() {
  local minutes="$1"
  local seconds

  if ! [[ "$minutes" =~ ^[0-9]+$ ]] || [[ "$minutes" -le 0 ]]; then
    echo "Error: --now requires a positive integer number of minutes."
    exit 1
  fi

  seconds=$((minutes * 60))

  clear
  echo "Keeping system awake for $minutes minutes starting now."
  run_caffeinate "$seconds"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --today)
      MODE="today"
      shift
      ;;
    --now)
      MODE="now"
      NOW_MINUTES="${2:-}"
      if [[ -z "${NOW_MINUTES:-}" ]]; then
        echo "Error: --now requires a value."
        usage
        exit 1
      fi
      shift 2
      ;;
    --override-hours)
      if [[ $# -lt 3 ]]; then
        echo "Error: --override-hours requires <start> <end>."
        usage
        exit 1
      fi
      START="$2"
      END="$3"
      shift 3
      ;;
    --wrap)
      MODE="wrap"
      shift
      [[ "${1:-}" == "--" ]] && shift   # optional -- separator
      WRAP_CMD=("$@")
      if [[ ${#WRAP_CMD[@]} -eq 0 ]]; then
        echo "Error: --wrap requires a command to run."
        usage
        exit 1
      fi
      break   # everything after --wrap is the command
      ;;
    --display)
      KEEP_DISPLAY=1
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Error: unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

if ! is_valid_time "$START"; then
  echo "Error: invalid start time: $START"
  exit 1
fi

if ! is_valid_time "$END"; then
  echo "Error: invalid end time: $END"
  exit 1
fi

case "$MODE" in
  today)
    run_today
    ;;
  now)
    run_now "$NOW_MINUTES"
    ;;
  wrap)
    run_wrap
    ;;
  *)
    echo "Error: you must specify --today, --now <minutes>, or --wrap <command>."
    echo
    usage
    exit 1
    ;;
esac
