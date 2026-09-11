# OmarKEYS release notes

Written when a finished **beta** is promoted into **main**. Cursor does not
land on `main`.

## 1.16.0.0 — 2026-09-11

Promoted from `beta`. Cursor not included.

- **The corner reports a version; it no longer switches one.** Clicking it
  shows the release and the plugin id — what a bug report needs to name
  which build it is about. The channel picker that used to live there
  (Channel and Versions tabs, the 1.0/2.0 track row, the tree of tagged
  releases, the cloud update button) is moving to **OmarVerTester**, a tool
  for picking and installing versions of any Omarchy plugin, rather than
  each plugin carrying its own copy of a package manager.
- **The overlay makes no network access at all**, and executes no git.
  `plugin-git` is gone. The version comes from the manifest, which also
  means it works whatever shape the install is — a plugin directory is not
  always a git clone.

Gone with the picker, deliberately: the channel name and commit hash in the
corner, and the **restart to load** warning that noticed the checkout moving
under a running shell. That warning existed because the picker could move
the checkout from inside the overlay, and nothing here does that now.
OmarVerTester owns all of it; this corner will ask that tool for it once it
exists.

Updating on Main is `omarchy plugin update`. Off Main, until OmarVerTester
lands, pull in the plugin directory by hand — see the README.

## 1.15.0.0 — 2026-09-10

Promoted from `beta`. Cursor not included. A packaging and documentation
release: nothing about the overlay itself changed.

- **`AGENTS.md` is no longer part of the plugin.** The marketplace does not
  permit agent-control files in a distributed payload -- a file like that
  inside an installed tree can inject repository-supplied instructions into
  any coding agent working in or above the plugin directory. There was
  nothing to exclude it from either, since this repo *is* what gets
  installed, so it now lives outside the repo entirely.
- **The installer says exactly what it touches.** README lists every path
  it writes, states that it needs no root and that its only network access
  is cloning this repo, and spells out that `bindings.lua` is backed up
  before it is edited, that nothing is ever deleted -- an existing install
  is moved aside, not overwritten -- and that Super+K is the one existing
  binding claimed, only while its toggle is on.
- For contributors: `tests/headless-session.sh` brings the overlay up in a
  compositor of its own -- headless sway holding a nested Hyprland -- so
  visual checks stop requiring someone's live desktop. Gesture input there
  has to go through `ydotool`/uinput; the Wayland virtual-keyboard protocol
  moves nothing in Hyprland, silently.

## 1.14.0.0 — 2026-09-10

Promoted from `beta`. Cursor not included. First release carrying
contributed changes: **Super detection** and **the per-monitor card** are
[@curmorpheus](https://github.com/curmorpheus)'s work.

- **The sidebar is three panels**: Omarchy, Active Apps and Options.
  Omarchy and Active Apps are one choice rather than two trees — picking
  either switches the board, and clicking anywhere inside a panel picks
  it. Options is pinned to the bottom edge whatever height the trees
  above it take.
- **A workspace selector**, `Workspace 1 2 3 … ALL`, above the Active Apps
  heading, replacing the workspace level added in 1.13.0.0: filtering to a
  workspace scopes both the tree and the board to what is actually on it,
  and ALL shows every app with its workspace beside each instance.
- **Active Apps shows every kind at once**, each section tagged with the
  kind whose sheet it came from, rather than one app at a time.
- **A Track row in the version picker**, 1.0 and the 2.0 line being built
  alongside it. It filters rather than switches, and opens on the track
  the running build belongs to.
- **Versions reaches other tracks.** The list is no longer filtered down
  to the selected track: other tracks come after it, marked *switches
  track*, so a build on 1.0 can move up to a tagged 2.0 release by
  loading it and come back down the same way. `fetch` asks for tags
  explicitly, so a release cut on an untracked branch still arrives.
- **More room between things.** The row's columns are separated by named
  gutters that scale with the Size slider, instead of the 4 and 8 pixels
  that made a row read as one run of text; section cards are inset evenly
  and the board's gaps step up to match.
- Fixed: **Active Apps showed no keymaps at all** with more than one kind
  of app open. The sheet queue advanced by assigning `FileView.path` from
  inside that same FileView's `onLoaded`, which starts no second load — so
  the first sheet landed, the queue stopped, and the board kept whatever
  was already there.
- Fixed: the kind tags were missing from those headings. `columns()`
  rebuilds each section object field by field and dropped the qualifier,
  leaving two kinds contributing a "Close tab" section apiece with nothing
  to tell them apart.
- Fixed: picking a workspace narrowed the tree but left the board on every
  kind. The reload ran from the filter's own change handler and read a
  binding whose only dependency was that same property, so it answered
  with the pre-change value.
- Fixed: **the gestures could fire from the wrong key.** The Super
  keycodes were hardcoded, and `input.keyboard.key` reports XKB keycodes
  rather than evdev ones, so two of the four named keypad keys; the other
  two are Super only until an XKB option moves it. The fallback that
  covered for this read the keyboard state from *before* the event, so
  with Super held the next key pressed was taken for Super. The keymap is
  asked at runtime now, once per keyboard.
- Fixed: **the overlay appeared on every monitor** and its keyboard focus
  followed `Hyprland.focusedMonitor`, so under `follow_mouse` it chased
  the pointer to another display. The monitor it opened on is latched, and
  the card finds its way back if an output blinks.

## 1.13.0.0 — 2026-09-09

Promoted from `beta`. Cursor not included. First release numbered
`1.<main>.<beta>.<dev>`, where a main release resets the beta count and a
beta cut resets the dev count.

- **Active Apps gains a workspace level.** Workspace 1..n, each holding
  the app groupings you already had but scoped to the windows actually on
  it — an app with windows on two workspaces appears under both, each
  time with only the ones there. Double-click a workspace to switch to it;
  the caret folds it.
- **Options is an icon panel**: Keyboard, Keys and Border side by side,
  each with its current setting, over one sample chord drawn exactly as
  the board draws it. One **Size** slider covers chip text, glyphs and
  padding together.
- The board's group titles sit in a tinted bar, so a card reads as a block
  rather than as a line of text above some rows.
- Fixed: **the overlay would not open at all** when a QML file set one
  property twice — a component that does is refused, and everything using
  it goes with it. qmllint does not report that, so there is now a test.
- Fixed: double-clicking a workspace did nothing. It dispatched
  `workspace <id>`, which the Lua config provider parses as Lua and
  rejects with a syntax error — silently. It uses the same call Omarchy's
  own bind makes now.
- Fixed: a click on a workspace row folded it, which fired under the first
  half of the double-click meant to switch to it.
- Fixed: selecting a row could drop the scroll-into-view and log
  `board is not defined`, when a rebuild destroyed the delegate before the
  deferred call ran.

## 1.12.1.0 — 2026-09-08

Promoted from `beta` (`3e9ba94`). Never released to `main` on its own;
folded into 1.13.0.0. Cursor not included.

- **Load a released version.** The picker has Channel and Versions as
  tabs: Channel picks a line of work that keeps moving, Versions picks a
  release that does not, shown as a tree grouped by main version.
- **A floor that cannot be talked around.** Only builds carrying the
  `versionPicker` marker in their manifest are offered, and the marker is
  read out of the target tree before any checkout. A tag is a label a
  person can put on any commit, so it cannot testify to what that
  commit's code can do — an older build has no picker in it and landing
  there would strand you with no way back.
- Loading a version leaves you detached on purpose; the corner names the
  release rather than reporting branch `HEAD`.

## 1.12.0 — 2026-09-08

Promoted from `beta`. Cursor not included.

- **Options is an icon panel.** Keyboard, Keys and Border sit side by side
  — title, icon, current setting — over one sample chord drawn exactly as
  the board draws it, ruled off above and below. Keys and Border dim while
  the chips are words, since neither changes anything until they are icons.
- **One Size slider** covers chip text, glyphs and the padding around them,
  so a chord keeps its proportions at any setting.
- Fixed: toggling **Border** used to resize every glyph by 11% and change a
  chord's width, because the icon compensation and the padding both
  depended on the cap. A border changes the outline and nothing else now.
- Fixed: the options sample was drawn at a fixed size, so it only matched
  the board at one slider position; and its chord rendered identically at
  full, short and icons, so it showed nothing about the setting it sat
  under. It is `Super + Shift + Return` now, and there is a test that the
  sample distinguishes all three chip styles and all four keyboards.
- Fixed: **the overlay would not open at all** if a QML file set one
  property twice — a component that does is refused, and everything using
  it goes with it. Caught only by the running shell, since qmllint does not
  report it, so there is now a test that walks every QML file for it.
- Fixed: selecting a row could log `board is not defined` and drop the
  scroll-into-view, when a rebuild destroyed the delegate before the
  deferred call ran.
- **Untested is gone from the channel picker.** Most of those branches
  predate the picker, so switching to one left you running code that could
  not fetch or switch back out. A checkout on any other branch is still
  named in the corner, and any channel gets you out of it.
- **Hold Super can be turned off.** The last opener still enabled refuses
  to switch off, so Super+K, double-tap and hold cannot all be disabled.
- The close button reads `[ ✕ ]`, and the tree's Options block has a
  heading.

## 1.11.0 — 2026-09-08

Promoted from `beta` (`1e7ee0a`). Never released to `main` on its own;
folded into 1.12.0. Cursor not included.

- The corner reads **Version: Channel @ hash**, and the picker opens with
  what is loaded as three labelled lines — Updated, Branch, Hash — beside a
  cloud button whose label says whether clicking it will *check* or
  *update*.
- Every other channel says how it compares to what is loaded: *same*, or
  how many days *newer* or *older*. Sameness is by commit, not by clock.
- **The overlay says when it is running older code than the checkout.**
  Switching or syncing restarts the shell, but if that restart does not
  take effect the corner and the picker both say **restart to load** and
  name the commit actually running. Without it, a change that had arrived
  on disk looked exactly like one that never came.
- **Gestures sort by the key they are performed on**, so Double-tap and
  Hold sit with Super instead of filing under D and H.
- Fixed: every row in the **Active Apps** branch loads that app's keys.
  Only the app row did; the rows under it did nothing on a click.

## 1.10.0 — 2026-09-08

Promoted from `beta`. Written by Claude while Grok is offline. Cursor not
included.

- **Grouping, Sort, Order and Filter now sit under the tree**, each an
  icon showing its current mode and cycling on click, under an Options
  heading. The old corner link is **All Options** and opens the popup for
  everything else.
- **Filtering by key means the key you press.** It was a substring match
  over the whole chord, so on a 189-row keymap pressing `s` matched 166
  rows — Super, Shift, Space and Escape all contain one — while `3`
  matched none, because the workspace binds are written `1-9, 0`. A query
  now has to equal a whole key: `s` finds 4 rows, `3` finds the 5 range
  binds, and `[` finds `bracketleft` by its symbol.
- **Named keys filter too.** Delete, Home, the function keys and the rest
  never reached the filter, so the mode meant for looking up a key could
  not look up most of them. Return, Tab, Backspace and the arrows filter
  only while the box is empty, then go back to moving through results.
- **Click the filter box to capture a keystroke whole**, modifiers
  included, which is the only way to filter on Return or Escape. A
  captured chord matches as a chord: every key in it must be in the row.
- **All mode reads what you typed.** One character is a key; more than one
  searches keys, descriptions and topics.
- The **version picker** names the date each build was made and says
  whether every other channel is the same, or how many days newer or
  older. Sameness is by commit, not by clock.
- Fixed: every row in the **Active Apps** branch loads that app's keys.
  Only the app row did — the rows below it handled double-click to focus
  and nothing else, so clicking them did visibly nothing.

## 1.9.0 — 2026-09-08

Promoted from `beta` (`234ae31`). Never released to `main` on its own;
folded into 1.10.0. Cursor not included.

- **Keyboard type** picks which keyboard's keycaps the modifier chips
  imitate — text, mac (⌘ ⌃ ⇧ ⌥), windows or omarchy. Command, not Option,
  is Super: on a Mac keyboard under Linux it is Command that reports
  `KEY_LEFTMETA`, which the kernel's own `hid_apple` says in as many
  words.
- **Icon borders** draws a cap around each key. Only keys you press get
  one; a glyph standing for what a key *does*, or for a mouse button, is
  not a cap.
- **Grouping** by key type (Numbers, Alpha, Special, Non-keyboard) or off
  entirely, and a third **Sort** by the key you actually press, so
  `Super+Shift+K` files under K rather than under S.
- Ungrouped rows trail their topic in faint smaller text — once the
  headings are gone, the row is the only place it survives.
- Group headings carry the Omarchy mark, or the app's name in brackets
  when a sheet is loaded. The tree's Omarchy row carries the mark too.
- **Keys read as keys**: punctuation shows its symbol rather than
  `bracketleft`, media keys read "Volume up" rather than
  `XF86AudioRaiseVolume`, and nothing is truncated into something that is
  no longer a key name.
- The channel picker is Main / Beta / Nightly / **Untested** — the three
  channels are each one branch's tip, and Untested holds the rest.
- The **Options popup fits its content** and scrolls past that, instead
  of running its last rows off the bottom edge.
- The **Modifiers** section is now **Filters**, and a clear key means All
  and carries no mark.

## 1.8.0 — 2026-09-08

Promoted from `beta`. Written by Claude while Grok is offline. Cursor not
included.

- **Running a command now takes a double-click.** A single click only
  moves the highlight. Any click used to fire the shortcut and close the
  overlay, which is easy to do by accident while reading the board and
  cannot be undone once a bind has run. Enter is unchanged.
- **Super+K can be turned off**, under Options → Opening. Off hands the
  chord back to whatever held it before OmarKEYS (Omarchy binds
  **Keybindings**). It works by never claiming the key rather than by
  rebinding it, so a Super+K you remapped yourself comes back untouched.
  Applying it runs `hyprctl reload`, since the bind lives in
  `hyprland.lua` and that only re-reads its config when Hyprland does.
  Hold Super has no off switch, so this cannot lock you out.
- Documentation caught up with the code. The README had been describing
  an Edit mode that does not ship, the pre-1.6.0 sidebar, and a settings
  bar that 1.7.0 deleted; the manifest description claimed arrows and
  Ctrl+1–9 pick a window, which neither does.

## 1.7.0 — 2026-09-08

Promoted from `beta` (`a5a7d6d`). Never released to `main` on its own;
folded into 1.8.0. Cursor not included.

- Modifiers and the opening gestures moved out of the sidebar and the
  bottom bar into an **Options popup**, opened from the bottom-left
  corner. Close ✕, centred headings, and a **Restore defaults** that also
  clears hidden groups, hidden apps and the search box.
- Four display options: key chips **full / short / icons**, keys or the
  action leading the row, sort **by group or by name**, and search across
  **all / keys / name**.
- Icon chips are drawn from the overlay's own Nerd Font rather than
  emoji, which resolve to a fallback font with different metrics.
  Hovering a row names each glyph in words beside it.
- Left/right/middle mouse collapse to one chip; the wheel gets a mouse
  glyph with a direction arrow.
- Text-size and icon-size sliders, each reset by clicking its label.
- The overlay sizes itself to the display instead of a fixed default.
- Gesture rows name the key they apply to (Double-tap → Super).
- "No keymap sheet" is pinned to the bottom of the tree.
- Fixed: descriptions vanished when toggling Order; every key chip
  rendered blank; hovering a row widened the keys column and slid the
  chips out from under the cursor.

## 1.6.1 — 2026-09-07

Promoted from `beta` (`85f10d0`). Cursor not included.

- Each window of a multi-window app gets its own row, named by the
  program running in it: `Ghostty` expands to `claude` and a shell,
  rather than one row counted `(2)`. The program comes from the
  terminal's foreground process group; where a terminal multiplexes
  windows under one pid, attribution falls back to matching the shell's
  working directory against the window title and declines to guess when
  that is ambiguous.
- Double-click an app to focus its window.
- Chrome PWAs are named from the window title, so `Claude Code` and
  `Grok` instead of extension ids.

## 1.6.0 — 2026-09-07

Promoted from `beta`. Cursor not included.

- Active Apps groups by kind: apps sharing a keymap sheet sit together,
  so five Chrome PWAs are one **Web apps** branch rather than five
  entries repeating Chromium's shortcuts. Apps with no sheet are listed
  under **No keymap sheet**.
- Chrome PWAs are named from their window title, not their extension id
  (`Claude Code`, not `Chromium · fmpnliohjhemenmnlpbf`).
- Show/Hide replaces the toggle switches at every level of the tree.
  Plain text, revealed on row hover, and a hidden branch keeps its label
  and greys out, so hiding can always be undone.
- Every parent carries a caret: collapsed when everything under it is
  hidden, expanded while any of it still shows.
- Double-click an app to focus its window.
- Command rows give more width to the action, so fewer labels truncate.

## 1.5.1 — 2026-09-07

Promoted from `beta` (`9db25ad`). Cursor not included.

- Modifier filters are a 2×2 key-chip grid, ruled off from the tree;
  legend reads All / Must / Hide.
- Switching a channel fetches and fast-forwards it first, so Beta/Main
  do not silently load a stale local tip.
- `install.sh` installs a real directory (symlink folders fail
  `omarchy plugin update`); `--dev` keeps the symlink for local work.
- Lua binds round-trip table args; un-issuable rows are dimmed.
- Key-sending rows target the window that was focused before the overlay
  opened.

## 1.5.0 — 2026-09-07

Promoted from `beta` (`375da99`).

### Overlay

- Super+W closes OmarKEYS while it is open (temporarily remapped; does
  not close the window behind the layer). Esc, Super tap, and click-dim
  still dismiss.
- Keyboard grab after Super is released; overlay hides if the focused
  window changes.

### Keymap

- Enter or click runs the highlighted **Omarchy bind by dispatching its
  action**, not by replaying the chord (chord replay never reached
  Hyprland's matcher). App-sheet rows still send keys to the focused
  window.
- Ranges, gestures, and descriptive rows stay inert and dimmed.

### Sidebar

- Real tree: Omarchy buckets into five areas (Launch & navigate,
  Windows & workspaces, Clipboard & capture, System & media, Apps).
- **Active Apps** is Omarchy's sibling; click a window to load its
  sheet. Named empty state when an app has no sheet; "No windows
  detected" when none are open.
- Click an area or group to solo it on the board (view-only; hide
  settings are restored when the overlay closes).

### Channels

- Corner picker is Main / Beta / Nightly. Claude owns beta; Grok
  promotes beta to main.

### Not in this release

- Phase 3 View | Edit UI
- Cursor working-copy / Cloud Agent changes (`develop-cursor`)
