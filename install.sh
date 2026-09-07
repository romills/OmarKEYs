#!/usr/bin/env bash
# Install OmarKEYS into Omarchy: install the plugin, enable it, wire Hyprland.
#
# Default is a real directory, because Omarchy's validator refuses a plugin
# folder that is a symlink -- `find <dir> -type l` reports the starting point
# itself -- which makes `omarchy plugin update` fail and roll back. Use --dev
# to symlink this checkout instead, which is what you want while working on
# OmarKEYS and what you must not ship to anyone else.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ID="io.github.romills.omarkeys"
OLD_ID="romills.omarkeys"
PLUGIN_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/plugins/${PLUGIN_ID}"
OLD_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/plugins/${OLD_ID}"
BINDINGS="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/bindings.lua"
UNINSTALL=0
DEV=0

for arg in "$@"; do
  case "$arg" in
    --uninstall) UNINSTALL=1 ;;
    --dev) DEV=1 ;;
    -h|--help)
      printf '%s\n' \
        "Usage: ./install.sh [--dev] [--uninstall]" \
        "  Install this repo into Omarchy plugins, enable OmarKEYS," \
        "  and load hyprland.lua from ~/.config/hypr/bindings.lua." \
        "" \
        "  --dev  symlink this checkout instead of copying it. Edits go live" \
        "         on 'omarchy restart shell', but 'omarchy plugin update'" \
        "         and 'omarchy plugin validate' both reject a symlinked" \
        "         plugin folder, so never use this for a real install."
      exit 0
      ;;
    *)
      echo "unknown option: $arg" >&2
      exit 2
      ;;
  esac
done

log() { printf '\033[1;36m==>\033[0m %s\n' "$*"; }

MARKER_BEGIN="-- OmarKEYS"
DOFLE_LINE="dofile((os.getenv(\"HOME\") or \"\") .. \"/.config/omarchy/plugins/${PLUGIN_ID}/hyprland.lua\")"

strip_omarkeys_from_bindings() {
  python3 - "$BINDINGS" "$PLUGIN_ID" <<'PY'
from pathlib import Path
import re, sys

path = Path(sys.argv[1])
plugin_id = sys.argv[2]
text = path.read_text()

patterns = [
    re.compile(r"\n-- OmarKEYS[\s\S]*?\nend\n", re.M),
    re.compile(r"\n-- SUPER\+K was the searchable keybinding menu[\s\S]*?\nend\n", re.M),
    re.compile(
        r"\ndofile\(\(os\.getenv\(\"HOME\"\) or \"\"\) \.\. \"/.config/omarchy/plugins/"
        + re.escape(plugin_id)
        + r"/hyprland\.lua\"\)\n"
    ),
]
for pat in patterns:
    text = pat.sub("\n", text)
text = re.sub(r"\n-- OmarKEYS\n+", "\n", text)
if not text.endswith("\n"):
    text += "\n"
path.write_text(text)
PY
}

if (( UNINSTALL )); then
  if command -v omarchy >/dev/null; then
    omarchy plugin disable "$PLUGIN_ID" >/dev/null 2>&1 || true
    omarchy plugin disable "$OLD_ID" >/dev/null 2>&1 || true
  fi
  if [[ -L $PLUGIN_DIR ]]; then
    rm -f "$PLUGIN_DIR"
    log "removed symlink $PLUGIN_DIR"
  elif [[ -d $PLUGIN_DIR ]]; then
    rm -rf "$PLUGIN_DIR"
    log "removed $PLUGIN_DIR"
  fi
  if [[ -f $BINDINGS ]]; then
    cp "$BINDINGS" "$BINDINGS.bak.$(date +%s)"
    strip_omarkeys_from_bindings
    log "removed OmarKEYS from $BINDINGS"
  fi
  if command -v hyprctl >/dev/null; then
    hyprctl reload >/dev/null || true
  fi
  log "OmarKEYS uninstalled. Restore Super+K with: omarchy refresh hyprland  (only if you want stock bindings back)"
  exit 0
fi

mkdir -p "$(dirname "$PLUGIN_DIR")"
chmod +x "$ROOT/run-shortcut" "$ROOT/dump-keymap" "$ROOT/apply-edit" "$ROOT/plugin-git"

if (( DEV )); then
  if [[ -e $PLUGIN_DIR && ! -L $PLUGIN_DIR ]]; then
    backup="${PLUGIN_DIR}.bak.$(date +%s)"
    mv "$PLUGIN_DIR" "$backup"
    log "moved existing plugin dir -> $backup"
  fi
  ln -sfn "$ROOT" "$PLUGIN_DIR"
  log "symlinked $PLUGIN_DIR -> $ROOT"
  log "dev install: 'omarchy plugin update' and 'validate' will reject this symlink"
else
  # A git clone, not a copy: `omarchy plugin update` drives the plugin dir
  # with git fetch + merge --ff-only, so it needs real history to update.
  [[ -L $PLUGIN_DIR ]] && { rm -f "$PLUGIN_DIR"; log "removed old symlink $PLUGIN_DIR"; }
  origin="$(git -C "$ROOT" remote get-url origin 2>/dev/null || true)"
  if [[ -d $PLUGIN_DIR/.git ]]; then
    log "plugin already installed at $PLUGIN_DIR; update it with: omarchy plugin update $PLUGIN_ID"
  elif [[ -n $origin ]]; then
    [[ -e $PLUGIN_DIR ]] && { mv "$PLUGIN_DIR" "${PLUGIN_DIR}.bak.$(date +%s)"; log "moved existing plugin dir aside"; }
    branch="$(git -C "$ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo main)"
    git clone --quiet --branch "$branch" "$origin" "$PLUGIN_DIR"
    log "cloned $origin ($branch) -> $PLUGIN_DIR"
  else
    fail_msg="no git origin to clone from; run from a clone, or use --dev to symlink"
    echo "install.sh: $fail_msg" >&2
    exit 1
  fi
fi

if command -v omarchy >/dev/null && ! omarchy plugin validate "$PLUGIN_DIR" >/dev/null 2>&1; then
  log "WARNING: $PLUGIN_DIR does not pass 'omarchy plugin validate'"
fi

if command -v omarchy >/dev/null; then
  omarchy-shell shell rescanPlugins >/dev/null 2>&1 || true
  omarchy plugin disable "$OLD_ID" >/dev/null 2>&1 || true
  omarchy plugin enable "$PLUGIN_ID"
  log "enabled $PLUGIN_ID"
fi

if [[ -d $OLD_DIR && ! -L $OLD_DIR ]]; then
  log "left old plugin at $OLD_DIR (disabled). Remove it when you like."
fi

if [[ -f $BINDINGS ]]; then
  cp "$BINDINGS" "$BINDINGS.bak.$(date +%s)"
  strip_omarkeys_from_bindings
  printf '\n%s\n%s\n' "$MARKER_BEGIN" "$DOFLE_LINE" >> "$BINDINGS"
  log "wired $BINDINGS -> hyprland.lua"
  if command -v python3 >/dev/null; then
    "$ROOT/apply-edit" wire >/dev/null || true
    log "wired $BINDINGS -> omarkeys-edits.lua"
  fi
else
  echo "missing $BINDINGS" >&2
  exit 1
fi

if command -v omarchy >/dev/null; then
  omarchy plugin validate "$ROOT"
fi

if command -v hyprctl >/dev/null; then
  hyprctl reload
  sleep 0.2
  errors="$(hyprctl configerrors || true)"
  if [[ -n ${errors// } ]]; then
    echo "$errors" >&2
    exit 1
  fi
  log "Hyprland reloaded"
fi

log "OmarKEYS ready. Super+K, double-tap Super, or hold Super 5s."
