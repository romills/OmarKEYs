# OmarKEYS

A Super+K alternative for [Omarchy](https://omarchy.org/). Topic-organized
keymap overlay, summoned without eating Super+other shortcuts.

Repo: https://github.com/romills/OmarKEYs. Work climbs one ladder —
`develop-claude` → `develop` → `beta` → `main`:

| Branch | Channel | Owner |
|---|---|---|
| `main` | Main | Claude promotes a finished beta and writes [RELEASE.md](RELEASE.md) |
| `beta` | Beta | Claude |
| `develop` | Nightly | Claude integrates; Cursor opens PRs into it from `develop-cursor` |
| `develop-claude` | — | Claude's working branch |
| `develop-cursor` | — | Cursor's working branch |

Cursor does not land on `main`.

**Open**

- Double-tap Super (optional)
- Hold Super (default 5 seconds, optional)
- Super+K (optional)

At least one of the three always stays on, so they cannot all be turned off.

The gestures follow whatever key your keymap actually puts Super on, asked
of the keymap the first time you press it rather than assumed from a
keycode — so an `altwin:` option that moves Super does not leave them
firing from the key it vacated. Super+K works either way.

The overlay opens on the monitor you were working on and stays there. The
dimming covers every screen; the card does not follow the pointer to
another display.

**Close**

- Tap Super
- Escape
- Super+W (temporarily mapped to the overlay so it does not close the window behind it)
- Click the dimmed background

Type while it is open to filter, including digits.

**Navigate**

- Arrow keys move the highlight (up/down command, left/right group)
- `Ctrl+1`–`Ctrl+9` jump to a numbered group (`Ctrl+0` is the 10th)
- Click highlights a row; **double-click** or Enter runs it. Running takes
  two deliberate actions so a click while reading cannot fire a shortcut
  and close the overlay under you.
- Greyed-out rows cannot be run: ranges, gestures, and any bind whose
  action OmarKEYS could not recover from your config

**Sidebar** — three panels: Omarchy, Active Apps, Options

The **Options** panel holds the settings worth reaching for while reading
the board,
without opening the popup. They sit under an **Options** heading: **Grouping** 󰋃, **Sort** 󰒺 and **Order** 󰣟, each
showing its current mode underneath and cycling on click. Order swaps
between keys first and keys last. The **Filter** 󰈲 keeps its own column under Grouping, mode label and all,
with the box beside it across the other two. Clicking the icon changes what
is matched; typing anywhere in the overlay lands in the box.

**All** reads the length of what you typed: one character is treated as a
key, more than one searches everything — keys, descriptions and topics. So
`k` finds binds on K, while `delete` finds the Delete key *and* anything
described with the word.

In key mode, clicking the box arms it: the next keystroke is taken whole,
modifiers included, so `Super+Shift+B` filters on that chord and finds the
binds that use all of it. That is the only way to filter on Return or
Escape, which do other jobs the rest of the time. Elsewhere, clicking the
box clears it. Filtering by key holds a *single* key, so a keystroke
replaces what is in the box rather than adding to it, and it matches whole
keys only — pressing `k` finds binds on K, not every chord with a `k`
somewhere in a key's name. A digit matches the ranges that contain it, so
`3` finds the `1-9` workspace binds.

In key mode the named keys filter as themselves too, so pressing Delete
finds what Delete is bound to. Keys that also drive the overlay — Return,
Tab, Backspace and the arrows — filter only while the box is empty; once
there are results they go back to moving through them. **Escape** clears the
box, and closes the overlay when the box is already empty — so to filter
*on* Escape, arm the box and press it.

**Omarchy** and **Active Apps** are one choice between them, not two
branches: the selected one is accented and its keymap fills the board.
Clicking either root switches, and so does clicking anything inside
either tree.

- **Omarchy** (marked with the Omarchy glyph): five areas, each
  holding its topic groups
- **Active Apps**, headed by a workspace selector — `Workspace 1 2 3 4 ALL`
  — over the live windows, grouped by the keymap sheet they share
  (Web apps, Terminals, File managers) and then by app. Click any row in
  the branch — the kind, the app, or a window under it — to load that
  the app view; double-click a window to focus it. **Active Apps** shows
  every kind's keymap at once, one set per kind rather than per app —
  apps sharing a sheet share their bindings, so repeating them per window
  would say the same thing several times. Each card names the kind it
  came from. In the selector, clicking
  a number filters the list to that workspace and clicking **ALL** removes
  the filter; double-clicking a number switches to that workspace. It
  starts on ALL and stays where you put it until the overlay is reopened.
  Filtering scopes an app to the windows it has there, so an app on two
  workspaces shows only the relevant ones. On **ALL**, each row carries a
  faint workspace number in the app-name column — on an app only when its windows
  agree, since one spread across two workspaces has no single number to
  show; its windows carry their own. An app with windows on two workspaces appears under both, each
  time with only the windows it has there. Apps with no bundled sheet sit
  under **No keymap sheet**, pinned to the bottom.
- Click an area or group to *solo* it — everything else hides so the board
  shows only what you clicked. Clicking **Omarchy** restores all of them.
  Solo is view-only and is undone when the overlay closes.
- Every row carries a **Show**/**Hide** control, revealed when you hover it.
  Hiding a branch collapses and greys it but keeps its label, so it can
  always be brought back. Carets show the state: collapsed when everything
  under a parent is hidden, expanded while any of it still shows.

**All Options** (at the foot of the tree, under the filter)

*Display*

| Option | Values | Default |
|---|---|---|
| Keyboard 󰧹 | text / ⌘ mac /  windows /  omarchy | windows |
| Keys 󰌌 | full / short / icons | icons |
| Border 󰃇 | on / off | off |
| Size | slider, click the label to reset | 1.0 |

The first three sit side by side — title, icon, current setting — with a
sample chord ruled off beneath them, drawn as the board would draw it. The
sample shows what the three add up to, which none of their names does.
**Keys** and **Border** describe how an icon is drawn, so they dim while
the chips are words; both stay clickable, since Keys is how you get icons
back. Grouping, Sort, Order and Find are not repeated here; they have their
own controls under the tree.

With icons on, hovering a row spells each glyph out in words beside it.

**Keyboard** picks which keyboard's keycaps the modifier chips
imitate. It moves all four modifiers together, and applies in every chip
style — choosing a layout is pointless if its keycaps only show in icon
mode.

| Set | Super | Ctrl | Shift | Alt |
|---|---|---|---|---|
| text | Super | Ctrl | Shift | Alt |
| mac | ⌘ | ⌃ | ⇧ | ⌥ |
| windows |  | Ctrl | Shift | Alt |
| omarchy |  | Ctrl | Shift | Alt |

Mac is the only layout that gives all four a symbol; a PC keycap prints
the words, so those sets supply a logo for Super and leave the rest as
text. Omarchy's own mark is block-drawing art rather than a font glyph,
so that set uses the Arch logo. Every glyph was checked against the
overlay's font before mapping.

**Grouping** by key type replaces the topic cards with four buckets —
Numbers, Alpha, Special, Non-keyboard — filed on the key you actually
press. Mouse buttons, media keys and the Super gestures are not keys on
a keyboard, so they go last rather than under a letter they do not have.
Off drops the cards entirely and lists every row as one run, split down
the middle across the two columns. In both of those modes each row
trails its topic in faint, smaller text after the description — once
the headings are gone that is the only place it survives. **Sort by key** files a
chord under the key you actually press — `Super+Shift+K` sorts under `K`.
Sorting on the whole chord would file almost everything under S, since
almost every bind starts with Super.

One **Size** slider covers everything: chip text, glyphs and the padding
around them all scale together, so a chord keeps its proportions at any
setting. Icons are drawn a little larger than letters to read the same
size, by a fixed amount that does not depend on the border — toggling
Border changes the outline and nothing else.

**Icon borders** draws a cap around each key. Only keys you press get
one — a glyph standing for what the key *does* (volume, brightness) or for
a mouse button is not a cap, so those stay loose whatever this is set to.
Words are always capped, since a chip of text needs an edge to read as a
key at all.

Command is Super, not Option: on a Mac keyboard under Linux it is Command
that reports `KEY_LEFTMETA` and therefore arrives as Super, while Option
arrives as Alt. The kernel names them that way itself — `hid_apple`'s
`swap_opt_cmd` parameter reads *"Swap the Option (Alt) and Command (Flag)
keys"*, defaulting to the unswapped Mac layout.

*Filters* — Super, Shift, Ctrl and Alt in a 2×2 grid. A **clear** key is
**A**ll and carries no mark; click it to require it (**M**ust), again to
drop rows that use it (**H**ide), again to clear. Only the states you
chose are marked, so anything showing a letter is a filter you set. The
legend words set all four at once.

*Opening* — Super+K, double-tap Super and hold Super each on/off, plus the
hold duration (1–10s). The last one still on refuses to switch off: with
all three disabled there is no way back into the overlay short of editing
`omarkeys.json` by hand.

Turning **Super+K** off hands the chord back to whatever held it before
OmarKEYS (Omarchy binds it to **Keybindings**). It works by not claiming
the key rather than by rebinding it, so your own remap of Super+K survives
untouched. The bind lives in `hyprland.lua`, which only re-reads its config
when Hyprland does, so flipping this runs `hyprctl reload` — the same
reload the installer does, and it costs nothing else.

**Restore defaults** (bottom right of the popup) resets every one of the
above, plus hidden groups and apps and the search box.

**Version** (bottom-right corner) reads `Version: 1.15.0.0`. Click it and a
popup shows that version and the plugin id — what a bug report needs to name
which build it is about.

It reads the manifest and nothing else, so it works whatever shape the
install is; not every plugin directory is a git clone. Picking and
installing a different version is **OmarVerTester**'s job — a separate tool
that does that for any Omarchy plugin, rather than each plugin carrying its
own copy of a package manager. This corner will find that tool and show
what it knows once it exists.

Each group heading says which keymap it came from: the Omarchy mark for
Omarchy's own binds, or the app's name in brackets when a sheet is loaded.

App windows with a bundled sheet (Chromium, Ghostty, Nautilus) can be
selected in the overlay; those sheets live in `sheets/`.

Bindings are read live from Hyprland each time OmarKEYS opens, and
settings are stored in `~/.config/omarchy/omarkeys.json`.

## Dependencies and privileges

Omarchy plugins run unsandboxed inside the long-running shell process with
your user's permissions, so here is everything OmarKEYS reaches for.

**External commands**

| Command | Used for |
|---|---|
| `hyprctl` | Read binds and clients; dispatch the action of a row you run; reload the config when Super+K is toggled |
| `python3` | `dump-keymap`, `apply-edit`, and JSON quoting in `run-shortcut` |
| `lua` | Read the real action of each bind out of your Hyprland Lua config |
| `git` | The edit history behind Restore default |
| `bash` | `run-shortcut`, `install.sh`, and invoking `omarchy restart shell` |
| `omarchy`, `omarchy-shell` | Enable/disable the plugin, rescan plugins, restart the shell |

**Files it writes**

| Path | What |
|---|---|
| `~/.config/omarchy/omarkeys.json` | Overlay settings (display options, hidden groups and apps, modifiers, gestures) |
| `~/.config/hypr/bindings.lua` | Installer appends one `dofile` line; backed up first |
| `~/.config/hypr/omarkeys-edits.lua` | Chord remaps — written only by `apply-edit` |
| `${XDG_STATE_HOME:-~/.local/state}/omarchy/omarkeys-history` | Git history of remaps, so an edit can be reverted |

The last two are the chord-remap backend. It ships and works from the
command line, but **nothing in the overlay calls it yet** — the View | Edit
UI is unbuilt (see [PLAN.md](PLAN.md)), so a stock install never writes
either path.

**Privilege boundaries**

- Running a row dispatches that binding's **own** action, taken from your
  Hyprland config — an `exec` bind runs its command as you. OmarKEYS adds no
  commands of its own; it can only trigger what you already bound.
- Rows whose action cannot be recovered are shown dimmed and do nothing, so
  the overlay never guesses at what a key might mean.
- **Network:** none. The overlay never contacts anything.
- The overlay does not fetch, check out, or change what is installed.
  Switching versions moved out to **OmarVerTester**; this plugin reads its
  own manifest and stops there.
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

#### Exactly what the installer touches

It runs as your user and needs no root. Everything it writes is under
`$XDG_CONFIG_HOME` (`~/.config` by default), and the only network access is
cloning this repository from the origin your checkout already points at.

| Path | What happens to it |
|---|---|
| `~/.config/omarchy/plugins/io.github.romills.omarkeys/` | Created, as a `git clone` of this repo on the branch you ran the installer from. With `--dev`, a symlink to your checkout instead. |
| `~/.config/hypr/bindings.lua` | **Copied to `bindings.lua.bak.<epoch>` first**, then any previous OmarKEYS block is stripped and one `dofile(...)` line appended under an `-- OmarKEYS` marker. Nothing else in the file is altered. |
| `run-shortcut`, `dump-keymap`, `apply-edit` | Made executable, in your checkout. |
| Omarchy plugin registry | `omarchy plugin enable io.github.romills.omarkeys`; the pre-rename id `romills.omarkeys` is disabled if present. |
| Hyprland | `hyprctl reload`, then `hyprctl configerrors` — a non-empty result fails the install rather than leaving a broken config. |

Nothing is deleted. An existing plugin directory is moved aside to
`<dir>.bak.<epoch>` rather than overwritten, and an old plugin at the
previous id is left in place, disabled, for you to remove.

`./install.sh --uninstall` reverses all of it: the plugin directory goes,
and the OmarKEYS block is stripped from `bindings.lua` — again after a
timestamped backup. Your original Super+K binding comes back with
`omarchy refresh hyprland`.

Super+K is the one existing binding OmarKEYS claims, and only while the
**Super+K** toggle in the overlay's Options is on. Turned off it never
unbinds the chord, so whatever held it keeps it.

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

`omarchy plugin update` works on a normal (clone) install, and is the way
to update on **Main**.

Off Main there is currently no in-overlay update. The corner used to switch
and sync; that moved out to **OmarVerTester**, which does not exist yet, so
until it does a Beta or Nightly checkout is updated from the plugin
directory by hand:

```bash
cd ~/.config/omarchy/plugins/io.github.romills.omarkeys
git pull --ff-only
omarchy restart shell
```

Do **not** reach for `omarchy plugin update` there. It always fetches the
default branch (`main`) and fast-forwards whatever branch is checked out
onto it, so running it on Beta *succeeds* and leaves a branch named `beta`
sitting on main's commit — the label then lies about what you are running.
Recover in the plugin directory with `git checkout main`, then
`git branch -D beta`, then `git checkout -b beta origin/beta`.

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
| `KeymapHideButton.qml` | Show/Hide control, used at every level of the tree |
| `KeymapOptionsMenu.qml` | Options popup: display, modifiers, opening gestures |
| `KeymapVersionPopup.qml` | Corner popup: which version is running |
| `KeymapData.js` | Filter, catalog, shortcut parse, fallback list |
| `dump-keymap` | Live Hyprland binds → JSON sections |
| `run-shortcut` | Runs a row after the overlay closes: dispatches the bind's own action, or sends the chord for app-sheet rows |
| `apply-edit` | Remap a chord into `omarkeys-edits.lua` (no UI yet) |
| `install.sh` | Install the plugin and wire the Hyprland gestures |
| `sheets/` | Bundled app keymaps (Chromium, Ghostty, Nautilus) |
| `tests/` | `node --test tests/*.test.js` |
| `hyprland.lua` | Super+K, double-tap, hold |

## License

MIT
