#!/usr/bin/env bash
# Bring up an OmarKEYS overlay nobody is looking at.
#
# Visual checks -- does the board fill, does the card land on one monitor,
# did the spacing change land -- have until now meant restarting the shell
# on the machine someone is working on and throwing the overlay over their
# windows. This runs the same checks against a compositor of our own.
#
#   headless sway (virtual output)
#     -> nested Hyprland (Wayland backend)
#        -> quickshell + the OmarKEYS plugin
#
# Sway is the host, not the thing under test: OmarKEYS is Hyprland-specific.
# The overlay reads Quickshell's Hyprland singleton, dump-keymap shells out
# to hyprctl and re-runs the Lua config, and the Super gestures live inside
# Hyprland's own Lua config provider. Under sway alone none of that exists,
# so the overlay would come up with no keymap at all.
#
# wayvnc is optional and only for watching: attach it to sway (port 5900)
# and the whole nested desktop is visible live.
#
# STATUS: not yet run end to end. Written against homarchy before access to
# it existed, so the shape is right but the details have not met a real box.
# Two things are unverified and are called out where they matter: whether
# wtype's virtual keyboard reaches hl.on("input.keyboard.key"), and whether
# a nested Hyprland picks up Omarchy's Lua bindings without a login session.
set -uo pipefail

RES="${RES:-2560x1440}"
PLUGIN_ID="io.github.romills.omarkeys"
WORK="$(mktemp -d -t omarkeys-headless-XXXXXX)"
SHOTS="${SHOTS:-$WORK/shots}"
mkdir -p "$SHOTS"

SWAY_PID=""
HYPR_PID=""

log() { printf '  %s\n' "$*"; }
die() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

# Always tear down: a leaked compositor holds a Wayland socket and the next
# run attaches to the wrong one, which is worse than failing outright.
cleanup() {
  [ -n "$HYPR_PID" ] && kill "$HYPR_PID" 2>/dev/null
  [ -n "$SWAY_PID" ] && kill "$SWAY_PID" 2>/dev/null
  sleep 1
  [ -n "$HYPR_PID" ] && kill -9 "$HYPR_PID" 2>/dev/null
  [ -n "$SWAY_PID" ] && kill -9 "$SWAY_PID" 2>/dev/null
  log "torn down; artefacts in $WORK"
}
trap cleanup EXIT INT TERM

preflight() {
  local missing=()
  for t in sway Hyprland quickshell hyprctl grim omarchy-shell; do
    command -v "$t" >/dev/null 2>&1 || missing+=("$t")
  done
  [ ${#missing[@]} -eq 0 ] || die "not installed: ${missing[*]}"
  command -v wtype >/dev/null 2>&1 || log "note: no wtype, gesture checks will skip"
  [ -e /dev/dri/renderD128 ] || log "note: no render node, falling back to llvmpipe (slow)"
  log "preflight ok"
}

start_sway() {
  cat > "$WORK/sway.conf" <<EOF
output HEADLESS-1 resolution $RES
# No bar, no bindings, no autostart: this compositor exists to hold a
# nested Hyprland and nothing else.
default_border none
EOF
  WLR_BACKENDS=headless WLR_LIBINPUT_NO_DEVICES=1 \
    sway --config "$WORK/sway.conf" > "$WORK/sway.log" 2>&1 &
  SWAY_PID=$!

  # sway names its socket unpredictably; find the one this pid owns rather
  # than guessing wayland-1 and racing whatever else is running.
  for _ in $(seq 1 40); do
    for sock in "$XDG_RUNTIME_DIR"/wayland-*; do
      case "$sock" in *.lock) continue ;; esac
      if SWAYSOCK="" WAYLAND_DISPLAY="$(basename "$sock")" \
           swaymsg -t get_version >/dev/null 2>&1; then
        export WAYLAND_DISPLAY="$(basename "$sock")"
        log "sway up on $WAYLAND_DISPLAY ($RES)"
        return 0
      fi
    done
    sleep 0.25
  done
  die "sway did not come up; see $WORK/sway.log"
}

start_hyprland() {
  # Deliberately minimal, and deliberately NOT the user's config: no
  # autostart, no apps. It does source Omarchy's bindings so dump-keymap has
  # real binds to read and hyprland.lua's gesture hooks get registered --
  # without that the overlay loads but has nothing to show.
  cat > "$WORK/hypr.conf" <<EOF
monitor = , preferred, auto, 1
general { border_size = 0 gaps_in = 0 gaps_out = 0 }
animations { enabled = false }
decoration { blur { enabled = false } }
misc {
  disable_hyprland_logo = true
  disable_splash_rendering = true
  force_default_wallpaper = 0
}
source = ~/.config/hypr/bindings.conf
exec-once = quickshell -n -p /usr/share/omarchy/shell
EOF
  Hyprland --config "$WORK/hypr.conf" > "$WORK/hypr.log" 2>&1 &
  HYPR_PID=$!

  # Its signature, not the host's: hyprctl talks to whichever instance the
  # signature names, and on a developer box the outer session is also live.
  for _ in $(seq 1 40); do
    SIG="$(hyprctl instances -j 2>/dev/null | python3 -c '
import json,sys,os
try: d=json.load(sys.stdin)
except Exception: sys.exit(1)
mine=os.environ.get("HYPRLAND_INSTANCE_SIGNATURE","")
for i in d:
    if i["instance"]!=mine: print(i["instance"]); break
' 2>/dev/null)"
    if [ -n "${SIG:-}" ]; then
      export HYPRLAND_INSTANCE_SIGNATURE="$SIG"
      log "nested Hyprland up (${SIG:0:16}...)"
      return 0
    fi
    sleep 0.25
  done
  die "nested Hyprland did not come up; see $WORK/hypr.log"
}

wait_for_plugin() {
  for _ in $(seq 1 40); do
    if omarchy-shell shell call "$PLUGIN_ID" grab 1 >/dev/null 2>&1; then
      log "plugin answering IPC"
      return 0
    fi
    sleep 0.5
  done
  die "plugin never answered; see $WORK/hypr.log"
}

shoot() {
  grim "$SHOTS/$1.png" 2>/dev/null && log "shot: $SHOTS/$1.png" \
    || log "WARN: grim failed for $1"
}

# The checks worth having a compositor for. Each one leaves a PNG; reading
# them is still a human's (or a model's) job -- this only guarantees the
# overlay was up, in a known state, with nothing else on screen.
run_checks() {
  omarchy-shell shell summon "$PLUGIN_ID" '{}' >/dev/null 2>&1
  sleep 2
  shoot 01-omarchy-board

  omarchy-shell shell call "$PLUGIN_ID" selectSource apps >/dev/null 2>&1
  sleep 2
  shoot 02-active-apps

  omarchy-shell shell call "$PLUGIN_ID" toggleBranchMenu "" >/dev/null 2>&1
  sleep 2
  shoot 03-version-picker
  omarchy-shell shell call "$PLUGIN_ID" toggleBranchMenu "" >/dev/null 2>&1

  omarchy-shell shell hide "$PLUGIN_ID" >/dev/null 2>&1
  sleep 1

  # The one thing no amount of IPC can stand in for. hyprland.lua listens on
  # input.keyboard.key; wtype speaks zwp_virtual_keyboard_v1. If Hyprland's
  # Lua hook only sees physical devices this proves nothing, so treat a
  # failure here as unknown rather than as a broken gesture.
  if command -v wtype >/dev/null 2>&1; then
    log "gesture: double-tap Super"
    wtype -M logo -m logo 2>/dev/null
    sleep 0.15
    wtype -M logo -m logo 2>/dev/null
    sleep 2
    shoot 04-gesture-double-tap
    omarchy-shell shell hide "$PLUGIN_ID" >/dev/null 2>&1
  fi
}

report() {
  echo
  echo "shots:"
  ls -1 "$SHOTS" 2>/dev/null | sed 's/^/  /'
  echo
  grep -iE 'error|warn|threw|ReferenceError|TypeError' "$WORK/hypr.log" 2>/dev/null \
    | grep -viE 'xkbcomp|ScrollLock' | head -10 | sed 's/^/  log: /'
  # Keep the shots even though $WORK is a mktemp dir: the caller wants to
  # look at them, and the trap only kills processes.
  echo "  (artefacts: $WORK)"
}

preflight
start_sway
start_hyprland
wait_for_plugin
run_checks
report
