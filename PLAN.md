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
- [x] Arrows, Enter or click to run the highlighted chord
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
- [x] Capture/remap functions in `Keymap.qml` (per-row record popup)

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

- [x] Click or Enter runs the highlighted Omarchy bind and closes the overlay
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
- [x] `beta` branch created; Claude owns beta; promotion is `develop` → `beta` (Claude) → `main` (Grok)
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
- [x] Per-agent clones: `omarkeys-grok`, `omarkeys-claude`, `omarkeys-cursor`
- [x] Grok pulls `shared/beta` into this `main` (not `develop`, not Cursor)

### Live reload (was "Later")

- [x] A 3s timer while open so `hyprctl binds` picks up Lua reloads we did not write
- [x] Watch `omarkeys-edits.lua` the same way as `bindings.lua`

### (cursor) Beta code cleanup

Reviewed current `beta` (1.6.1) and landed the low-risk cleanups on
`develop-cursor`. Left the invasive splits as follow-ups so we do not
rewrite the overlay chrome in the same pass.

- [x] (cursor) One `rowRunnable()` for board dimming and Enter
- [x] (cursor) Sparse numbered binds keep dump dispatcher/arg
- [x] (cursor) Shared board section delegate; click-to-run only (no dual click/dblclick API)
- [x] (cursor) Enter stays View-only until the Phase 3 header exists
- [x] (cursor) Drop dead `toggleApp` / `allGroupsVisible` / unused KeymapData accessors
- [x] (cursor) Shared `resetSession()` for close/dismiss; named overlay timings
- [x] (cursor) Cache `hyprland.lua` config for a Super-down gesture
- [x] (cursor) Exact window-address match in `run-shortcut`
- [x] (cursor) Skip the live dump test without Omarchy; add dump-keymap unit tests
- [ ] (cursor) Extract sidebar tree chrome into delegates
- [ ] (cursor) Split Keymap.qml host (config / actions / chrome)
- [ ] (cursor) One shared section-taxonomy source for dump-keymap + KeymapData

## Future

### Finish Phase 3 — Record / restore chords

- [x] (cursor) Record icon next to each editable Omarchy key (no header View|Edit)
- [x] (cursor) Record popup: listen, then Save; Enter still runs the row
- [x] (cursor) Conflict if the captured chord is already in use; Save stays off until Swap or Move the other
- [x] (cursor) Factory chord remembered in `omarkeys-chords.json`; never overwritten by later dumps
- [x] (cursor) Restore default unwinds that remap and any displaced chain
- [x] (cursor) `install.sh` wires `omarkeys-edits.lua` on first install

Chord remap writes `~/.config/hypr/omarkeys-edits.lua` using Omarchy's
own override style (`hl.unbind` then `hl.bind` with the recovered
dispatcher). Factory keys and the remap log live in
`~/.config/omarchy/omarkeys-chords.json`. That is allowed for an
unsandboxed overlay plugin: it edits the user's Hyprland config, not
the plugin git origin and not Omarchy's default bind modules. Super+K /
hold / double-tap cannot be remapped. Dispatcher/args are not edited —
only the chord.

### Later (out of the original three phases)

- [ ] More app sheets beyond Chromium / Ghostty / Nautilus
- [ ] Do not scrape another program’s keymap from memory
- [ ] Do not edit dispatcher/args — chord remap of an existing action only
- [ ] Do not change Super+K / hold / double-tap from the chord editor
- [ ] GitHub release tag
- [ ] Manifest description catch-up
