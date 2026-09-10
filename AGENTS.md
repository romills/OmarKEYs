# OmarKEYS

Omarchy overlay plugin. Repo root *is* the plugin (`manifest.json` here)
so `omarchy plugin add <git-url>` works.

## Layout

| Path | Role |
|---|---|
| `manifest.json` | Plugin id `io.github.romills.omarkeys`, overlay entry |
| `Keymap.qml` | Overlay host: config, dump, keyboard, execute |
| `KeymapSidebar.qml` | Three panels: Omarchy, Workspaces (Active Apps), Options |
| `KeymapBoard.qml` | Two-column section grid |
| `KeymapSection.qml` | One topic card |
| `KeymapRow.qml` | One command row |
| `KeymapOptionsMenu.qml` | Options popup: display, filters, gestures |
| `KeymapChipSample.qml` | A chord drawn with a given setting, for the display options |
| `KeymapHideButton.qml` | Show/Hide control used at every level of the tree |
| `KeymapData.js` | Grouped bindings, filters, shortcut helpers |
| `hyprland.lua` | Super double-tap / hold / Super+K |
| `run-shortcut` | Run a selected row after the overlay closes (`--dispatch` for Hyprland binds; chord replay for app sheets) |
| `dump-keymap` | Read live Hyprland binds into OmarKEYS JSON sections |
| `apply-edit` | Remap a chord; required at runtime by edit mode |
| `plugin-git` | Channel picker state: switch + sync |
| `KeymapBranchMenu.qml` | Corner picker: Main / Beta / Nightly |
| `sheets/` | Bundled per-app keymap JSON; `kind` groups apps in the tree |
| `install.sh` | Install plugin (real directory; `--dev` to symlink), wire Hyprland |
| `RELEASE.md` | Release notes, written when promoting `beta` → `main`. |

Keep overlay logic in the host (`Keymap.qml`) and UI chrome in the child
QML files. `KeymapData.js` is the only place that decides which rows are
visible (search, hidden groups, modifier modes). Roadmap: `PLAN.md`.

## Validation

```sh
omarchy plugin validate .
node --test tests/*.test.js
git diff --check
```

After editing `hyprland.lua` on a live install:

```sh
hyprctl reload
hyprctl configerrors
```

QML changes need `omarchy restart shell` (keepLoaded overlay).

### Visual checks without taking over a desktop

`tests/headless-session.sh` brings the overlay up in a compositor of its
own and leaves screenshots behind, instead of restarting the shell on the
machine someone is using:

```
headless sway (virtual output) -> nested Hyprland -> quickshell + plugin
```

Sway is the host, not the thing under test. OmarKEYS is Hyprland-specific
-- the overlay reads Quickshell's `Hyprland` singleton, `dump-keymap`
shells out to `hyprctl`, and the Super gestures live inside Hyprland's Lua
config provider -- so under sway alone the overlay comes up with no keymap.
`wayvnc` attached to sway makes the nested session watchable live.

Needs `sway`, `Hyprland`, `quickshell`, `hyprctl`, `grim`, `omarchy-shell`;
`wtype` additionally for the gesture check. The script says which are
missing and does nothing else.

Not yet run end to end -- written before the box it targets was reachable.
Two things are unproven: whether `wtype`'s virtual keyboard reaches
`hl.on("input.keyboard.key")` (if not, the Super gestures still cannot be
tested anywhere), and whether a nested Hyprland loads Omarchy's Lua
bindings without a login session.

## Channels

One ladder, `develop-claude` → `develop` → `beta` → `main`. Each step is a
fast-forward, so a change that reaches `main` is the same commit that was
tested on `beta`.

| Branch | Channel | Owner | Fed by |
|---|---|---|---|
| `main` | Main | Claude | `beta` |
| `beta` | Beta | Claude | `develop` |
| `develop` | Nightly | Claude | `develop-claude`; PRs from `develop-cursor` |
| `develop-claude` | — | Claude | direct work |
| `develop-cursor` | — | Cursor | direct work; PRs into `develop` |

Claude promotes all three: `develop-claude` into `develop` once it is
approved, `develop` to `beta`, and a finished `beta` into `main`, writing
`RELEASE.md` at the last step. Grok reviews rather than promotes. Cursor
does not land on `main`.

Write release-note and version changes on the branch that *feeds* the one
being promoted, never directly on `beta` or `main` — a commit made on the
tip breaks the fast-forward and forces a back-merge to repair.

### Updating: `omarchy plugin update` is Main-only

Install as a real directory (the default `./install.sh`, or
`omarchy plugin add`) and both updaters work — the picker never needed the
symlink, it only needs a git repo at the plugin path.

They are not interchangeable, though:

| On channel | Use |
|---|---|
| Main | `omarchy plugin update`, or the picker |
| Beta, Nightly | the picker's **Sync** only |

`omarchy plugin update` fetches `origin HEAD`, which is always `main`, and
fast-forwards whatever branch is checked out onto it. Run it while the
picker has you on Beta and the fast-forward *succeeds*, leaving a branch
still called `beta` sitting on main's commit — so the corner label reads
`Beta @ <main's hash>` while running Main's code. Nothing is lost, but the
channel is then a lie.

To recover, from the plugin directory: `git checkout main`, then
`git branch -D beta`. The next switch to Beta recreates it cleanly from
`origin/beta`.

```sh
cd ~/Work/omarkeys-grok
git checkout main
git fetch shared
git merge --ff-only shared/beta
# update RELEASE.md, then:
git push origin main
git push shared main
```

## Install on this machine

```sh
./install.sh
```

That clones this repo to `~/.config/omarchy/plugins/io.github.romills.omarkeys`
and `dofile`s `hyprland.lua` from `~/.config/hypr/bindings.lua`. Use
`./install.sh --dev` to symlink a working checkout instead.
