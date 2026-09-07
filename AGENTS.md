# OmarKEYS

Omarchy overlay plugin. Repo root *is* the plugin (`manifest.json` here)
so `omarchy plugin add <git-url>` works.

## Layout

| Path | Role |
|---|---|
| `manifest.json` | Plugin id `io.github.romills.omarkeys`, overlay entry |
| `Keymap.qml` | Overlay host: config, dump, keyboard, execute |
| `KeymapSidebar.qml` | Group visibility and modifier Any/Must/Hide |
| `KeymapBoard.qml` | Two-column section grid |
| `KeymapSection.qml` | One topic card |
| `KeymapRow.qml` | One command row |
| `KeymapSettingsBar.qml` | Double-tap toggle and hold slider |
| `KeymapData.js` | Grouped bindings, filters, shortcut helpers |
| `hyprland.lua` | Super double-tap / hold / Super+K |
| `run-shortcut` | Run a selected row after the overlay closes (`--dispatch` for Hyprland binds; chord replay for app sheets) |
| `dump-keymap` | Read live Hyprland binds into OmarKEYS JSON sections |
| `apply-edit` | Remap a chord; required at runtime by edit mode |
| `plugin-git` | Branch/update state for the corner picker; switch + sync |
| `KeymapBranchMenu.qml` | Corner channel picker: Main/Beta/Nightly, sync to latest |
| `sheets/` | Bundled per-app keymap JSON; required for app sources |
| `install.sh` | Symlink plugin, wire Hyprland, enable |

Keep overlay logic in the host (`Keymap.qml`) and UI chrome in the child
QML files. `KeymapData.js` is the only place that decides which rows are
visible (search, hidden groups, modifier modes). Roadmap: `PLAN.md`.

## Validation

```sh
omarchy plugin validate .
node --test tests/keymap-data.test.js
git diff --check
```

After editing `hyprland.lua` on a live install:

```sh
hyprctl reload
hyprctl configerrors
```

QML changes need `omarchy restart shell` (keepLoaded overlay).

## Repositories

This file lives in the **shared** Claude/Cursor repo
(https://github.com/romills/OmarKEYs). Grok's released line is a separate
repo (https://github.com/romills/OmarKEYs-grok). Do not treat a shared-repo
clone as Grok's tree.

| Remote | URL | Role |
|---|---|---|
| `origin` | https://github.com/romills/OmarKEYs.git | Shared repo. `develop` is integration; Cursor works on `develop-cursor`. |
| `grok` (optional) | https://github.com/romills/OmarKEYs-grok.git | Grok's released line. Read-only for Claude and Cursor. |

## Cursor's clone

Cursor's directory on the Omarchy machine is `~/Work/omarkeys-cursor`.
Origin is the shared repo above. Do not commit in `~/Work/omarkeys-grok`
or the deploy slot `~/Work/omarkeys`.

Bootstrap on the Omarchy machine:

```sh
git clone https://github.com/romills/OmarKEYs.git ~/Work/omarkeys-cursor
cd ~/Work/omarkeys-cursor
git checkout develop-cursor
git pull origin develop-cursor
```

Cursor commits on `develop-cursor` (or a `cursor/*` feature branch) and
opens a PR into `develop`. Never push to `main` or `beta`.

## Grok's repository (OmarKEYs-grok)

Grok's clone is `~/Work/omarkeys-grok` with `origin` = OmarKEYs-grok.
Claude and Cursor do not commit there. Grok is the only one who promotes
into `main`:

```sh
cd ~/Work/omarkeys-grok
git checkout main
git fetch shared
git merge --no-ff shared/develop
git push origin main
```

Do not push Grok commits to the shared repo unless handing a patch back.

## Working copies

**`~/Work/omarkeys` is not a workspace. Do not edit or commit in it.**

It is the **deploy slot**: `~/.config/omarchy/plugins/io.github.romills.omarkeys`
symlinks here. It only switches branches and pulls. The overlay's corner
branch picker refuses to switch or sync when this tree is dirty.

| Path | Who | Purpose |
|---|---|---|
| `~/Work/omarkeys-grok` | Grok | OmarKEYs-grok. Edit and commit there. |
| `~/Work/omarkeys-claude` | Claude | Shared-repo clone |
| `~/Work/omarkeys-cursor` | Cursor | Shared-repo clone (`origin` = OmarKEYs) |
| `~/Work/omarkeys` | nobody | Deploy slot. No edits. |

To test a branch live, point the deploy slot at it (corner picker, or
`git -C ~/Work/omarkeys checkout <branch>`) and `omarchy restart shell`.

## Branches

| Branch | Owner | Role |
|---|---|---|
| `main` | Grok | **Main channel.** Released/stable; Grok promotes `beta` into `main` |
| `beta` | Claude | **Beta channel.** Tested, ahead of stable; Claude promotes `develop` into `beta` |
| `develop` | Claude (integration) | Integration branch; only accepts approved merges from `develop-claude` and `develop-cursor` |
| `develop-claude` | Claude | Claude's working integration branch; feature branches merge here first, brought into `develop` once approved |
| `develop-cursor` | Cursor | Cursor's own integration branch; opens a PR into `develop` when ready to hand work back |
| `feature/phase2-sidebar-tree` | Claude | Off `develop-claude` |
| `feature/phase3-view-edit-ui` | Claude | Off `develop-claude` |

### Release channels

The overlay's corner picker exposes three channels, not raw branches, so
someone who just wants a working keymap never has to reason about our
branch names:

| Channel | Branch | Who it is for |
|---|---|---|
| Main | `main` | Stable |
| Beta | `beta` | Tested, ahead of stable |
| Nightly | any other branch | Us — the list is behind a disclosure |

Promotion runs one way: `develop` → `beta` (Claude) → `main` (Grok).
Do not promote a branch into a channel you do not own, and do not point a
channel at a working branch — Nightly already covers that case.

Rules: only the branch owner commits directly to it. Everyone else lands
changes via PR/merge after review. Claude's own feature work lands on
`develop-claude`, not `develop`, and only moves to `develop` once approved.
Cursor never pushes straight to `develop` or `main` — it PRs from
`develop-cursor`. Grok is the only one who merges into `main`. Claim a
PLAN.md item by prefixing it with the owner (e.g. `(cursor)`) before
starting so two agents don't duplicate work.

## Install on this machine

```sh
./install.sh
```

That symlinks this repo to `~/.config/omarchy/plugins/io.github.romills.omarkeys`
and `dofile`s `hyprland.lua` from `~/.config/hypr/bindings.lua`.

## Cursor Cloud specific instructions

The Cloud Agent VM is headless Ubuntu, not an Omarchy/Hyprland desktop.
`node` and `python3` are preinstalled (see `.cursor/environment.json`), so
these checks run here:

```sh
node --test tests/keymap-data.test.js   # data layer; 1 case needs a live host (see below)
python3 -m py_compile dump-keymap apply-edit
git diff --check
```

`omarchy plugin validate .`, `hyprctl reload`/`configerrors`, the running
overlay, and the `dump-keymap reads live Hyprland bindings` test all require
an Omarchy host (`omarchy`, `hyprctl`, `omarchy-menu-keybindings`). They are
not available headlessly, so that one node case is expected to fail on the
Cloud Agent VM; run them on a real Omarchy machine.
