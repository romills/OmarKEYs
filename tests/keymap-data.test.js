const { test } = require("node:test")
const assert = require("node:assert/strict")
const fs = require("node:fs")
const path = require("node:path")
const vm = require("node:vm")

const src = fs.readFileSync(path.join(__dirname, "..", "KeymapData.js"), "utf8")
  .replace(/^\.pragma library\s*/, "")
const context = {}
vm.createContext(context)
vm.runInContext(src + "\nthis.filtered = filtered; this.columns = columns; this.splitKeys = splitKeys; this.sections = sections; this.isRunnable = isRunnable; this.shortcut = shortcut; this.navList = navList; this.sectionStarts = sectionStarts; this.setConfig = setConfig; this.setSections = setSections; this.catalog = catalog; this.catalogFor = catalogFor; this.groupedCatalog = groupedCatalog; this.displayKeys = displayKeys; this.shortKey = shortKey; this.displayNames = displayNames; this.rowMatchesModifiers = rowMatchesModifiers; this.normalizeModifierMode = normalizeModifierMode; this.rowRunnable = rowRunnable; this.rowEditable = rowEditable; this.isProtectedChord = isProtectedChord; this.normalizeChord = normalizeChord; this.findOccupant = findOccupant; this.relatedActions = relatedActions; this.restorePlan = restorePlan; this.setChordIndex = setChordIndex; this.rowRemapped = rowRemapped; this.defaultKeysFor = defaultKeysFor;", context)

function hasLiveDump() {
  const { execFileSync } = require("node:child_process")
  try {
    execFileSync("which", ["omarchy-menu-keybindings"], { stdio: "ignore" })
    return true
  } catch {
    return false
  }
}

test("splitKeys splits Super chords", () => {
  assert.equal(JSON.stringify(context.splitKeys("Super + K")), JSON.stringify(["Super", "K"]))
  assert.equal(JSON.stringify(context.splitKeys("Print")), JSON.stringify(["Print"]))
})

test("filtered matches keys, actions, and titles", () => {
  const byKeys = context.filtered("super + k")
  assert.ok(byKeys.some((s) => s.rows.some((r) => r.action === "OmarKEYS")))
  const byTitle = context.filtered("workspaces")
  assert.equal(byTitle[0].title, "Workspaces")
})

test("columns splits sections left/right", () => {
  const cols = context.columns("")
  assert.ok(cols.left.length >= 1)
  assert.ok(cols.right.length >= 1)
  assert.equal(cols.left.length + cols.right.length, context.sections.length)
  assert.equal(cols.left[0].sectionIndex, 0)
  assert.equal(cols.right[0].sectionIndex, 1)
  assert.equal(cols.left[0].title, "Main")
})

test("runnable shortcuts parse for Enter-to-run", () => {
  assert.equal(context.isRunnable("Super + Return"), true)
  assert.equal(context.isRunnable("Super + 1-9, 0"), false)
  const sc = context.shortcut("Super + Shift + Return")
  assert.equal(sc.mods, "SUPER SHIFT")
  assert.equal(sc.key, "Return")
})

test("navList and sectionStarts cover filtered rows", () => {
  const items = context.navList("")
  assert.ok(items.length > 10)
  const starts = context.sectionStarts(items)
  assert.equal(starts[0], 0)
  assert.ok(starts.length === context.filtered("").length)
  assert.ok(starts.length >= 10)
  assert.equal(items[starts[0]].sectionTitle, "Main")
  assert.equal(items[starts[1]].sectionTitle, "Menus and launchers")
})

test("digit blocks map onto the first ten sections", () => {
  const items = context.navList("")
  const starts = context.sectionStarts(items)
  const titles = starts.map((i) => items[i].sectionTitle)
  assert.equal(titles[0], "Main")
  assert.equal(titles[9], "Notifications")
  assert.ok(items[0].runnable)
  assert.equal(items[0].shortcut.key, "space")
})

test("config hold time and double-tap appear on Main", () => {
  context.setConfig({ doubleTap: true, holdSeconds: 5 })
  const on = context.navList("")
  assert.ok(on.some((row) => row.keys === "Hold Super 5s"))
  assert.ok(on.some((row) => row.keys === "Double-tap Super"))
  context.setConfig({ doubleTap: false, holdSeconds: 8 })
  const off = context.navList("")
  assert.ok(off.some((row) => row.keys === "Hold Super 8s"))
  assert.ok(!off.some((row) => row.keys === "Double-tap Super"))
  context.setConfig({ doubleTap: true, holdSeconds: 5 })
})

test("dump-keymap reads live Hyprland bindings", { skip: !hasLiveDump() ? "needs omarchy-menu-keybindings" : false }, () => {
  const { execFileSync } = require("node:child_process")
  const raw = execFileSync("python3", [path.join(__dirname, "..", "dump-keymap")], { encoding: "utf8" })
  const data = JSON.parse(raw)
  assert.ok(Array.isArray(data.sections))
  const start = data.sections.find((s) => s.title === "Main")
  assert.ok(start)
  assert.ok(start.rows.some((r) => /omarchy menu/i.test(r.action)))
  assert.ok(start.rows.some((r) => r.keys.includes("Super")))
  const menu = start.rows.find((r) => /omarchy menu/i.test(r.action))
  assert.ok(menu)
  assert.ok(menu.bindKey)
  assert.ok(Array.isArray(data.clients))
})

test("hidden groups stay in the catalog but leave the grid", () => {
  context.setConfig({ doubleTap: true, holdSeconds: 5, hiddenGroups: ["Windows"] })
  const names = context.catalog().map((g) => g.title)
  assert.ok(names.includes("Windows"))
  assert.ok(context.catalog().some((g) => g.title === "Windows" && g.hidden))
  assert.ok(!context.filtered("").some((s) => s.title === "Windows"))
  context.setConfig({ doubleTap: true, holdSeconds: 5, hiddenGroups: [] })
})

test("modifier any/must/hide filters chords", () => {
  assert.equal(context.normalizeModifierMode(false), "hide")
  assert.equal(context.normalizeModifierMode(true), "any")
  context.setConfig({
    doubleTap: true,
    holdSeconds: 5,
    hiddenGroups: [],
    modifiers: { Super: "hide", Shift: "any", Ctrl: "any", Alt: "any" }
  })
  const hiddenSuper = context.navList("")
  assert.ok(!hiddenSuper.some((r) => /super/i.test(r.keys)))
  assert.ok(hiddenSuper.some((r) => /print|tab|delete/i.test(r.keys)))
  context.setConfig({
    doubleTap: true,
    holdSeconds: 5,
    hiddenGroups: [],
    modifiers: { Super: "must", Shift: "any", Ctrl: "any", Alt: "any" }
  })
  const mustSuper = context.navList("")
  assert.ok(mustSuper.length > 0)
  assert.ok(mustSuper.every((r) => /super/i.test(r.keys)))
  context.setConfig({
    doubleTap: true,
    holdSeconds: 5,
    hiddenGroups: [],
    modifiers: { Super: "must", Shift: "hide", Ctrl: "any", Alt: "any" }
  })
  const mustSuperHideShift = context.navList("")
  assert.ok(mustSuperHideShift.some((r) => r.keys === "Super + Space"))
  assert.ok(!mustSuperHideShift.some((r) => /\bshift\b/i.test(r.keys)))
  context.setConfig({ doubleTap: true, holdSeconds: 5, hiddenGroups: [] })
})

test("hiding every group empties the grid", () => {
  const titles = context.catalog().map((g) => g.title)
  context.setConfig({ doubleTap: true, holdSeconds: 5, hiddenGroups: titles })
  assert.equal(context.filtered("").length, 0)
  assert.equal(context.catalog().length, titles.length)
  context.setConfig({ doubleTap: true, holdSeconds: 5, hiddenGroups: [] })
})

test("navList carries a bind's own dispatcher so rows dispatch, not replay keys", () => {
  // Regression: rows used to expose only mods/key, so the overlay replayed
  // the chord as a synthetic key. Hyprland's bind matcher never sees those,
  // so every Omarchy binding silently did nothing.
  context.setSections([{
    title: "Main",
    rows: [
      { keys: "Super + Return", action: "Terminal", mods: "SUPER", bindKey: "RETURN",
        dispatcher: "exec", arg: "omarchy-launch-terminal" },
      { keys: "Ctrl + T", action: "New tab" }
    ]
  }])
  const items = context.navList("")
  const terminal = items.find((i) => i.action === "Terminal")
  assert.equal(terminal.dispatcher, "exec")
  assert.equal(terminal.dispatchArg, "omarchy-launch-terminal")
  assert.equal(terminal.runnable, true)
  // App sheet rows have no dispatcher and still fall back to key replay,
  // which is correct for an app's own shortcut.
  const tab = items.find((i) => i.action === "New tab")
  assert.equal(tab.dispatcher, "")
  assert.ok(tab.shortcut && tab.shortcut.key)
  context.setSections(null)
})

test("a bind the overlay cannot issue stays non-runnable however runnable its chord looks", () => {
  // Context-sensitive binds (universal copy, zoom) are Lua closures, so
  // there is no action to dispatch; OmarKEYS' own bind is self-referential.
  // dump-keymap marks those runnable:false and that must win, otherwise the
  // row looks live, closes the overlay, and does nothing.
  context.setSections([{
    title: "Main",
    rows: [
      { keys: "Super + C", action: "Universal copy", runnable: false },
      { keys: "Super + Return", action: "Terminal", dispatcher: "exec", arg: "term" }
    ]
  }])
  const items = context.navList("")
  assert.equal(items.find((i) => i.action === "Universal copy").runnable, false)
  assert.equal(items.find((i) => i.action === "Terminal").runnable, true)
  context.setSections(null)
})

test("groupedCatalog buckets every section into exactly 5 areas, none dropped", () => {
  const areas = context.groupedCatalog(context.sections)
  assert.equal(areas.length, 5)
  const flatTitles = context.catalogFor(context.sections).map((g) => g.title).sort()
  const groupedTitles = areas.flatMap((a) => a.groups.map((g) => g.title)).sort()
  assert.deepEqual(groupedTitles, flatTitles)
})

test("groupedCatalog carries hidden flags through to nested groups", () => {
  context.setConfig({ doubleTap: true, holdSeconds: 5, hiddenGroups: ["Workspaces"] })
  const areas = context.groupedCatalog(context.sections)
  const workspaces = areas.flatMap((a) => a.groups).find((g) => g.title === "Workspaces")
  assert.equal(workspaces.hidden, true)
  context.setConfig({ doubleTap: true, holdSeconds: 5, hiddenGroups: [] })
})

test("groupedCatalog still buckets everything when a section list omits Other", () => {
  const withoutOther = context.sections.filter((s) => s.title !== "Other")
  const areas = context.groupedCatalog(withoutOther)
  const groupedTitles = areas.flatMap((a) => a.groups.map((g) => g.title)).sort()
  assert.deepEqual(groupedTitles, context.catalogFor(withoutOther).map((g) => g.title).sort())
})

test("display options: short chips, action sort, and the two search modes", () => {
  // Option 1: chips shorten to <=5 chars so the action column keeps its width.
  context.setConfig({ chipStyle: "short" })
  // JSON.stringify, not deepEqual: values cross the vm realm boundary, so
  // their prototypes differ even when the contents match.
  assert.equal(JSON.stringify(context.displayKeys("Super + Shift + Backspace", "short")),
    JSON.stringify(["Sup", "Shft", "Bksp"]))
  assert.equal(context.shortKey("XF86AudioRaiseVolume"), "Raise")
  assert.ok(context.displayKeys("Super + Shift + Backspace", "short").every((k) => k.length <= 5))
  // Full style is untouched.
  assert.equal(JSON.stringify(context.displayKeys("Super + Return", "full")),
    JSON.stringify(["Super", "Return"]))

  // Sorting by description orders rows within their section.
  context.setConfig({ sortBy: "action" })
  const actions = context.filtered("")[0].rows.map((r) => r.action)
  assert.equal(JSON.stringify(actions),
    JSON.stringify(actions.slice().sort((a, b) => a.toLowerCase() < b.toLowerCase() ? -1 : 1)))

  // The two search modes are genuinely different: "super" is a modifier,
  // never a description, so searching descriptions must not match it.
  context.setConfig({ searchMode: "keys" })
  assert.ok(context.filtered("super").length > 0)
  context.setConfig({ searchMode: "action" })
  assert.equal(context.filtered("super").length, 0)
  context.setConfig({ searchMode: "action" })
  assert.ok(context.filtered("terminal").length > 0)

  context.setConfig({})
})

test("icon chips use in-font glyphs and fall back to text when unmapped", () => {
  // Nerd Font glyphs, not emoji: they live in the overlay's own font, so
  // they need no fallback family with different metrics.
  const vol = context.displayKeys("XF86AudioRaiseVolume", "icons")
  assert.equal(vol.length, 1)
  assert.ok(vol[0].codePointAt(0) >= 0xF0000, "expected a Nerd Font glyph")
  // A mouse button keeps its side, which a bare mouse glyph would lose.
  assert.ok(context.displayKeys("Super + Left + Mouse + Button", "icons")[1].endsWith("L"))
  // Named keys are glyphs too, so a row does not mix icons with text arrows.
  const named = context.displayKeys("Super + Shift + Return", "icons")
  assert.ok(named[2].codePointAt(0) >= 0xF0000, "Return should be a glyph")
  assert.ok(context.displayKeys("Super + Left", "icons")[1].codePointAt(0) >= 0xF0000,
    "arrow keys should be glyphs, not text arrows")
  // A letter has no icon and keeps its short text rather than going blank.
  assert.equal(JSON.stringify(context.displayKeys("Super + Shift + B", "icons")),
    JSON.stringify(["Sup", "Shft", "B"]))
})

test("a mouse bind is one chip, and only real arrow keys become arrows", () => {
  // Hyprland reports "Super + Left + Mouse + Button" as four words; left as
  // four chips the button reads as an arrow key, and short mode abbreviated
  // that "Left" to an arrow outright.
  assert.equal(JSON.stringify(context.displayKeys("Super + Left + Mouse + Button", "full")),
    JSON.stringify(["Super", "LMB"]))
  assert.equal(JSON.stringify(context.displayKeys("Super + Right + Mouse + Button", "short")),
    JSON.stringify(["Sup", "RMB"]))
  assert.equal(JSON.stringify(context.displayKeys("Super + mouse_down", "full")),
    JSON.stringify(["Super", "Wheel↓"]))
  // The arrow key itself still shortens to an arrow, which is the point.
  assert.equal(JSON.stringify(context.displayKeys("Super + Left", "short")),
    JSON.stringify(["Sup", "←"]))
})

test("hovering an icon names it in words, not in raw key tokens", () => {
  // The point of the hover is to say what a glyph is; "XF86AudioRaiseVolume"
  // would be barely better than the glyph itself.
  assert.equal(JSON.stringify(context.displayNames("XF86AudioRaiseVolume")),
    JSON.stringify(["Volume up"]))
  assert.equal(JSON.stringify(context.displayNames("Super + mouse_down")),
    JSON.stringify(["Super", "Wheel down"]))
  assert.equal(JSON.stringify(context.displayNames("Super + Left + Mouse + Button")),
    JSON.stringify(["Super", "Left click"]))
  // Names line up with chips index for index, which is what the row relies on.
  const keys = "Super + Shift + XF86MonBrightnessUp"
  assert.equal(context.displayNames(keys).length, context.displayKeys(keys, "icons").length)
})

test("a gesture shows the key it applies to, at every chip style", () => {
  // "Double-tap Super" is one token, so abbreviating it cut the key off and
  // left "Doubl" - a gesture with nothing to perform it on.
  assert.equal(JSON.stringify(context.displayKeys("Double-tap Super", "full")),
    JSON.stringify(["Double-tap", "Super"]))
  assert.equal(JSON.stringify(context.displayKeys("Double-tap Super", "short")),
    JSON.stringify(["Double-tap", "Sup"]))
  // The hold time stays with the gesture, and follows the configured value.
  assert.equal(JSON.stringify(context.displayKeys("Hold Super 8s", "icons")),
    JSON.stringify(["Hold 8s", "Sup"]))
  // Gestures are still not dispatchable; splitting them is display only.
  assert.equal(context.isRunnable("Double-tap Super"), false)
  assert.equal(context.isRunnable("Hold Super 5s"), false)
})

test("rowRunnable matches the board and Enter", () => {
  assert.equal(context.rowRunnable({ keys: "Super + K" }), true)
  assert.equal(context.rowRunnable({ keys: "Super + 1-9, 0" }), false)
  assert.equal(context.rowRunnable({ keys: "Super + K", runnable: false }), false)
  assert.equal(context.rowRunnable({
    keys: "Super + K", runnable: false, dispatcher: "exec"
  }), false)
  assert.equal(context.rowRunnable({
    keys: "not a chord", dispatcher: "workspace", arg: "1"
  }), true)
})

test("rowEditable is chord remap of a recovered action, never OmarKEYS summons", () => {
  assert.equal(context.isProtectedChord("Super + K"), true)
  assert.equal(context.isProtectedChord("SUPER + K"), true)
  assert.equal(context.isProtectedChord("Hold Super 5s"), true)
  assert.equal(context.rowEditable({
    keys: "Super + Return", dispatcher: "exec", arg: "ghostty"
  }), true)
  assert.equal(context.rowEditable({
    keys: "Super + K", dispatcher: "lua", arg: "hl.dsp.exec_cmd(\"x\")"
  }), false)
  assert.equal(context.rowEditable({ keys: "Super + Return" }), false)
  assert.equal(context.rowEditable({
    keys: "Super + 1-9, 0", dispatcher: "lua", arg: "hl.dsp.workspace(1)"
  }), false)
})

test("normalizeChord treats Super + Return and SUPER + RETURN as the same", () => {
  assert.equal(context.normalizeChord("Super + Return"), "SUPER + RETURN")
  assert.equal(context.normalizeChord("SUPER + RETURN"), "SUPER + RETURN")
  assert.equal(context.normalizeChord("Shift + Super + T"), "SUPER + SHIFT + T")
  assert.equal(context.normalizeChord("Ctrl + Alt + Super + Q"), "SUPER + CTRL + ALT + Q")
})

test("findOccupant reports a live conflict and ignores the row being edited", () => {
  const sections = [{
    title: "Main",
    rows: [
      { keys: "Super + Return", action: "Terminal", dispatcher: "exec", arg: "ghostty" },
      { keys: "Super + T", action: "New terminal tab", dispatcher: "exec", arg: "ghostty -e" },
    ]
  }]
  const hit = context.findOccupant("SUPER + T", "Terminal", sections, [])
  assert.equal(hit.action, "New terminal tab")
  assert.equal(context.findOccupant("SUPER + T", "New terminal tab", sections, []), null)
  const afterMove = context.findOccupant("SUPER + T", "Terminal", sections, [{
    action: "New terminal tab",
    new_keys: "SUPER + N",
    dispatcher: "exec",
    arg: "ghostty -e"
  }])
  assert.equal(afterMove, null)
})

test("restorePlan unwinds a swap and a displaced chain back to factory keys", () => {
  const defaults = {
    Terminal: { keys: "Super + Return", dispatcher: "exec", arg: "ghostty" },
    Browser: { keys: "Super + Shift + Return", dispatcher: "exec", arg: "chromium" },
    Files: { keys: "Super + F", dispatcher: "exec", arg: "nautilus" },
  }
  const swap = [
    { action: "Browser", from: "Super + Shift + Return", to: "Super + Return", because: "Terminal" },
    { action: "Terminal", from: "Super + Return", to: "Super + Shift + Return", because: "" },
  ]
  const swapPlan = context.restorePlan("Terminal", defaults, swap)
  assert.equal(JSON.stringify(swapPlan.map((s) => s.action).sort()), JSON.stringify(["Browser", "Terminal"]))
  const terminal = swapPlan.find((s) => s.action === "Terminal")
  assert.equal(terminal.new_keys, "Super + Return")

  const chain = [
    { action: "Browser", from: "Super + Shift + Return", to: "Super + F", because: "Terminal" },
    { action: "Files", from: "Super + F", to: "Super + N", because: "Terminal" },
    { action: "Terminal", from: "Super + Return", to: "Super + Shift + Return", because: "" },
  ]
  const chainPlan = context.restorePlan("Terminal", defaults, chain)
  assert.equal(JSON.stringify(chainPlan.map((s) => s.action).sort()), JSON.stringify(["Browser", "Files", "Terminal"]))
  assert.equal(chainPlan.find((s) => s.action === "Files").new_keys, "Super + F")
})

test("rowRemapped follows the stored factory chord", () => {
  context.setChordIndex({
    defaults: { Terminal: { keys: "Super + Return" } },
    current: { Terminal: "Super + T" },
    remapped: { Terminal: "Super + T" },
    moves: [{ action: "Terminal", from: "Super + Return", to: "Super + T", because: "" }],
  })
  assert.equal(context.defaultKeysFor("Terminal"), "Super + Return")
  assert.equal(context.rowRemapped("Terminal"), true)
  context.setChordIndex({
    defaults: { Terminal: { keys: "Super + Return" } },
    current: { Terminal: "Super + Return" },
    remapped: {},
    moves: [],
  })
  assert.equal(context.rowRemapped("Terminal"), false)
})
