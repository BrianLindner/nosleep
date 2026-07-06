#!/usr/bin/env python3
# keepawake.py
# macOS keep-awake helper using Quartz mouse movement
import argparse
import sys
import time
from datetime import datetime, time as dt_time

import Quartz.CoreGraphics as CG

WORK_START: dt_time = dt_time(7, 0)
WORK_END: dt_time = dt_time(17, 30)
WIGGLE_INTERVAL: int = 30


def move(x: int, y: int) -> None:
    event = CG.CGEventCreateMouseEvent(None, CG.kCGEventMouseMoved, (x, y), 0)
    CG.CGEventPost(CG.kCGHIDEventTap, event)


def wiggle_until(end_ts: float) -> None:
    x, y = 500, 500
    toggle = False
    while time.time() < end_ts:
        dx = 2 if toggle else -2
        move(x + dx, y)
        toggle = not toggle
        remaining = end_ts - time.time()
        time.sleep(min(WIGGLE_INTERVAL, max(0.0, remaining)))
    print("Done.")


def run_now(minutes: int) -> None:
    print(f"Wiggling mouse for {minutes} minutes.")
    wiggle_until(time.time() + minutes * 60)


def run_today(start: dt_time = WORK_START, end: dt_time = WORK_END) -> None:
    now = datetime.now()
    now_time = now.time().replace(second=0, microsecond=0)

    if now_time < start:
        print(f"Current time is before the work window ({start.strftime('%H:%M')} to {end.strftime('%H:%M')}). Nothing started.")
        sys.exit(0)
    if now_time >= end:
        print(f"Current time is after the work window ({start.strftime('%H:%M')} to {end.strftime('%H:%M')}). Nothing started.")
        sys.exit(0)

    end_dt = datetime.combine(now.date(), end)
    remaining_minutes = int((end_dt - now).total_seconds() / 60)
    print(f"Wiggling mouse until {end.strftime('%H:%M')} today. Remaining: {remaining_minutes} minutes.")
    wiggle_until(end_dt.timestamp())


def parse_time(s: str) -> dt_time:
    try:
        return datetime.strptime(s, "%H:%M").time()
    except ValueError:
        raise argparse.ArgumentTypeError(f"Invalid time format: {s!r} (expected HH:MM)")


def main() -> None:
    parser = argparse.ArgumentParser(
        prog="keepawake.py",
        description="Keep system awake by wiggling the mouse cursor.",
    )
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--today", action="store_true", help="Wiggle until end of work window")
    group.add_argument("--now", type=int, metavar="MINUTES", help="Wiggle for a fixed number of minutes")
    parser.add_argument(
        "--override-hours",
        nargs=2,
        metavar=("START", "END"),
        type=parse_time,
        help="Override work window (HH:MM HH:MM)",
    )

    args = parser.parse_args()

    if args.today:
        start = args.override_hours[0] if args.override_hours else WORK_START
        end = args.override_hours[1] if args.override_hours else WORK_END
        run_today(start, end)
    else:
        if args.now <= 0:
            parser.error("--now requires a positive integer")
        run_now(args.now)


if __name__ == "__main__":
    main()
