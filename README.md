# OmarKEYS (Grok)

A Super+K alternative for [Omarchy](https://omarchy.org/). Topic-organized
keymap overlay, summoned without eating Super+other shortcuts.

Stable is **main** (Grok). Claude owns **beta** on
https://github.com/romills/OmarKEYs. When a beta is done, Grok pulls it
into `main` and updates [RELEASE.md](RELEASE.md). Cursor does not land
on `main`. Working copy: `~/Work/omarkeys-grok`.

**Open**

- Double-tap Super (optional)
- Hold Super (default 5 seconds)
- Super+K

**Close**

- Tap Super
- Escape
- Super+W (temporarily mapped to the overlay so it does not close the window behind it)
- Click the dimmed background

Type while it is open to filter, including digits.

**Navigate**

- Arrow keys move the highlight (up/down command, left/right group)
- `Ctrl+1`–`Ctrl+9` jump to a numbered group (`Ctrl+0` is the 10th)
- Enter or click runs the highlighted shortcut
- Greyed-out rows (ranges, holds, double-tap) cannot be run

**Sidebar**

- Tree: **Omarchy** (expanded) with topic groups under it; **Open windows**
  for live apps (click a window to load its sheet)
- Groups: show or hide topic cards; All/None on the Omarchy row
- Modifiers: each of Super, Shift, Ctrl, Alt is Any / Must / Hide.
  Click a name to cycle it, or click **A any**, **M must**, **H hide** to set all four.

**Settings** (bottom of the overlay)

- Double-tap Super on/off
- Hold Super duration, 1–10 seconds
- Edit mode (Omarchy source): pick a command, then press its new chord

App windows with a bundled sheet (Chromium, Ghostty, Nautilus) can be
selected in the overlay; those sheets live in `sheets/`.

Bindings are read live from Hyprland each time OmarKEYS opens. Settings
are stored in `~/.config/omarchy/omarkeys.json`. Remaps write
`~/.config/hypr/omarkeys-edits.lua` and keep a git history under
`~/.local/state/omarchy/omarkeys-history`.

## Dependencies and privileges

Omarchy plugins run unsandboxed inside the long-running shell process with
your user's permissions, so here is everything OmarKEYS reaches for.

**External commands**

| Command | Used for |
|---|---|
| `hyprctl` | Read binds and clients; dispatch the action of a row you run |
| `python3` | `dump-keymap`, `apply-edit`, `plugin-git`, and JSON quoting in `run-shortcut` |
| `lua` | Read the real action of each bind out of your Hyprland Lua config |
| `git` | Branch picker (status, fetch, checkout, fast-forward) and the edit history |
| `bash` | `run-shortcut`, `install.sh`, and invoking `omarchy restart shell` |
| `omarchy`, `omarchy-shell` | Enable/disable the plugin, rescan plugins, restart the shell |

**Files it writes**

| Path | What |
|---|---|
| `~/.config/omarchy/omarkeys.json` | Overlay settings (hidden groups, modifiers, gestures) |
| `~/.config/hypr/omarkeys-edits.lua` | Chord remaps made in the overlay |
| `~/.config/hypr/bindings.lua` | Installer appends one `dofile` line; backed up first |
| `~/.local/state/omarchy/omarkeys-history` | Git history of remaps, so an edit can be reverted |

**Privilege boundaries**

- Running a row dispatches that binding's **own** action, taken from your
  Hyprland config — an `exec` bind runs its command as you. OmarKEYS adds no
  commands of its own; it can only trigger what you already bound.
- Rows whose action cannot be recovered are shown dimmed and do nothing, so
  the overlay never guesses at what a key might mean.
- **Network:** only the branch picker, and only to the plugin's own git
  remote, when you check for updates or sync. Nothing else phones home.
- The picker can change which branch of this plugin is checked out and then
  run `omarchy restart shell`. It never starts a second Quickshell process,
  never force-pushes, never resets, and refuses to act on a dirty checkout.
- No root, no setuid, no system services, no remote build step.

## Install

Needs Omarchy Quattro (Hyprland Lua + `omarchy-shell` plugins), plus
`python3`, `lua`, and `git` on `PATH`.

```bash
git clone <this-repo> ~/Work/omarkeys
cd ~/Work/omarkeys
./install.sh
```

`install.sh` will:

1. Clone this repo to `~/.config/omarchy/plugins/io.github.romills.omarkeys`
2. Enable the overlay plugin
3. Point `~/.config/hypr/bindings.lua` at `hyprland.lua`
4. Reload Hyprland

### Already installed with a symlink?

Earlier versions symlinked the checkout into the plugins folder. Omarchy's
validator refuses a plugin folder that *is* a symlink, so
`omarchy plugin update` fails on those installs and rolls back:

```
omarchy-plugin-validate: symlinks are not allowed inside a plugin folder
omarchy-plugin-update: update of '...' failed validation; rolled back
```

Nothing is broken and nothing is lost — the plugin keeps working, it just
cannot be updated in place. Re-run the installer to convert it:

```bash
cd ~/Work/omarkeys && git pull && ./install.sh
```

### Updating

`omarchy plugin update` works on a normal (clone) install, and so does the
overlay's own corner picker. They divide up like this:

| On channel | Use |
|---|---|
| Main | `omarchy plugin update`, or the picker |
| Beta / Nightly | the picker's **Sync** |

`omarchy plugin update` always fetches the default branch (`main`) and
fast-forwards the checked-out branch onto it, so running it while on Beta
leaves a branch named `beta` sitting on main's commit. Recover with
`git checkout main && git branch -D beta` in the plugin directory; the next
switch to Beta recreates it from `origin/beta`.

### Working on OmarKEYS itself

```bash
./install.sh --dev
```

Symlinks the checkout instead of cloning, so edits go live on
`omarchy restart shell`. `omarchy plugin update` and
`omarchy plugin validate` both reject a symlinked plugin folder, so use this
only on a machine where you are developing OmarKEYS.

Or add it like any other Omarchy plugin, then still run `./install.sh` so
the Super gestures are wired (the overlay alone has no Super hold/double-tap).

```bash
omarchy plugin add <git-url> --enable
./install.sh
```

## Uninstall

```bash
./install.sh --uninstall
```

## Layout

This repository root *is* the Omarchy plugin (`manifest.json` at the top).
Hyprland activation lives in `hyprland.lua` and is `dofile`d from your
user bindings file so Super+chords stay unmodified.

| Path | Role |
|---|---|
| `Keymap.qml` | Overlay host: config, live dump, keys, execute |
| `KeymapSidebar.qml` | The tree: Omarchy areas/groups and Active Apps |
| `KeymapBoard.qml` | Two-column binding cards |
| `KeymapSection.qml` / `KeymapRow.qml` | One topic card and one command row |
| `KeymapOptionsMenu.qml` | Options popup: display, modifiers, gestures |
| `KeymapHideButton.qml` | Show/Hide control used in the tree |
| `KeymapData.js` | Filter, catalog, shortcut parse, fallback list |
| `dump-keymap` | Live Hyprland binds → JSON sections |
| `apply-edit` | Remap a chord into `omarkeys-edits.lua` |
| `sheets/` | Bundled app keymaps (Chromium, Ghostty, Nautilus) |
| `run-shortcut` | Replay a chord after the overlay closes |
| `hyprland.lua` | Super+K, double-tap, hold |

## License

MIT
