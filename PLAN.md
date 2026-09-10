# OmarKEYS plan

Living plan for the overlay. Done items stay here so we do not lose
the thread after a cleanup or GitHub push.

User comments on approval (plan.md:116):

- Why the limit on writing `bindings.lua`? If that is the worry, take a
  backup we can revert and keep a library of changes.
- Version-control each working version.

Those comments are implemented in `apply-edit`: snapshots, git history
under `~/.local/state/omarchy/omarkeys-history`, rollback on a failed
reload. Edits still land in `~/.config/hypr/omarkeys-edits.lua` rather
than rewriting the body of `bindings.lua`.

User comments (layer vs app / Super+W):

- Super+W closed the last focused window, not OmarKEYS.
- Should this be an app (so Super+W closes it) or a layer plugin?

Dealt with: OmarKEYS stays an overlay **layer plugin** (same family as
the menu and clipboard). Super+W is "close window"; a layer is not a
window, so that bind would kill the app behind the overlay. While the
layer is up, Super+W is **temporarily remapped** to close OmarKEYS.
The original "Close window" bind is restored when the overlay hides.

User comment (auto-select focused window):

- Should opening the "Open windows" branch auto-load the currently
  focused window's sheet instead of requiring a click?

Dealt with: kept v1's click-to-open. Auto-loading on open (or on every
focus change) would silently swap the sheet under you while Omarchy
stays the deliberate default landing view; a click stays the
intentional "jump to this app" action. Not building this.

## Done

### Overlay (Super+K replacement)

- [x] Topic-organized overlay plugin (`io.github.romills.omarkeys`)
- [x] Open: Super+K, double-tap Super, hold Super (default 5s)
- [x] Close: tap Super, Esc, Super+W, click dim
- [x] Keyboard grab after Super-up; dismiss if the focused window changes
- [x] Super+W temp-mapped to the layer while open (does not close the window behind it)
- [x] Live Hyprland binds on open (`dump-keymap`)
- [x] Type to search (digits included; Ctrl+1–9 jumps groups)
- [x] Arrows to move, Enter or double-click to run the highlighted chord
      (single click only highlights; see the 1.7.0 notes below)
- [x] Sidebar groups with show/hide and All/None
- [x] Modifier filter Any / Must / Hide; A/M/H sets all four
- [x] Double-tap toggle and hold slider
- [x] Settings in `~/.config/omarchy/omarkeys.json`
- [x] Code split: host, sidebar, board, row, settings bar
- [x] Public repo: https://github.com/romills/OmarKEYs
- [x] Grok repo: https://github.com/romills/OmarKEYs-grok (`~/Work/omarkeys-grok`). Grok owns `main`, pulls finished `beta` (Claude) into it, and writes `RELEASE.md`.
- [x] Ship `apply-edit` and `sheets/` (were gitignored; GitHub clones missed them)

### Phase 1 — Auto-reload

- [x] Refresh dump when the overlay opens
- [x] Watch `~/.config/hypr/bindings.lua` and refresh while open
- [x] Hash the dump so idle refreshes do not reset selection/search
- [x] Keep selection when the row still exists after a refresh

### Phase 2 — Data for the app tree

- [x] `dump-keymap` returns `clients` (class, label, focused, sheet)
- [x] Starter sheets: Chromium, Ghostty, Nautilus
- [x] `selectSource()` loads Omarchy dump or a sheet / empty state

### Phase 3 — Edit backend

- [x] `apply-edit remap` writes `omarkeys-edits.lua`
- [x] Backup + git history per working version; restore on reload error
- [x] Lua-escape bind strings; refuse chords that are not Hyprland-like
- [x] Capture/remap functions in `Keymap.qml` (`setEditMode`, `startCapture`)

### Phase 2 — Sidebar tree UI

- [x] Omarchy as the default expanded branch, with current groups under it
- [x] Active Apps branch from live clients; click loads that app’s sheet
- [x] Focused window marked in the tree
- [x] Groups / modifiers still apply to the active branch
- [x] Empty-state copy names the app when a window has no bundled sheet
- [x] Empty-state row ("No windows detected") when no clients are open
- [x] Auto-select the focused window — decided against, see note above

User comment (tree structure):

- The sidebar wasn't really reading as a tree — groups sat flat under
  Omarchy with no visual hierarchy, and Active Apps needed to clearly
  read as Omarchy's sibling branch rather than an afterthought below it.

Dealt with: Omarchy's ~14 topic groups are now bucketed into 5 areas
(`KeymapData.groupedCatalog`, kept in sync with `dump-keymap`'s
`SECTION_RULES`) — Launch & navigate, Windows & workspaces, Clipboard &
capture, System & media, Apps — each with its own bulk show/hide toggle
alongside the per-group ones. Sidebar rows now draw a trunk guide line
per branch (Omarchy's areas/groups, and Active Apps' clients) so the
nesting reads visually, not just by indent depth. Renamed "Open
windows" to "Active Apps" to match how it's talked about.

User comment (click to filter / click to run):

- Clicking a branch in the tree should hide the tables in the other
  branches.
- Clicking a command should run it and close the overlay.

Dealt with: clicking an area or a group now *solos* it — every other
Omarchy group is hidden so the board shows only what you clicked
(`soloGroups()`). Clicking the **Omarchy** root restores all of them,
so it doubles as the reset. Solo is **view-only**: it snapshots
`hiddenGroups` and restores them when the overlay closes (a stray click
had been writing 14/15 groups hidden into the live config). Deliberate
toggles still persist and end the solo. Active Apps was already
exclusive: picking a window swaps the whole board to that app's sheet.

### Run a command (dispatch, not chord replay)

- [x] Double-click or Enter runs the highlighted Omarchy bind and closes
      the overlay; a single click only highlights
- [x] `dump-keymap` recovers each bind's real dispatcher+arg (stubbed Lua
      `bind()`, because `hyprctl binds` reports every Lua bind as `__lua`)
- [x] `run-shortcut --dispatch <kind> <arg>` runs that action (`exec`,
      `lua`, `sendshortcut`, other dispatchers)
- [x] App sheet rows still replay the chord into the focused window
- [x] Ranges, gestures, and descriptive rows stay inert and dimmed

Chord replay of a Hyprland bind was a no-op: keys sent to the active
window never reach Hyprland's bind matcher, so the app swallowed them
and `run-shortcut` still exited 0. Omarchy's own keybindings menu
dispatches the action; OmarKEYS now matches that. Verified: Volume up
moved the sink; the old path returned ok and changed nothing.

### Release channels in the picker

- [x] Corner picker offers Main / Beta / Nightly instead of raw branches
- [x] `beta` branch created; Claude owns beta; promotion is `develop-claude` → `develop` → `beta` (Claude) → `main` (Grok)
- [x] Grok updates `RELEASE.md` when promoting a finished beta
- [x] 1.5.1 from beta `9db25ad`: modifier chips, channel switch syncs,
      real-directory install, dispatcher table args, pre-overlay window
      for key-sends
- [x] Nightly is a disclosure holding every working branch, so nobody
      lands on one by accident
- [x] `plugin-git switch` fetches when a branch is unseen, so a newly
      created channel is selectable without a manual fetch first

### Branch picker / update check

- [x] `plugin-git` reports branch, hash, dirty, upstream, ahead/behind
- [x] Corner label is a dropdown: pick a branch, see when one is behind
- [x] Sync button fast-forwards to the remote and restarts the shell
- [x] Refuses rather than discards: no switch/sync with a dirty tree, no
      force, no `reset --hard`, `merge --ff-only` so divergence reports
- [x] Branches held by another worktree are left out (git would refuse)

### Working copies

- [x] `~/Work/omarkeys` is the deploy slot. No edits.
- [x] Per-agent clones: `omarkeys-grok`, `omarkeys-claude`. No separate
      Cursor clone was made; Cursor lands via `develop-cursor` on the remote.
- [x] Grok pulls `shared/beta` into this `main` (not `develop`, not Cursor)

### Live reload (was "Later")

- [x] A 3s timer while open so `hyprctl binds` picks up Lua reloads we did not write
- [x] Watch `omarkeys-edits.lua` the same way as `bindings.lua`

### Display options (1.7.0)

User comment: the chords were hard to read while navigating — too much
text per row, and no way to scan by what a command *does*.

- [x] Four display options: key chips full / short / icons, keys or action
      leading the row, sort by group or by name, search all / keys / name
- [x] Icon chips drawn from the overlay's own Nerd Font, not emoji (emoji
      resolve to a fallback font with different metrics)
- [x] Hovering a row names each glyph in words beside it, dimmed. The keys
      column is a constant width so hovering never moves the chips
- [x] Left/right/middle mouse collapse to one chip; the wheel gets a mouse
      glyph plus a direction arrow
- [x] Text-size and icon-size sliders, each reset by clicking its label
- [x] Overlay sizes itself to the display instead of a fixed default
- [x] Modifiers and gestures moved out of the sidebar and the bottom bar
      into an Options popup, opened from the bottom-left corner
      (`KeymapSettingsBar.qml` deleted, `KeymapOptionsMenu.qml` added)
- [x] Restore defaults resets display, modifiers, gestures, hidden groups
      and apps, and the search box
- [x] Gesture rows name the key they apply to (Double-tap → Super)
- [x] "No keymap sheet" pinned to the bottom of the tree
- [x] Docs catch-up: README rewritten for the tree and Options popup;
      the channels table covers the full ladder
- [x] Running a command takes a double-click. A single click only moves
      the highlight, so a click while reading the board cannot fire a
      shortcut and close the overlay. Enter is unchanged.
- [x] Super+K on/off under Options → Opening. Off means `hyprland.lua`
      never unbinds the chord, so the original survives without OmarKEYS
      having to know what it was; the overlay applies it with
      `hyprctl reload`. Hold Super has no off switch, so no lockout.

## Future

### Finish Phase 3 — View | Edit UI

- [ ] Header toggle View | Edit (Omarchy branch only)
- [ ] Dim non-editable rows; “press a new chord or Esc”
- [ ] Enter stays View-only
- [ ] Surface `apply-edit revert` / history in the overlay
- [ ] `install.sh` wires `omarkeys-edits.lua` on first install (first edit already appends the dofile)

### 1.x — four-part versions, and tags that mean something

The version in `manifest.json` is decorative today: nothing reads it, and
the overlay identifies a build by channel, hash and commit date. There are
no tags at all. So a release has no name, and "Nightly @ dfe7468" cannot
tell you how far past a release it is.

Scheme is `1.<main>.<beta>.<dev>`: a main release bumps the second part
and resets the rest, a beta cut bumps the third and resets the fourth, and
a landing on `develop` bumps the fourth. Today's 1.12.0 becomes 1.12.0.0.

- [ ] Bump the fourth part when `develop-claude` lands on `develop`, the
      third at a beta cut, the second at a main release. Checked: the
      Omarchy validator accepts four-part versions (and prerelease
      strings), so nothing external constrains this.
- [ ] Bump on `develop`, never on `develop-claude`. `develop` has one
      writer; a version line edited on every working branch is a conflict
      in every merge, and `develop-cursor` would hit it too.
- [ ] Annotated tag `v1.M.B.D` at each beta cut and each main release.
      Not on dev bumps: that is tens of tags a day, and `git describe`
      already renders a dev build as `v1.12.1.0-7-gdfe7468`, which says
      exactly what a Nightly is — seven commits past the last beta.
- [ ] `plugin-git` reports `git describe --tags` alongside the hash, and
      the picker shows the version rather than a bare hash. The date and
      the newer/older comparison stay: a tag says which release, a date
      says how stale.
- [ ] Tag retroactively from RELEASE.md, so the history has names before
      the scheme starts rather than beginning at 1.13.0.0 with nothing
      behind it.

### 2.0 — editable keymaps, versioned, with the defaults kept

Being built by Grok on its own branch, in its own checkout
(`~/Work/omarkeys-grok`). 1.0 keeps shipping to beta and main meanwhile;
nothing of 2.0 reaches a channel until it is ready. The picker already has
a Track row for it, filtered on what branches and tags carry, so 2.0
appears there on its own the moment it is tagged or promoted.

The backend is already built and unreachable: `apply-edit` remaps a chord
into `omarkeys-edits.lua`, snapshots before every write into a git repo
under `~/.local/state/omarchy/omarkeys-history`, and restores the previous
state when a reload fails. `Keymap.qml` has `setEditMode` and
`startCapture` that nothing calls. 2.0 is mostly surfacing that safely.

- [ ] View | Edit toggle on the Omarchy branch: pick a row, press the new
      chord, confirm. The capture primitive exists -- the filter's armed
      capture takes a whole keystroke including modifiers, Return and
      Escape, which is exactly what "press a new chord" needs.
- [ ] Refuse a chord already bound, and say what holds it. The live dump
      knows every bind, so this is a lookup rather than a guess.
- [ ] **Two baselines, not one.** "Omarchy defaults" and "what your config
      looked like before OmarKEYS touched it" are different things the
      moment someone has customised `bindings.lua`, and conflating them
      makes Restore either lose their work or fail to restore anything.
      Capture the shipped defaults from `/usr/share/omarchy/default/hypr/`
      and the user's own pre-edit dump separately, at install.
- [ ] Named keymap versions: a version is a set of overrides, one commit
      in the history repo, switchable. Switching writes that version's
      `omarkeys-edits.lua` and reloads; a failed reload rolls back, which
      `apply-edit` already does.
- [ ] Diff a version against either baseline, and against the live config.
- [ ] Export and import a version, so a keymap can move between machines.

Boundaries worth keeping from the current design: edits stay additive in
`omarkeys-edits.lua` rather than rewriting the body of `bindings.lua`;
chord remaps only, never dispatcher or argument edits; and Super+K, hold
and double-tap stay out of the chord editor, since breaking those is how
you lose the way back in.

### Later (out of the original three phases)

- [ ] More app sheets beyond Chromium / Ghostty / Nautilus
- [ ] Do not scrape another program’s keymap from memory
- [ ] Do not edit dispatcher/args — chord remap of an existing action only
- [ ] Do not change Super+K / hold / double-tap from the chord editor
- [ ] GitHub release tag
