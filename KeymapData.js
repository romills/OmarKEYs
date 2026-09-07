.pragma library

var sections = [
  {
    title: "Main",
    rows: [
      { keys: "Super + Space", action: "Omarchy menu" },
      { keys: "Super + Return", action: "Terminal" },
      { keys: "Super + Shift + Return", action: "Browser" },
      { keys: "Super + Shift + F", action: "File manager" },
      { keys: "Super + K", action: "OmarKEYS" },
      { keys: "Double-tap Super", action: "OmarKEYS" },
      { keys: "Hold Super 5s", action: "OmarKEYS" },
      { keys: "Super + Escape", action: "System menu" },
      { keys: "Super + W", action: "Close window" },
      { keys: "Super + Ctrl + L", action: "Lock screen" }
    ]
  },
  {
    title: "Menus and launchers",
    rows: [
      { keys: "Super + Alt + Space", action: "Apps menu" },
      { keys: "Super + Shift + Ctrl + Space", action: "Theme menu" },
      { keys: "Super + Ctrl + Space", action: "Background switcher" },
      { keys: "Super + Ctrl + O", action: "Toggle menu" },
      { keys: "Super + Ctrl + H", action: "Hardware menu" },
      { keys: "Super + Ctrl + C", action: "Capture menu" },
      { keys: "Super + Shift + Space", action: "Toggle top bar" },
      { keys: "Super + Ctrl + 1-9", action: "Bar panel 1-9" }
    ]
  },
  {
    title: "Windows",
    rows: [
      { keys: "Super + F", action: "Fullscreen" },
      { keys: "Super + Ctrl + F", action: "Tiled fullscreen" },
      { keys: "Super + Alt + F", action: "Full width" },
      { keys: "Super + T", action: "Float / tile" },
      { keys: "Super + J", action: "Toggle split" },
      { keys: "Super + O", action: "Pop out (float and pin)" },
      { keys: "Super + P", action: "Pseudo window" },
      { keys: "Super + L", action: "Toggle workspace layout" },
      { keys: "Super + Backspace", action: "Toggle transparency" },
      { keys: "Super + Shift + Backspace", action: "Toggle gaps" },
      { keys: "Super + Ctrl + Backspace", action: "Square single-window" },
      { keys: "Ctrl + Alt + Delete", action: "Close all windows" }
    ]
  },
  {
    title: "Focus and move",
    rows: [
      { keys: "Super + arrows", action: "Focus window that way" },
      { keys: "Super + Shift + arrows", action: "Swap window that way" },
      { keys: "Alt + Tab", action: "Next window" },
      { keys: "Shift + Alt + Tab", action: "Previous window" },
      { keys: "Ctrl + Alt + Tab", action: "Next monitor" },
      { keys: "Shift + Ctrl + Alt + Tab", action: "Previous monitor" },
      { keys: "Super + left drag", action: "Move window" },
      { keys: "Super + right drag", action: "Resize window" }
    ]
  },
  {
    title: "Workspaces",
    rows: [
      { keys: "Super + 1-9, 0", action: "Switch to workspace 1-10" },
      { keys: "Super + Shift + 1-9, 0", action: "Move window there" },
      { keys: "Super + Shift + Alt + 1-9, 0", action: "Move window silently" },
      { keys: "Super + Tab", action: "Next workspace" },
      { keys: "Super + Shift + Tab", action: "Previous workspace" },
      { keys: "Super + Ctrl + Tab", action: "Former workspace" },
      { keys: "Super + Shift + Alt + arrows", action: "Move workspace to that monitor" },
      { keys: "Super + scroll", action: "Scroll workspace" }
    ]
  },
  {
    title: "Resize",
    rows: [
      { keys: "Super + - / =", action: "Expand / shrink left" },
      { keys: "Super + Shift + - / =", action: "Shrink up / expand down" },
      { keys: "Super + Ctrl or Alt + those", action: "A lot / a little" },
      { keys: "Super + Alt + Home", action: "Save window width" },
      { keys: "Super + Home", action: "Restore window width" }
    ]
  },
  {
    title: "Groups and scratchpad",
    rows: [
      { keys: "Super + G", action: "Toggle grouping" },
      { keys: "Super + Alt + 1-5", action: "Group window 1-5" },
      { keys: "Super + Alt + Tab", action: "Next window in group" },
      { keys: "Super + Alt + arrows", action: "Move into group that way" },
      { keys: "Super + Alt + G", action: "Move out of group" },
      { keys: "Super + S", action: "Toggle scratchpad" },
      { keys: "Super + Alt + S", action: "Send to scratchpad" }
    ]
  },
  {
    title: "Clipboard and text",
    rows: [
      { keys: "Super + C / X / V", action: "Copy / cut / paste" },
      { keys: "Super + Ctrl + V", action: "Clipboard manager" },
      { keys: "Super + Ctrl + E", action: "Emojis" },
      { keys: "Super + Print", action: "Color picker" },
      { keys: "F9", action: "Dictation push-to-talk" },
      { keys: "Super + Ctrl + X", action: "Toggle dictation" }
    ]
  },
  {
    title: "Capture and share",
    rows: [
      { keys: "Print", action: "Screenshot" },
      { keys: "Alt + Print", action: "Screen recording" },
      { keys: "Super + Ctrl + Print", action: "OCR text from screen" },
      { keys: "Super + Ctrl + S", action: "Share" },
      { keys: "Super + Ctrl + .", action: "Transcode" },
      { keys: "Super + Alt + [ / ]", action: "Webcam overlay size" },
      { keys: "Shift + Alt + D", action: "Download video from web app" },
      { keys: "Shift + Alt + L", action: "Copy URL from web app" }
    ]
  },
  {
    title: "Notifications",
    rows: [
      { keys: "Super + ,", action: "Dismiss last" },
      { keys: "Super + Shift + ,", action: "Dismiss all" },
      { keys: "Super + Alt + ,", action: "Invoke last" },
      { keys: "Super + Ctrl + ,", action: "Silence notifications" },
      { keys: "Super + Shift + Alt + ,", action: "Notification history" },
      { keys: "Super + Ctrl + R", action: "Set reminder" },
      { keys: "Super + Ctrl + Alt + R", action: "Show reminders" },
      { keys: "Super + Shift + Ctrl + R", action: "Clear reminders" }
    ]
  },
  {
    title: "Display and look",
    rows: [
      { keys: "Super + /", action: "Scale monitor up" },
      { keys: "Super + Alt + /", action: "Scale monitor down" },
      { keys: "Super + Ctrl + D", action: "Display panel" },
      { keys: "Super + Ctrl + Delete", action: "Toggle laptop display" },
      { keys: "Super + Ctrl + Alt + Delete", action: "Toggle laptop mirroring" },
      { keys: "Super + Ctrl + N", action: "Night light" },
      { keys: "Super + Ctrl + I", action: "Lock on idle" },
      { keys: "Super + Ctrl + Z", action: "Zoom in" }
    ]
  },
  {
    title: "Bar panels",
    rows: [
      { keys: "Super + Ctrl + A", action: "Audio" },
      { keys: "Super + Ctrl + B", action: "Bluetooth" },
      { keys: "Super + Ctrl + W", action: "Network" },
      { keys: "Super + Ctrl + P", action: "Power" },
      { keys: "Super + Ctrl + T", action: "Activity" },
      { keys: "Super + Ctrl + Q", action: "Calculator" },
      { keys: "Super + Ctrl + Alt + T", action: "Time" },
      { keys: "Super + Ctrl + Alt + W", action: "Weather" }
    ]
  },
  {
    title: "Apps",
    rows: [
      { keys: "Super + Alt + Return", action: "Tmux" },
      { keys: "Super + Ctrl + Return", action: "Herdr" },
      { keys: "Super + Shift + N", action: "Editor" },
      { keys: "Super + Shift + O", action: "Obsidian" },
      { keys: "Super + Shift + D", action: "Docker" },
      { keys: "Super + Shift + M", action: "Music" },
      { keys: "Super + Shift + /", action: "Passwords" },
      { keys: "Super + Shift + Ctrl + A", action: "Agent" },
      { keys: "Super + Shift + A", action: "ChatGPT" },
      { keys: "Super + Shift + Alt + A", action: "Grok" },
      { keys: "Super + Shift + E", action: "Email" },
      { keys: "Super + Shift + G", action: "Signal" },
      { keys: "Super + Shift + Y", action: "YouTube" },
      { keys: "Super + Shift + X", action: "X" }
    ]
  },
  {
    title: "Media and hardware",
    rows: [
      { keys: "Volume keys", action: "Volume up, down, mute" },
      { keys: "Alt + volume", action: "Precise volume" },
      { keys: "Shift + mute", action: "Switch audio output" },
      { keys: "Play / pause / next / prev", action: "Media transport" },
      { keys: "Brightness keys", action: "Display brightness" },
      { keys: "Shift + brightness", action: "Min / max brightness" },
      { keys: "Keyboard light keys", action: "Keyboard backlight" },
      { keys: "Mic mute / calculator / power", action: "Hardware extras" }
    ]
  }
]

var liveSections = null
var currentConfig = {
  doubleTap: true,
  holdSeconds: 5,
  hiddenGroups: [],
  modifiers: { Super: "any", Shift: "any", Ctrl: "any", Alt: "any" }
}

function setSections(next) {
  liveSections = (next && next.length) ? next : null
}

// Long key names push the action column off the row, so a chip can be
// abbreviated. Anything not listed falls back to its first 5 characters,
// which keeps XF86-style names from running away.
var SHORT_KEYS = {
  Super: "Sup", Shift: "Shft", Control: "Ctrl", Ctrl: "Ctrl", Alt: "Alt",
  Return: "Ret", Enter: "Ret", Escape: "Esc", Space: "Spc", Backspace: "Bksp",
  Delete: "Del", Insert: "Ins", Print: "Prt", Home: "Home", End: "End",
  PageUp: "PgUp", PageDown: "PgDn", Left: "←", Right: "→", Up: "↑", Down: "↓",
  Tab: "Tab", "Wheel↓": "Whl↓", "Wheel↑": "Whl↑"
}

// Hyprland reports a mouse bind as separate words, so "Super + Left +
// Mouse + Button" arrives as four chips - and the "Left" would then be
// abbreviated to an arrow, which reads as the arrow key. Collapse the
// whole button into one chip before anything else touches it.
function splitGesture(part) {
  var text = String(part || "")
  var hold = text.match(/^Hold (.+) (\d+s)$/)
  if (hold)
    return ["Hold " + hold[2], hold[1]]
  var tap = text.match(/^(Double-tap) (.+)$/)
  if (tap)
    return [tap[1], tap[2]]
  return null
}

function collapseMouse(parts) {
  var out = []
  for (var i = 0; i < parts.length; i++) {
    var name = parts[i]
    var gesture = splitGesture(name)
    if (gesture) {
      out.push(gesture[0])
      out.push(gesture[1])
      continue
    }
    if (parts[i + 1] === "Mouse" && parts[i + 2] === "Button"
        && (name === "Left" || name === "Right" || name === "Middle")) {
      out.push(name === "Left" ? "LMB" : (name === "Right" ? "RMB" : "MMB"))
      i += 2
      continue
    }
    if (name === "mouse_down") { out.push("Wheel↓"); continue }
    if (name === "mouse_up") { out.push("Wheel↑"); continue }
    out.push(name)
  }
  return out
}

// Nerd Font glyphs, which matter because they live in the overlay's own
// font (Omarchy's monospace resolves to JetBrainsMono Nerd Font). Emoji
// would come from Noto Color Emoji as a *fallback*: a colour font with
// different metrics, which sits badly in a row of monospace chips. These
// are opt-in via the "icons" chip style, so a setup without a Nerd Font
// simply never selects it.
var KEY_ICONS = {
  XF86AudioRaiseVolume: "\udb81\udd7e",
  XF86AudioLowerVolume: "\udb81\udd7f",
  XF86AudioMute: "\udb81\udd81",
  XF86AudioMicMute: "\udb80\udf6d",
  XF86MonBrightnessUp: "\udb80\udcdf",
  XF86MonBrightnessDown: "\udb80\udcde",
  XF86KbdBrightnessUp: "\udb80\udf0c",
  XF86KbdBrightnessDown: "\udb80\udf0c",
  XF86KbdLightOnOff: "\udb81\udddc",
  XF86AudioPlay: "\udb80\udfe4",
  XF86AudioPause: "\udb80\udfe4",
  XF86AudioNext: "\udb81\udcad",
  XF86AudioPrev: "\udb81\udcae",
  XF86PowerOff: "\udb81\udc25",
  XF86Calculator: "\udb80\udcec",
  XF86Eject: "\udb82\udc39",
  XF86TouchpadToggle: "\udb80\udd68",
  XF86TouchpadOn: "\udb80\udd68",
  XF86TouchpadOff: "\udb80\udd68",
  LMB: "\udb80\udf7d L",
  RMB: "\udb80\udf7d R",
  MMB: "\udb80\udf7d M",
  "Wheel\u2193": "\udb80\udf7d \u2193",
  "Wheel\u2191": "\udb80\udf7d \u2191",
  Left: "\udb80\udc4d",
  Right: "\udb80\udc54",
  Up: "\udb80\udc5d",
  Down: "\udb80\udc45",
  Return: "\udb80\udf11",
  Enter: "\udb80\udf11",
  Tab: "\udb80\udf12",
  Space: "\udb84\udc50",
  Escape: "\udb84\udeb7",
  Backspace: "\udb80\udc6e",
  Delete: "\udb80\udd56",
  Home: "\udb80\udedc",
  Print: "\udb81\udc2a"
}

// What an icon is, in words. The raw token is no good here: hovering to
// find out what a glyph means and being told "XF86AudioRaiseVolume" is
// barely an improvement on the glyph.
var KEY_NAMES = {
  XF86AudioRaiseVolume: "Volume up",
  XF86AudioLowerVolume: "Volume down",
  XF86AudioMute: "Mute",
  XF86AudioMicMute: "Mic mute",
  XF86MonBrightnessUp: "Brightness up",
  XF86MonBrightnessDown: "Brightness down",
  XF86KbdBrightnessUp: "Keyboard light up",
  XF86KbdBrightnessDown: "Keyboard light down",
  XF86KbdLightOnOff: "Keyboard light",
  XF86AudioPlay: "Play",
  XF86AudioPause: "Pause",
  XF86AudioNext: "Next track",
  XF86AudioPrev: "Previous track",
  XF86PowerOff: "Power",
  XF86Calculator: "Calculator",
  XF86Eject: "Eject",
  XF86TouchpadToggle: "Touchpad",
  XF86TouchpadOn: "Touchpad on",
  XF86TouchpadOff: "Touchpad off",
  LMB: "Left click",
  RMB: "Right click",
  MMB: "Middle click",
  "Wheel\u2193": "Wheel down",
  "Wheel\u2191": "Wheel up"
}

function keyName(name) {
  var key = String(name || "")
  return KEY_NAMES[key] || key
}

function displayNames(keys) {
  var parts = collapseMouse(splitKeys(keys))
  var out = []
  for (var i = 0; i < parts.length; i++)
    out.push(keyName(parts[i]))
  return out
}

function iconKey(name) {
  return KEY_ICONS[String(name || "")] || ""
}

function shortKey(name) {
  var key = String(name || "")
  if (SHORT_KEYS[key])
    return SHORT_KEYS[key]
  if (/^(Hold \d+s|Double-tap)$/.test(key))
    return key
  // XF86AudioRaiseVolume -> Volume, XF86PowerOff -> Power
  var xf86 = key.match(/^XF86(?:Audio|Mon|Kbd)?([A-Za-z]+)/)
  if (xf86)
    return xf86[1].slice(0, 5)
  return key.length <= 5 ? key : key.slice(0, 5)
}

function displayKeys(keys, style) {
  var parts = collapseMouse(splitKeys(keys))
  if (style === "icons") {
    var iconed = []
    for (var j = 0; j < parts.length; j++) {
      // Anything without an icon keeps its short text, so the row stays
      // readable rather than half-blank.
      iconed.push(iconKey(parts[j]) || shortKey(parts[j]))
    }
    return iconed
  }
  if (style !== "short")
    return parts
  var out = []
  for (var i = 0; i < parts.length; i++)
    out.push(shortKey(parts[i]))
  return out
}

function setConfig(cfg) {
  var hidden = []
  if (cfg && cfg.hiddenGroups) {
    for (var i = 0; i < cfg.hiddenGroups.length; i++)
      hidden.push(String(cfg.hiddenGroups[i]))
  }
  var modsIn = (cfg && cfg.modifiers) || {}
  currentConfig = {
    doubleTap: !cfg || cfg.doubleTap !== false,
    holdSeconds: Math.max(1, Math.min(10, Number(cfg && cfg.holdSeconds) || 5)),
    hiddenGroups: hidden,
    modifiers: {
      Super: normalizeModifierMode(modsIn.Super),
      Shift: normalizeModifierMode(modsIn.Shift),
      Ctrl: normalizeModifierMode(modsIn.Ctrl),
      Alt: normalizeModifierMode(modsIn.Alt)
    },
    chipStyle: (cfg && (cfg.chipStyle === "short" || cfg.chipStyle === "full"))
      ? cfg.chipStyle : "icons",
    rowLayout: (cfg && cfg.rowLayout === "keys") ? "keys" : "action",
    sortBy: (cfg && cfg.sortBy === "section") ? "section" : "action",
    searchMode: (cfg && (cfg.searchMode === "keys" || cfg.searchMode === "action"))
      ? cfg.searchMode : "all"
  }
}

function searchMode() {
  return currentConfig.searchMode || "all"
}

function sortBy() {
  return currentConfig.sortBy || "section"
}

// Which field the query is tested against. "Search by modifiers" means the
// chord text, so Super+Shift narrows to those; "by description" means the
// action, so typing a word never matches a stray key name.
function rowMatchesQuery(row, sectionTitle, q) {
  if (!q)
    return true
  var mode = searchMode()
  var keys = String(row.keys).toLowerCase()
  var action = String(row.action).toLowerCase()
  if (mode === "keys")
    return keys.indexOf(q) !== -1
  if (mode === "action")
    return action.indexOf(q) !== -1
  return keys.indexOf(q) !== -1 || action.indexOf(q) !== -1
    || String(sectionTitle).toLowerCase().indexOf(q) !== -1
}

function normalizeModifierMode(value) {
  if (value === "must" || value === "hide" || value === "any")
    return value
  if (value === false)
    return "hide"
  return "any"
}

function rowUsesModifier(row, name) {
  var blob = String((row && row.mods) || "") + " " + String((row && row.keys) || "")
  var low = blob.toLowerCase()
  if (name === "Super")
    return /\bsuper\b/.test(low)
  if (name === "Shift")
    return /\bshift\b/.test(low)
  if (name === "Ctrl")
    return /\bctrl\b|\bcontrol\b/.test(low)
  if (name === "Alt")
    return /\balt\b/.test(low)
  return false
}

function rowMatchesModifiers(row) {
  var modes = currentConfig.modifiers || {}
  var names = ["Super", "Shift", "Ctrl", "Alt"]
  for (var i = 0; i < names.length; i++) {
    var name = names[i]
    var mode = modes[name] || "any"
    var uses = rowUsesModifier(row, name)
    if (mode === "must" && !uses)
      return false
    if (mode === "hide" && uses)
      return false
  }
  return true
}

function isHidden(title) {
  var hidden = currentConfig.hiddenGroups || []
  for (var i = 0; i < hidden.length; i++) {
    if (hidden[i] === title)
      return true
  }
  return false
}

function catalogFor(sectionList) {
  var source = sectionList && sectionList.length ? sectionList : []
  var out = []
  for (var i = 0; i < source.length; i++) {
    out.push({
      title: source[i].title,
      hidden: isHidden(source[i].title)
    })
  }
  return out
}

function catalog() {
  return catalogFor(withGestures(activeSections(), currentConfig))
}

// Five top-level areas the sidebar tree groups Omarchy's topic groups
// under. Keep this in sync with SECTION_RULES in dump-keymap — every
// title dump-keymap can emit (14 rules + its own "Other" fallback)
// should appear exactly once below.
var areaMap = [
  { title: "Launch & navigate", groups: ["Main", "Menus and launchers", "Bar panels"] },
  { title: "Windows & workspaces", groups: ["Windows", "Focus and move", "Workspaces", "Resize", "Groups and scratchpad"] },
  { title: "Clipboard & capture", groups: ["Clipboard and text", "Capture and share"] },
  { title: "System & media", groups: ["Notifications", "Display and look", "Media and hardware", "Other"] },
  { title: "Apps", groups: ["Apps"] }
]

function groupedCatalog(sectionList) {
  var flat = catalogFor(sectionList)
  var byTitle = {}
  for (var i = 0; i < flat.length; i++)
    byTitle[flat[i].title] = flat[i]
  var used = {}
  var out = []
  for (var a = 0; a < areaMap.length; a++) {
    var groups = []
    var names = areaMap[a].groups
    for (var j = 0; j < names.length; j++) {
      var entry = byTitle[names[j]]
      if (entry) {
        groups.push(entry)
        used[names[j]] = true
      }
    }
    if (groups.length)
      out.push({ title: areaMap[a].title, groups: groups })
  }
  // Defensive: a group title not covered by areaMap above (e.g. one
  // added to SECTION_RULES / sections without updating this map) still
  // shows up here instead of silently vanishing from the tree.
  var leftovers = []
  for (var k = 0; k < flat.length; k++) {
    if (!used[flat[k].title])
      leftovers.push(flat[k])
  }
  if (leftovers.length)
    out.push({ title: "Other", groups: leftovers })
  return out
}

function activeSections() {
  return liveSections && liveSections.length ? liveSections : sections
}

function gestureRows(cfg) {
  var hold = (cfg && cfg.holdSeconds) || 5
  var rows = []
  if (!cfg || cfg.doubleTap !== false)
    rows.push({ keys: "Double-tap Super", action: "OmarKEYS" })
  rows.push({ keys: "Hold Super " + hold + "s", action: "OmarKEYS" })
  return rows
}

function withGestures(all, cfg) {
  var extra = gestureRows(cfg)
  var out = []
  var injected = false
  for (var i = 0; i < all.length; i++) {
    var sec = { title: all[i].title, rows: all[i].rows.slice() }
    if (!injected && sec.title === "Main") {
      var rows = []
      var placed = false
      for (var r = 0; r < sec.rows.length; r++) {
        var row = sec.rows[r]
        if (/double-tap super|hold super/i.test(String(row.keys)))
          continue
        rows.push(row)
        if (!placed && (String(row.keys) === "Super + K" || /omarkeys/i.test(String(row.action)))) {
          for (var e = 0; e < extra.length; e++)
            rows.push(extra[e])
          placed = true
        }
      }
      if (!placed) {
        for (var e2 = 0; e2 < extra.length; e2++)
          rows.push(extra[e2])
      }
      sec.rows = rows
      injected = true
    }
    out.push(sec)
  }
  return out
}

function filtered(query) {
  var q = String(query || "").toLowerCase().trim()
  var source = withGestures(activeSections(), currentConfig)
  var out = []
  for (var s = 0; s < source.length; s++) {
    var rows = []
    var section = source[s]
    if (isHidden(section.title))
      continue
    for (var r = 0; r < section.rows.length; r++) {
      var row = section.rows[r]
      if (!rowMatchesModifiers(row))
        continue
      if (rowMatchesQuery(row, section.title, q))
        rows.push(row)
    }
    if (sortBy() === "action") {
      rows = rows.slice().sort(function (a, b) {
        return String(a.action).toLowerCase() < String(b.action).toLowerCase() ? -1
          : (String(a.action).toLowerCase() > String(b.action).toLowerCase() ? 1 : 0)
      })
    }
    if (rows.length)
      out.push({ title: section.title, rows: rows })
  }
  return out
}

function columns(query) {
  var all = filtered(query)
  var left = []
  var right = []
  for (var i = 0; i < all.length; i++) {
    var block = { title: all[i].title, rows: all[i].rows, sectionIndex: i }
    if (i % 2 === 0)
      left.push(block)
    else
      right.push(block)
  }
  return { left: left, right: right }
}

function splitKeys(keys) {
  return String(keys || "").split(/\s*\+\s*/).filter(function(part) {
    return part.length > 0
  })
}

function isRunnable(keys) {
  var k = String(keys || "")
  if (!k)
    return false
  if (/\d-\d/.test(k) || /arrows|drag|scroll|volume keys|brightness keys|keyboard light|play \/ pause|mic mute|double-tap|hold super/i.test(k))
    return false
  if (/\s\/\s/.test(k))
    return false
  return true
}

function isProtectedChord(keys) {
  var k = String(keys || "").trim()
  if (/^Super\s*\+\s*K$/i.test(k) || /^SUPER\s*\+\s*K$/i.test(k))
    return true
  if (/double-tap super|hold super/i.test(k))
    return true
  return false
}

function normalizeChord(keys) {
  var parts = splitKeys(keys)
  var have = {}
  var key = ""
  for (var i = 0; i < parts.length; i++) {
    var up = String(parts[i]).trim().toUpperCase()
    if (up === "SUPER" || up === "META" || up === "WIN")
      have.SUPER = true
    else if (up === "SHIFT")
      have.SHIFT = true
    else if (up === "CTRL" || up === "CONTROL")
      have.CTRL = true
    else if (up === "ALT" || up === "MOD1")
      have.ALT = true
    else if (up)
      key = up
  }
  var out = []
  if (have.SUPER) out.push("SUPER")
  if (have.SHIFT) out.push("SHIFT")
  if (have.CTRL) out.push("CTRL")
  if (have.ALT) out.push("ALT")
  if (key) out.push(key)
  return out.join(" + ")
}

var chordIndex = { defaults: {}, remapped: {}, moves: [], current: {} }

function setChordIndex(data) {
  chordIndex = data && typeof data === "object"
    ? {
        defaults: data.defaults || {},
        remapped: data.remapped || {},
        moves: data.moves || [],
        current: data.current || {}
      }
    : { defaults: {}, remapped: {}, moves: [], current: {} }
}

function defaultKeysFor(action) {
  var meta = chordIndex.defaults && chordIndex.defaults[action]
  if (!meta)
    return ""
  return typeof meta === "object" ? String(meta.keys || "") : String(meta || "")
}

function rowRemapped(action) {
  var name = String(action || "")
  if (!name)
    return false
  if (chordIndex.remapped && chordIndex.remapped[name])
    return true
  var def = defaultKeysFor(name)
  var cur = chordIndex.current && chordIndex.current[name]
  if (!def || !cur)
    return false
  return normalizeChord(def) !== normalizeChord(cur)
}

function flattenRows(sectionList) {
  var list = sectionList || sections
  var rows = []
  if (!list)
    return rows
  for (var s = 0; s < list.length; s++) {
    var block = (list[s] && list[s].rows) || []
    for (var i = 0; i < block.length; i++)
      rows.push(block[i])
  }
  return rows
}

function findOccupant(chord, exceptAction, sectionList, pending) {
  var want = normalizeChord(chord)
  if (!want)
    return null
  var keys = {}
  var info = {}
  var rows = flattenRows(sectionList)
  for (var i = 0; i < rows.length; i++) {
    var row = rows[i]
    var name = row && row.action
    if (!name)
      continue
    keys[name] = row.keys
    info[name] = row
  }
  var moves = pending || []
  for (var p = 0; p < moves.length; p++) {
    var step = moves[p]
    if (!step || !step.action)
      continue
    keys[step.action] = step.new_keys
    info[step.action] = {
      action: step.action,
      keys: step.new_keys,
      dispatcher: step.dispatcher || (info[step.action] && info[step.action].dispatcher) || "",
      arg: step.arg != null ? step.arg : ((info[step.action] && info[step.action].arg) || "")
    }
  }
  for (var action in keys) {
    if (exceptAction && action === exceptAction)
      continue
    if (normalizeChord(keys[action]) !== want)
      continue
    var hit = info[action] || {}
    return {
      action: action,
      keys: keys[action],
      dispatcher: hit.dispatcher || "",
      arg: hit.arg || ""
    }
  }
  return null
}

function relatedActions(action, moves) {
  var related = {}
  related[String(action || "")] = true
  var list = moves || []
  var changed = true
  while (changed) {
    changed = false
    for (var i = 0; i < list.length; i++) {
      var move = list[i] || {}
      var name = String(move.action || "")
      var because = String(move.because || "")
      if (related[name] || (because && related[because])) {
        if (name && !related[name]) {
          related[name] = true
          changed = true
        }
        if (because && !related[because]) {
          related[because] = true
          changed = true
        }
      }
    }
  }
  var out = []
  for (var key in related) {
    if (key)
      out.push(key)
  }
  return out.sort()
}

function restorePlan(action, defaults, moves) {
  var related = relatedActions(action, moves)
  var current = {}
  for (var name in (defaults || {})) {
    var meta = defaults[name] || {}
    current[name] = typeof meta === "object" ? String(meta.keys || "") : String(meta || "")
  }
  var list = moves || []
  for (var i = 0; i < list.length; i++) {
    if (list[i] && list[i].action)
      current[list[i].action] = list[i].to
  }
  var steps = []
  for (var r = 0; r < related.length; r++) {
    var item = related[r]
    var factory = defaults && defaults[item]
    if (!factory)
      continue
    var factoryKeys = typeof factory === "object" ? String(factory.keys || "") : String(factory || "")
    if (normalizeChord(current[item] || "") === normalizeChord(factoryKeys))
      continue
    steps.push({
      action: item,
      old_keys: current[item] || "",
      new_keys: factoryKeys,
      dispatcher: (typeof factory === "object" && factory.dispatcher) || "",
      arg: (typeof factory === "object" && factory.arg) || "",
      because: ""
    })
  }
  return steps
}

// Chord remap only: need the recovered Hyprland action, and never OmarKEYS'
// own summons (Super+K / hold / double-tap).
function rowEditable(row) {
  if (!row || isProtectedChord(row.keys))
    return false
  if (row.runnable === false)
    return false
  if (!row.dispatcher)
    return false
  return isRunnable(row.keys)
}

// One verdict for the board (dim) and the keyboard (Enter). dump-keymap's
// runnable:false wins; a recovered dispatcher can still run even if the
// chord text looks odd; otherwise the chord must parse as a shortcut.
function rowRunnable(row) {
  if (!row || row.runnable === false)
    return false
  if (row.dispatcher)
    return true
  var sc = row.bindKey
    ? { mods: row.mods || "", key: row.bindKey }
    : shortcut(row.keys)
  return isRunnable(row.keys) && !!sc
}

var KEY_SYMS = {
  Return: "Return",
  Enter: "Return",
  Space: "space",
  Escape: "Escape",
  Backspace: "BackSpace",
  Print: "Print",
  Home: "Home",
  Delete: "Delete",
  Tab: "Tab",
  ",": "comma",
  ".": "period",
  "-": "minus",
  "=": "equal",
  "/": "slash",
  "[": "bracketleft",
  "]": "bracketright"
}

var MOD_SYMS = {
  Super: "SUPER",
  Shift: "SHIFT",
  Ctrl: "CTRL",
  Control: "CTRL",
  Alt: "ALT"
}

function shortcut(keys) {
  if (!isRunnable(keys))
    return null
  var parts = splitKeys(keys)
  var mods = []
  var key = ""
  for (var i = 0; i < parts.length; i++) {
    var p = parts[i]
    if (MOD_SYMS[p])
      mods.push(MOD_SYMS[p])
    else
      key = KEY_SYMS[p] || p
  }
  if (!key)
    return null
  return { mods: mods.join(" "), key: key }
}

function navList(query) {
  var all = filtered(query)
  var items = []
  for (var s = 0; s < all.length; s++) {
    for (var r = 0; r < all[s].rows.length; r++) {
      var row = all[s].rows[r]
      var sc = null
      if (row.bindKey)
        sc = { mods: row.mods || "", key: row.bindKey }
      else
        sc = shortcut(row.keys)
      items.push({
        section: s,
        sectionTitle: all[s].title,
        keys: row.keys,
        action: row.action,
        // A Hyprland bind's own action, when dump-keymap recovered it.
        // Preferred over replaying the chord: synthetic keys sent to a
        // window never reach Hyprland's bind matcher.
        dispatcher: row.dispatcher || "",
        dispatchArg: row.arg || "",
        runnable: rowRunnable(row),
        shortcut: sc
      })
    }
  }
  return items
}

function sectionStarts(items) {
  var starts = []
  var last = null
  for (var i = 0; i < items.length; i++) {
    if (items[i].section !== last) {
      starts.push(i)
      last = items[i].section
    }
  }
  return starts
}
