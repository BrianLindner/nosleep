# nosleep - Utility Scripts to keep a computer awake/active

A set of utility scripts to keep a computer awake and active.
Useful for systems or applications that need to see periodic activity (key presses,
mouse movement, etc.) to stay alive, awake, or attentive.

NoSleep-style scripts in a variety of languages and platforms — pick the one that fits your environment.

---

## Scripts

### macOS

| Script | Mechanism | Notes |
|---|---|---|
| [keepawake.sh](keepawake.sh) | `caffeinate` | Most flexible. `--today` (until end of work window), `--now <minutes>`, or `--wrap -- <command>` (stay awake for a job's lifetime). Asserts `-i -m -s`. Optional `--display`. **Recommended for general use.** |
| [keepawake-teams.sh](keepawake-teams.sh) | `caffeinate` + AppleScript | Keeps display awake and periodically nudges Microsoft Teams status. Supports `--today` and `--now <minutes>`. |
| [keepawake.py](keepawake.py) | Quartz mouse move | Mouse wiggler via macOS Quartz API. Supports `--today` and `--now <minutes>`. Requires `pyobjc` (`pip install pyobjc`). |

### Windows

| Script | Mechanism | Notes |
|---|---|---|
| [keepawake.ahk](keepawake.ahk) | AutoHotKey mouse move | Moves mouse every 60 seconds. |
| [keepawake.ps1](keepawake.ps1) | PowerShell key press | Sends random function keys. Supports `-Now <minutes>` and `-Today`. |
| [keepawake.vbs](keepawake.vbs) | VBScript key press | Sends random function keys. |

---

## Quick start

**macOS (recommended):**
```bash
# Keep awake for the rest of your work day
./keepawake.sh --today

# Keep awake for 90 minutes
./keepawake.sh --now 90

# Keep display on too
./keepawake.sh --today --display

# Keep awake for exactly as long as a long job runs, then release
./keepawake.sh --wrap -- ./long-batch-job.sh arg1 arg2

# Keep awake + refresh Teams status
./keepawake-teams.sh --today
```

### Sleep coverage & caveats (macOS)

`keepawake.sh` always asserts `-i` (idle) `-m` (disk) `-s` (system) sleep. What that
does — and does **not** — cover:

| Sleep type | Prevented? | Notes |
|---|---|---|
| Idle system sleep | ✅ `-i` | Works on AC **and** battery |
| Disk idle sleep | ✅ `-m` | |
| Full system sleep | ✅ `-s`, **AC only** | Ignored on battery; re-activates automatically when you plug back in (no restart) |
| Display sleep | ✅ with `--display` (`-d`) | |
| PowerNap / **Maintenance sleep** | ❌ | Not blockable by `caffeinate`. Disable with `sudo pmset -a powernap 0` |
| **Thermal-emergency sleep** | ❌ | Firmware force-sleeps an overheating CPU; nothing overrides it — reduce load / improve airflow |

The script prints the current power source and these limits on start, and reports which
assertions actually took effect. For sustained all-core workloads, expect thermal to be the
one thing it can't save you from — the reason to offload heavy compute to a plugged-in
desktop or GPU box.

**Windows:**
```powershell
# PowerShell — keep awake for 90 minutes
.\keepawake.ps1 -Now 90

# PowerShell — keep awake for the rest of the work day
.\keepawake.ps1 -Today
```

Or open `keepawake.ahk` with AutoHotKey for a no-setup option.

---
