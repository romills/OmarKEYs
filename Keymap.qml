import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import qs.Commons
import qs.Ui
import "KeymapData.js" as KeymapData

Item {
  id: root

  property var shell: null
  property var manifest: null
  property bool opened: false
  // Which monitor the overlay was opened on, latched at open and never
  // rewritten. Bound live to Hyprland.focusedMonitor instead, the card would
  // chase the pointer across displays under follow_mouse = 1: open it on one
  // screen, glance at another, and the keymap jumps there.
  property string openMonitor: ""
  // Which monitor is actually showing the card. The same as openMonitor
  // whenever that screen is present, and something else only while it is not.
  // Keeping the wish and the fact apart is what lets the card come home: an
  // output can vanish for a moment on a mode change or DPMS blink, and a single
  // value would move away and then have nothing left to move back to.
  property string cardMonitor: ""
  property bool grabKeys: false
  property string filterText: ""
  property var leftSections: []
  property var rightSections: []
  property var navItems: []
  property int selected: 0
  property string selectedKeys: ""
  property string selectedAction: ""
  property string pendingMods: ""
  property string pendingKey: ""
  property string pendingDispatcher: ""
  property string pendingArg: ""
  property string pendingFocus: ""
  // The window that was focused when the overlay opened. Rows that send
  // keys are aimed at it explicitly, so a chord lands in the app you were
  // using rather than wherever focus drifted by the time we replay it.
  property string contextAddress: ""
  property bool contextAddressLatched: false
  property bool doubleTap: true
  property int holdSeconds: 5
  // Whether OmarKEYS claims Super+K. Off leaves the chord to whatever had
  // it before (Omarchy binds "Keybindings"); hyprland.lua acts on this.
  property bool superK: true
  property bool holdEnabled: true

  // Hold Super had no off switch, and that was what guaranteed a way in.
  // Now that all three can be turned off, the last one standing refuses:
  // otherwise the only way back into the overlay is editing the config
  // file by hand.
  readonly property int openerCount: (root.superK ? 1 : 0)
    + (root.doubleTap ? 1 : 0) + (root.holdEnabled ? 1 : 0)
  function isLastOpener(on) {
    return on && root.openerCount <= 1
  }
  property var hiddenGroups: []
  // Layout experiments, switchable from the settings bar so they can be
  // compared against each other rather than rebuilt to try.
  property string chipStyle: "icons"    // full | short | icons
  property string rowLayout: "action"   // keys | action
  property string sortBy: "key"         // section | action | key
  property string grouping: "topic"     // topic | keytype | off
  property string searchMode: "all"     // all | keys | action
  // Which keyboard's keycaps the modifier chips imitate. Mac symbols all
  // four; the PC layouts print words, so they only supply a Super logo.
  property string keyboardType: "windows" // text | mac | windows | omarchy
  // Draw keys as keycaps. Only keys you press get one -- an action the key
  // performs, or a mouse button, is not a cap and does not want a box.
  property bool iconBorders: false
  // Text size for the board, now that the overlay fills more of the screen.
  property real fontScale: 1.0
  // One number, not two. Compensating for the cap by resizing the glyph
  // meant toggling Border resized every icon by 11% -- subtle small, and
  // obvious at the top of the Size range, which is the opposite of the
  // two states matching. A cap is drawn around the same glyph now, so the
  // border changes the outline and nothing else.
  readonly property real iconScale: 1.35
  // Apps switched off in the tree, by window class. A hidden app leaves the
  // list rather than sitting there dimmed: this is a live window list, so a
  // permanent dimmed entry is just clutter of a different kind. Showing the
  // Active Apps branch brings them all back.
  property var hiddenApps: []
  property var groupList: []
  property var omarchyTree: []
  property string modSuper: "any"
  property string modShift: "any"
  property string modCtrl: "any"
  property string modAlt: "any"
  property string selectedSectionTitle: ""
  property bool launching: false
  property int focusTick: 0
  property bool contextArmed: false
  property var contextToplevel: null
  property string keymapHash: ""
  property var omarchySections: []
  property var clients: []
  property var workspaces: []
  // Which workspace the app tree is showing. 0 is all of them, which is
  // where it starts: the tree should open showing everything you have,
  // not a slice of it.
  property int workspaceFilter: 0
  property string activeSource: "omarchy"
  property bool editMode: false
  property bool capturing: false
  property string captureOldKeys: ""
  property string captureAction: ""
  property string editStatus: ""
  readonly property bool omarchyActive: root.activeSource === "omarchy"
  readonly property bool appsActive: root.activeSource === "apps"

  // Loading every app sheet at once. One FileView, one sheet at a time:
  // there are a handful of kinds, and a queue is less machinery than a
  // FileView per sheet with no way to know when they have all landed.
  property var sheetQueue: []
  property var mergedSections: []

  // One entry per kind, not per app. Apps of a kind share a sheet, so
  // listing them separately would repeat the same bindings once per
  // window that happens to be open. Scoped to the selected workspace, so
  // the board answers the same question the tree does: what is here, and
  // what does it answer to.
  //
  // A function, not a binding: the caller is the workspaceFilter change
  // handler, and a binding read from inside a handler for its own
  // dependency can still hand back the pre-change value.
  function appSheetsFor(only) {
    var out = []
    var seen = ({})
    var list = root.clients || []
    for (var i = 0; i < list.length; i++) {
      if (only > 0 && !root.appOnWorkspace(list[i], only))
        continue
      var sheet = list[i].sheet || ""
      if (!sheet || seen[sheet])
        continue
      seen[sheet] = true
      out.push({ sheet: sheet, kind: list[i].kind || root.noSheetKind })
    }
    return out
  }

  // The workspace filter is a view of the same client list, so the board
  // has to be reloaded when it moves -- nothing else re-reads the sheets.
  onWorkspaceFilterChanged: if (root.appsActive) root.loadAppSheets()

  readonly property bool allGroupsVisible: {
    var list = root.groupList
    if (!list || !list.length)
      return true
    for (var i = 0; i < list.length; i++) {
      if (list[i].hidden)
        return false
    }
    return true
  }
  readonly property bool allModsAny: root.modSuper === "any" && root.modShift === "any" && root.modCtrl === "any" && root.modAlt === "any"
  readonly property bool allModsMust: root.modSuper === "must" && root.modShift === "must" && root.modCtrl === "must" && root.modAlt === "must"
  readonly property bool allModsHide: root.modSuper === "hide" && root.modShift === "hide" && root.modCtrl === "hide" && root.modAlt === "hide"
  readonly property string sourceDir: (root.manifest && root.manifest.__sourceDir)
    || ((Quickshell.env("HOME") || "") + "/.config/omarchy/plugins/io.github.romills.omarkeys")
  readonly property string configPath: (Quickshell.env("HOME") || "") + "/.config/omarchy/omarkeys.json"

  property color background: Color.menu.background
  property color foreground: Color.menu.text
  property color border: Color.menu.border
  property var borderSpec: Border.surfaceSpec("menu", "border", border, Math.max(1, Style.space(2)))
  property color scrim: Color.menu.scrim
  property color chipBg: Color.menu.selectedBackground
  property color chipFg: Color.menu.selectedText
  readonly property int cornerRadius: Style.cornerRadius
  property string fontFamily: Style.font.menuFamily
  property int contentMargin: Style.spacing.panelPadding

  function pluginId() {
    return (root.manifest && root.manifest.id) || "io.github.romills.omarkeys"
  }

  function configObject() {
    return {
      doubleTap: root.doubleTap,
      holdSeconds: root.holdSeconds,
      superK: root.superK,
      holdEnabled: root.holdEnabled,
      hiddenGroups: root.hiddenGroups,
      hiddenApps: root.hiddenApps,
      chipStyle: root.chipStyle,
      rowLayout: root.rowLayout,
      sortBy: root.sortBy,
      grouping: root.grouping,
      searchMode: root.searchMode,
      keyboardType: root.keyboardType,
      iconBorders: root.iconBorders,
      fontScale: root.fontScale,
      modifiers: {
        Super: root.modSuper,
        Shift: root.modShift,
        Ctrl: root.modCtrl,
        Alt: root.modAlt
      }
    }
  }

  function open(payloadJson) {
    root.filterText = ""
    root.workspaceFilter = 0
    root.grabKeys = false
    root.launching = false
    root.contextArmed = false
    root.contextToplevel = ToplevelManager.activeToplevel
    root.openMonitor = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : ""
    root.cardMonitor = ""
    root.resolveCardMonitor()
    root.contextAddress = ""
    root.contextAddressLatched = false
    root.branchMenuOpen = false
    root.optionsMenuOpen = false
    root.filterCapturing = false
    root.selected = 0
    root.applyConfigToData()
    root.refreshKeymap()
    root.refreshGitInfo()
    root.rebuild()
    root.opened = true
  }

  function applyConfigToData() {
    KeymapData.setConfig(root.configObject())
  }

  function applyConfigText(text) {
    try {
      var cfg = JSON.parse(text)
      if (cfg && typeof cfg === "object") {
        if (cfg.doubleTap === false)
          root.doubleTap = false
        else if (cfg.doubleTap === true)
          root.doubleTap = true
        if (cfg.superK === false)
          root.superK = false
        else if (cfg.superK === true)
          root.superK = true
        if (cfg.holdEnabled === false)
          root.holdEnabled = false
        else if (cfg.holdEnabled === true)
          root.holdEnabled = true
        var hold = Number(cfg.holdSeconds)
        if (hold >= 1 && hold <= 10)
          root.holdSeconds = Math.round(hold)
        if (Object.prototype.toString.call(cfg.hiddenGroups) === "[object Array]")
          root.hiddenGroups = cfg.hiddenGroups.slice()
        if (Object.prototype.toString.call(cfg.hiddenApps) === "[object Array]")
          root.hiddenApps = cfg.hiddenApps.slice()
        if (cfg.chipStyle === "short" || cfg.chipStyle === "full" || cfg.chipStyle === "icons")
          root.chipStyle = cfg.chipStyle
        if (cfg.rowLayout === "action" || cfg.rowLayout === "keys")
          root.rowLayout = cfg.rowLayout
        if (cfg.sortBy === "action" || cfg.sortBy === "section" || cfg.sortBy === "key")
          root.sortBy = cfg.sortBy
        if (cfg.grouping === "topic" || cfg.grouping === "keytype"
            || cfg.grouping === "off")
          root.grouping = cfg.grouping
        if (cfg.searchMode === "keys" || cfg.searchMode === "action" || cfg.searchMode === "all")
          root.searchMode = cfg.searchMode
        // keyboardOS and superIcon are earlier names for this setting.
        var kb = cfg.keyboardType || cfg.keyboardOS || cfg.superIcon
        if (kb === "command" || kb === "option")
          root.keyboardType = "mac"
        else if (kb === "superman")
          root.keyboardType = "windows"
        else if (kb === "text" || kb === "mac" || kb === "windows" || kb === "omarchy")
          root.keyboardType = kb
        if (cfg.iconBorders === false)
          root.iconBorders = false
        else if (cfg.iconBorders === true)
          root.iconBorders = true
        var scale = Number(cfg.fontScale)
        if (scale >= 0.6 && scale <= 1.4)
          root.fontScale = scale
        if (cfg.modifiers && typeof cfg.modifiers === "object") {
          root.modSuper = KeymapData.normalizeModifierMode(cfg.modifiers.Super)
          root.modShift = KeymapData.normalizeModifierMode(cfg.modifiers.Shift)
          root.modCtrl = KeymapData.normalizeModifierMode(cfg.modifiers.Ctrl)
          root.modAlt = KeymapData.normalizeModifierMode(cfg.modifiers.Alt)
        }
      }
    } catch (e) {
    }
    root.applyConfigToData()
    root.rebuild()
  }

  function saveConfig() {
    root.applyConfigToData()
    configFile.setText(JSON.stringify(root.configObject(), null, 2) + "\n")
    root.rebuild()
  }

  function applyDump(text) {
    var data = null
    try {
      data = JSON.parse(text)
    } catch (e) {
      return
    }
    if (!data)
      return
    if (data.clients) {
      root.clients = data.clients
      root.workspaces = data.workspaces || []
      // Latch once per open: later refreshes must not re-point this at
      // something that took focus while the overlay was already up.
      if (!root.contextAddressLatched) {
        for (var c = 0; c < data.clients.length; c++) {
          if (data.clients[c].focused && data.clients[c].address) {
            root.contextAddress = data.clients[c].address
            root.contextAddressLatched = true
            break
          }
        }
      }
    }
    var same = data.hash && data.hash === root.keymapHash
    if (data.sections && data.sections.length) {
      root.omarchySections = data.sections
      root.keymapHash = data.hash || root.keymapHash
    }
    if (root.omarchyActive) {
      KeymapData.setSections(root.omarchySections)
      root.applyConfigToData()
      root.rebuild(true)
      if (!same && root.opened)
        root.requestFocus()
    }
  }

  function refreshKeymap() {
    if (dumpProc.running)
      dumpProc.running = false
    dumpProc.running = true
  }

  property string sheetPath: ""
  property string activeLabel: ""

  // Every kind's sheet, one after another, each section tagged with the
  // kind it came from so the board can say whose bindings these are.
  function loadAppSheets() {
    root.mergedSections = []
    root.sheetQueue = root.appSheetsFor(root.workspaceFilter)
    // Clear first: the queue advances by setting sheetPath, and setting it
    // to what it already holds loads nothing, so re-entering this view
    // would leave the queue waiting on a file that never arrives.
    root.sheetPath = ""
    root.nextAppSheet()
  }

  function nextAppSheet() {
    var queue = root.sheetQueue
    if (!queue.length) {
      root.sheetPath = ""
      var where = root.workspaceFilter > 0
        ? "on workspace " + root.workspaceFilter
        : "on screen"
      KeymapData.setSections(root.mergedSections.length
        ? root.mergedSections
        : [{ title: "Active Apps",
             rows: [{ keys: "—",
                      action: "No app " + where + " has a bundled keymap sheet" }] }])
      root.rebuild()
      return
    }
    root.sheetPath = root.sourceDir + "/sheets/" + queue[0].sheet
  }

  function appSheetLoaded(text) {
    var queue = root.sheetQueue
    var kind = queue.length ? queue[0].kind : ""
    try {
      var data = JSON.parse(text)
      var sections = (data && data.sections) || []
      var merged = root.mergedSections.slice()
      for (var i = 0; i < sections.length; i++) {
        var copy = ({})
        for (var f in sections[i])
          copy[f] = sections[i][f]
        // Which kind these bindings belong to. The board already knows how
        // to show a qualifier beside a heading.
        copy.qualifier = "[" + kind + "]"
        merged.push(copy)
      }
      root.mergedSections = merged
    } catch (e) {
      // A sheet that will not parse is one kind missing, not a dead view.
    }
    root.sheetQueue = queue.slice(1)
    // Out of the signal handler before touching the path again: assigning
    // FileView.path from inside its own onLoaded does not start another
    // load, which stalled the queue after the first sheet.
    Qt.callLater(root.nextAppSheet)
  }

  function emptySheetSections(label) {
    var name = label || "this window"
    return [{
      title: label || "This app",
      rows: [{ keys: "—", action: "No bundled keymap sheet for \"" + name + "\" yet" }]
    }]
  }

  FileView {
    id: sheetFile
    path: root.sheetPath
    printErrors: false
    onLoaded: {
      if (root.appsActive) {
        root.appSheetLoaded(text())
        return
      }
      try {
        var data = JSON.parse(text())
        if (data && data.sections)
          KeymapData.setSections(data.sections)
        else
          throw new Error("empty")
      } catch (e) {
        KeymapData.setSections(root.emptySheetSections(root.activeLabel))
      }
      root.rebuild()
    }
    onLoadFailed: {
      if (!root.sheetPath)
        return
      if (root.appsActive) {
        root.appSheetLoaded("")
        return
      }
      KeymapData.setSections(root.emptySheetSections(root.activeLabel))
      root.rebuild()
    }
  }

  FileView {
    id: bindingsWatch
    path: (Quickshell.env("HOME") || "") + "/.config/hypr/bindings.lua"
    watchChanges: true
    printErrors: false
    onFileChanged: if (root.opened) root.refreshKeymap()
  }

  FileView {
    id: editsWatch
    path: (Quickshell.env("HOME") || "") + "/.config/hypr/omarkeys-edits.lua"
    watchChanges: true
    printErrors: false
    onFileChanged: if (root.opened) root.refreshKeymap()
  }

  Timer {
    id: reloadTimer
    interval: 3000
    repeat: true
    running: root.opened
    onTriggered: root.refreshKeymap()
  }

  FileView {
    id: configFile
    path: root.configPath
    watchChanges: true
    atomicWrites: true
    printErrors: false
    onLoaded: root.applyConfigText(text())
    onLoadFailed: root.saveConfig()
    onFileChanged: reload()
  }

  Timer {
    id: hyprReloadTimer
    interval: 150
    repeat: false
    onTriggered: hyprReloadProc.running = true
  }

  Process {
    id: hyprReloadProc
    command: ["hyprctl", "reload"]
  }

  Process {
    id: dumpProc
    command: [root.sourceDir + "/dump-keymap"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.applyDump(text)
    }
  }

  property string gitBranch: ""
  property string gitHash: ""
  property var gitBranches: []
  property bool gitDirty: false
  property bool gitUpdateAvailable: false
  property int gitBehind: 0
  property string gitError: ""
  property bool gitBusy: false
  property bool branchMenuOpen: false
  property bool optionsMenuOpen: false
  // Set when a switch/sync succeeds: the QML on disk changed, so the
  // shell has to restart for it to take effect.
  property bool gitReloadPending: false
  // The commit this shell was loaded from, latched the first time git
  // reports one. Everything else about the version is read live from a
  // subprocess, so without this the overlay can report a commit it is not
  // actually running -- which is exactly what a restart racing a switch
  // leaves behind.
  property string loadedHash: ""
  readonly property bool shellStale: root.loadedHash !== ""
    && root.gitHash !== "" && root.loadedHash !== root.gitHash

  function refreshGitInfo() {
    root.runGit(["status"], false)
  }

  // Release channels. Main and Beta are the two choices most people need;
  // Nightly is the escape hatch that opens up every working branch.
  readonly property string mainBranch: "main"
  readonly property string betaBranch: "beta"
  readonly property string nightlyBranch: "develop"

  function channelFor(branch) {
    if (root.gitDetached)
      return "version"
    if (branch === root.mainBranch)
      return "main"
    if (branch === root.betaBranch)
      return "beta"
    if (branch === root.nightlyBranch)
      return "nightly"
    return "untested"
  }

  readonly property string gitChannel: root.channelFor(root.gitBranch)

  // When the loaded commit was made, and the same for every branch you
  // could switch to, so the picker can say how far apart they are.
  property string gitDate: ""
  // Released versions that can be loaded, and whether we are sitting on
  // one. A tag checkout is detached, so the branch name is "HEAD" and the
  // tag is the only thing that names where you are.
  property var gitVersions: []
  // Each channel's declared version, so a track can be told from what a
  // branch actually carries rather than from what it is called.
  property var gitChannelVersions: ({})

  // The release track a version string belongs to: the major number.
  // 1.13.1.0 is track 1, 2.0.0.0 is track 2.
  function trackOf(version) {
    var first = String(version || "").split(".")[0]
    return first || ""
  }

  // The track this build is actually running, so the picker opens on it
  // rather than on a hardcoded 1. Detached on a tag, the tag names the
  // version; on a branch, the branch's manifest does.
  function currentTrack() {
    if (root.gitDetached && root.gitDescribe)
      return root.trackOf(String(root.gitDescribe).replace(/^v/, "")) || "1"
    return root.channelTrack(root.gitChannel) || "1"
  }

  function channelTrack(channel) {
    var branch = root.branchForChannel(channel)
    var map = root.gitChannelVersions || ({})
    return branch ? root.trackOf(map[branch] || "") : ""
  }
  property bool gitDetached: false
  property string gitDescribe: ""
  property double gitEpoch: 0
  property var gitCommits: ({})

  // Releases grouped by their main number, newest first. A flat list of
  // tags stops reading as anything once there are more than a handful;
  // 1.<main> is the only level tags exist at, since only beta cuts and
  // main releases are tagged.
  readonly property var versionTree: {
    var list = root.gitVersions || []
    var order = []
    var byMain = ({})
    for (var i = 0; i < list.length; i++) {
      var v = list[i]
      var parts = String(v.version || "").split(".")
      var main = parts.length >= 2 ? parts[0] + "." + parts[1] : "other"
      if (!byMain[main]) {
        byMain[main] = []
        order.push(main)
      }
      byMain[main].push(v)
    }
    var out = []
    for (var g = 0; g < order.length; g++)
      out.push({ title: order[g], releases: byMain[order[g]] })
    return out
  }

  function branchForChannel(channel) {
    if (channel === "main")
      return root.mainBranch
    if (channel === "beta")
      return root.betaBranch
    if (channel === "nightly")
      return root.nightlyBranch
    return ""
  }

  // "same" / "3 days newer" / "1 day older", against the loaded commit.
  // Sameness is by commit, not by clock: two branches can share a date and
  // still be different code, and a fast-forward gives them the same date
  // as well as the same commit.
  function versionAge(branch) {
    var info = branch ? (root.gitCommits || ({}))[branch] : null
    if (!info || !root.gitEpoch)
      return ""
    if (info.hash && root.gitHash && info.hash === root.gitHash)
      return "same"
    var diff = Number(info.epoch) - root.gitEpoch
    if (!diff)
      return "same date"
    var days = Math.floor(Math.abs(diff) / 86400)
    var span = days < 1 ? "hours" : (days === 1 ? "1 day" : days + " days")
    return span + (diff > 0 ? " newer" : " older")
  }

  function versionDate(branch) {
    var info = branch ? (root.gitCommits || ({}))[branch] : null
    if (!info || !info.epoch)
      return ""
    return Qt.formatDate(new Date(Number(info.epoch) * 1000), "yyyy-MM-dd")
  }

  function channelLabel(channel) {
    if (channel === "main")
      return "Main"
    if (channel === "beta")
      return "Beta"
    if (channel === "nightly")
      return "Nightly"
    if (channel === "version")
      return "Version"
    return "Untested"
  }

  // Each of the three channels is the tip of one branch, so switching is
  // one click. "Untested" is not a channel you can pick -- it is what a
  // checkout on any other branch is called, so the corner can name it
  // rather than pretend it is one of the three.
  // A tag, not a branch: plugin-git checks the tree carries the version
  // marker before loading it, so a build with no picker in it can never be
  // the thing you land on.
  function loadVersion(tag) {
    if (!tag)
      return
    root.gitError = ""
    root.switchBranch(tag)
  }

  function switchChannel(channel) {
    if (channel === "main")
      root.switchBranch(root.mainBranch)
    else if (channel === "beta")
      root.switchBranch(root.betaBranch)
    else if (channel === "nightly")
      root.switchBranch(root.nightlyBranch)
  }

  function toggleOptionsMenu() {
    root.optionsMenuOpen = !root.optionsMenuOpen
    if (root.optionsMenuOpen)
      root.branchMenuOpen = false
  }

  function toggleBranchMenu() {
    root.branchMenuOpen = !root.branchMenuOpen
    if (root.branchMenuOpen)
      root.optionsMenuOpen = false
    // Opening is the moment the branch list matters, so refresh it then
    // rather than paying for git on every overlay open.
    if (root.branchMenuOpen)
      root.refreshGitInfo()
    else
      root.gitError = ""
  }

  function checkForUpdates() {
    root.gitError = ""
    root.runGit(["fetch"], false)
  }

  function switchBranch(name) {
    if (!name)
      return
    if (name === root.gitBranch && !root.gitDetached)
      return
    root.gitError = ""
    root.runGit(["switch", String(name)], true)
  }

  function syncBranch() {
    root.gitError = ""
    root.runGit(["sync"], true)
  }

  function runGit(args, reloadOnSuccess) {
    if (root.gitBusy)
      return
    root.gitBusy = true
    root.gitReloadPending = !!reloadOnSuccess
    gitProc.command = [root.sourceDir + "/plugin-git"].concat(args)
    gitProc.running = true
  }

  function applyGitPayload(text) {
    var data = null
    try {
      data = JSON.parse(text)
    } catch (e) {
      root.gitError = "could not read git status"
      return
    }
    if (!data)
      return
    root.gitBranch = data.branch || ""
    root.gitHash = data.hash || ""
    root.gitBranches = data.branches || []
    root.gitDate = data.date || ""
    root.gitVersions = data.versions || []
    root.gitChannelVersions = data.channelVersions || ({})
    root.gitDetached = data.detached === true
    root.gitDescribe = data.describe || ""
    root.gitEpoch = Number(data.epoch) || 0
    root.gitCommits = data.commits || ({})
    root.gitDirty = data.dirty === true
    root.gitBehind = data.behind || 0
    root.gitUpdateAvailable = data.updateAvailable === true
    // syncError is soft: the switch itself succeeded, only the follow-up
    // fast-forward did not, so it must not block the reload below.
    root.gitError = data.error || data.fetchError || data.syncError || ""
    // First hash seen wins: this is the tree the running QML came from.
    if (!root.loadedHash && root.gitHash)
      root.loadedHash = root.gitHash
    // Only a clean switch/sync warrants restarting the shell; a refusal
    // leaves the checkout untouched, so there is nothing to reload.
    if (root.gitReloadPending && data.ok && !data.error)
      root.restartShell()
    root.gitReloadPending = false
  }

  // Immediate, and guarded only against a double-fire in the same moment.
  //
  // This was briefly deferred behind a timer, to stop rapid channel
  // switches launching restarts that raced the checkouts they were meant
  // to follow. That was the wrong fix twice over: the switches in that
  // incident were seconds apart, far outside any debounce window, and
  // deferring the call added a way for the restart not to happen at all
  // -- which is exactly what happened on the first sync afterwards.
  //
  // What actually protects against a stale shell is noticing one:
  // loadedHash against gitHash, above.
  property double lastRestartAt: 0

  function restartShell() {
    var now = Date.now()
    if (now - root.lastRestartAt < 1500)
      return
    root.lastRestartAt = now
    // Through a login shell: omarchy lives in /usr/share/omarchy/bin,
    // which is on the user's PATH but not necessarily on the shell
    // process's. Detached, so it survives the restart it triggers.
    Quickshell.execDetached(["bash", "-lc", "omarchy restart shell"])
  }

  Process {
    id: gitProc
    command: [root.sourceDir + "/plugin-git", "status"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        root.gitBusy = false
        root.applyGitPayload(text)
      }
    }
    onExited: function(code) {
      root.gitBusy = false
      if (code !== 0 && !root.gitError)
        root.gitError = "plugin-git failed (" + code + ")"
    }
  }

  Component.onCompleted: {
    root.refreshKeymap()
    root.refreshGitInfo()
  }

  Timer {
    id: runTimer
    interval: 120
    repeat: false
    onTriggered: {
      var script = root.sourceDir + "/run-shortcut"
      var target = root.contextAddress ? "address:" + root.contextAddress : ""
      if (root.pendingFocus)
        Quickshell.execDetached([script, "--focus", "address:" + root.pendingFocus])
      else if (root.pendingDispatcher)
        Quickshell.execDetached([script, "--dispatch", root.pendingDispatcher, root.pendingArg, target])
      else
        Quickshell.execDetached([script, root.pendingMods, root.pendingKey, target])
    }
  }

  Process {
    id: editProc
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var out = String(text || "").trim()
        if (out === "ok") {
          root.editStatus = "Saved · history committed"
          root.capturing = false
          root.refreshKeymap()
        } else {
          root.editStatus = "Reload failed · restored previous version"
          root.capturing = false
        }
      }
    }
    onExited: function(code) {
      if (code !== 0 && root.capturing)
        root.editStatus = "Edit failed · restored previous version"
      root.capturing = false
    }
  }

  function grab() {
    root.grabKeys = true
    root.requestFocus()
    if (!root.contextArmed)
      armContextTimer.restart()
  }

  Timer {
    id: grabWatch
    interval: 50
    repeat: true
    running: root.opened && !root.grabKeys && !root.launching
    onTriggered: root.grab()
  }

  Timer {
    id: armContextTimer
    interval: 180
    repeat: false
    onTriggered: {
      if (!root.opened || !root.grabKeys)
        return
      root.contextToplevel = ToplevelManager.activeToplevel
      root.contextArmed = true
    }
  }

  Connections {
    target: ToplevelManager
    function onActiveToplevelChanged() {
      if (!root.opened || !root.contextArmed || root.launching)
        return
      if (ToplevelManager.activeToplevel !== root.contextToplevel)
        root.dismiss()
    }
  }

  // Where the card belongs, in order of preference: the monitor it opened on,
  // then wherever it is already, then the focused one, then anything at all.
  // Without the last three it would sit on a screen that no longer exists --
  // scrims up, no card, no keyboard grab -- and without the first it would
  // never come home from a blip. Letting the binding read live focus instead of
  // resolving here would do both jobs and bring the pointer-chasing back for
  // the rest of the session.
  function resolveCardMonitor() {
    var screens = Quickshell.screens
    var wanted = ""
    for (var i = 0; i < screens.length && wanted === ""; i++) {
      if (screens[i].name === root.openMonitor)
        wanted = root.openMonitor
    }
    for (var j = 0; j < screens.length && wanted === ""; j++) {
      if (screens[j].name === root.cardMonitor)
        wanted = root.cardMonitor
    }
    var focused = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : ""
    for (var k = 0; k < screens.length && wanted === ""; k++) {
      if (screens[k].name === focused)
        wanted = focused
    }
    if (wanted === "" && screens.length > 0)
      wanted = screens[0].name

    if (wanted === root.cardMonitor)
      return

    root.cardMonitor = wanted
    // The card has moved to a different panel, and nothing else will ask that
    // panel's keyCatcher for focus: the grab follows the binding, but Qt item
    // focus does not, so Escape and type-to-filter would be dead until the
    // overlay was closed and opened again.
    root.requestFocus()
  }

  Connections {
    target: Quickshell
    function onScreensChanged() {
      if (root.opened)
        root.resolveCardMonitor()
    }
  }

  Connections {
    target: Hyprland
    function onFocusedMonitorChanged() {
      if (root.opened)
        root.resolveCardMonitor()
    }
  }

  function requestFocus() {
    root.focusTick++
  }

  function close() {
    root.contextArmed = false
    root.grabKeys = false
    root.opened = false
    root.branchMenuOpen = false
    root.optionsMenuOpen = false
    root.clearSolo()
  }

  function dismiss() {
    root.contextArmed = false
    root.grabKeys = false
    root.opened = false
    root.branchMenuOpen = false
    root.optionsMenuOpen = false
    root.clearSolo()
    if (root.shell && typeof root.shell.hide === "function")
      root.shell.hide(root.pluginId())
  }

  function toggle() {
    if (root.opened)
      root.dismiss()
    else
      root.open("{}")
  }

  // Filtering by key means one key, not a string of them, so a keystroke
  // replaces what is in the box rather than adding to it. Typing "gh"
  // looking for h would otherwise leave you filtering on a chord nothing
  // is bound to.
  // Armed by clicking the filter box in key mode. The next keystroke is
  // taken whole -- Return and Escape included, which is the only way to
  // filter on them, since they do other jobs the rest of the time.
  property bool filterCapturing: false

  function toggleFilterCapture() {
    root.filterCapturing = !root.filterCapturing
  }

  function isModifierKey(event) {
    return event.key === Qt.Key_Shift || event.key === Qt.Key_Control
      || event.key === Qt.Key_Alt || event.key === Qt.Key_AltGr
      || event.key === Qt.Key_Meta || event.key === Qt.Key_Super_L
      || event.key === Qt.Key_Super_R || event.key === Qt.Key_CapsLock
  }

  // The chord a captured keystroke stands for. Modifiers come along with
  // the key rather than counting as the key, so holding Super and hitting
  // K gives "Super + K" and not two captures.
  function captureChord(event) {
    var name = root.namedFilterKey(event)
    if (!name && event.key === Qt.Key_Escape)
      name = "Escape"
    if (!name && event.key >= Qt.Key_A && event.key <= Qt.Key_Z)
      name = String.fromCharCode(65 + (event.key - Qt.Key_A))
    if (!name && event.key >= Qt.Key_0 && event.key <= Qt.Key_9)
      name = String(event.key - Qt.Key_0)
    if (!name && event.text && event.text.length === 1
        && event.text.charCodeAt(0) >= 32 && event.text.charCodeAt(0) !== 127)
      name = event.text
    if (!name)
      return ""
    var parts = []
    if (event.modifiers & Qt.MetaModifier)
      parts.push("Super")
    if (event.modifiers & Qt.ControlModifier)
      parts.push("Ctrl")
    if (event.modifiers & Qt.AltModifier)
      parts.push("Alt")
    // Shift is part of the chord, not of the letter: Hyprland writes
    // "Super + Shift + B", never "Super + B" with a capital B.
    if (event.modifiers & Qt.ShiftModifier)
      parts.push("Shift")
    parts.push(name)
    return parts.join(" + ")
  }

  // What a bare named key would filter on. Letters, digits and punctuation
  // already arrive as text; these are the ones that do not.
  function namedFilterKey(event) {
    if (event.key >= Qt.Key_F1 && event.key <= Qt.Key_F12)
      return "F" + (1 + event.key - Qt.Key_F1)
    switch (event.key) {
    case Qt.Key_Return:
    case Qt.Key_Enter:     return "Return"
    case Qt.Key_Tab:
    case Qt.Key_Backtab:   return "Tab"
    case Qt.Key_Backspace: return "Backspace"
    case Qt.Key_Delete:    return "Delete"
    case Qt.Key_Insert:    return "Insert"
    case Qt.Key_Home:      return "Home"
    case Qt.Key_End:       return "End"
    case Qt.Key_PageUp:    return "PageUp"
    case Qt.Key_PageDown:  return "PageDown"
    case Qt.Key_Left:      return "Left"
    case Qt.Key_Right:     return "Right"
    case Qt.Key_Up:        return "Up"
    case Qt.Key_Down:      return "Down"
    case Qt.Key_Space:     return "Space"
    case Qt.Key_Print:     return "Print"
    }
    return ""
  }

  // Some of those keys also drive the overlay. They filter only while the
  // box is empty: the first press picks the key, and once there are
  // results the same key goes back to moving through them. Everything
  // else -- Delete, Home, the function keys -- has no other job here and
  // always filters.
  function keyDrivesOverlay(name) {
    return name === "Return" || name === "Tab" || name === "Backspace"
      || name === "Left" || name === "Right" || name === "Up" || name === "Down"
  }

  // Whether this keystroke should land in the filter rather than do its
  // usual job. Only in key mode, and never for a chord.
  function filterCapturesKey(event) {
    if (root.searchMode !== "keys" || root.chordMods(event) || (event.modifiers & Qt.ShiftModifier))
      return false
    var name = root.namedFilterKey(event)
    if (!name)
      return false
    return !root.keyDrivesOverlay(name) || !root.filterText
  }

  function appendFilter(text) {
    root.setFilter(root.searchMode === "keys"
      ? String(text)
      : root.filterText + String(text))
  }

  function setFilter(nextFilter) {
    root.filterText = nextFilter
    root.selected = 0
    root.rebuild()
  }

  function rebuild(keepSelection) {
    var keepKeys = root.selectedKeys
    var keepAction = root.selectedAction
    root.applyConfigToData()
    root.groupList = KeymapData.catalog()
    var omarchySource = (root.omarchySections && root.omarchySections.length) ? root.omarchySections : KeymapData.sections
    root.omarchyTree = KeymapData.groupedCatalog(omarchySource)
    var cols = KeymapData.columns(root.filterText)
    root.leftSections = cols.left
    root.rightSections = cols.right
    root.navItems = KeymapData.navList(root.filterText)
    if (keepSelection)
      root.selectKeys(keepKeys, keepAction)
    if (root.selected >= root.navItems.length)
      root.selected = Math.max(0, root.navItems.length - 1)
    root.syncSelection()
    if (root.opened && !keepSelection)
      root.requestFocus()
  }

  function selectSource(id) {
    root.capturing = false
    root.editStatus = ""
    root.activeSource = id || "omarchy"
    if (!root.omarchyActive)
      root.editMode = false
    root.filterText = ""
    root.selected = 0
    if (root.omarchyActive) {
      root.sheetPath = ""
      KeymapData.setSections(root.omarchySections.length ? root.omarchySections : KeymapData.sections)
      root.rebuild()
      return
    }
    if (root.appsActive) {
      root.activeLabel = ""
      root.loadAppSheets()
      return
    }
    var sheet = ""
    var label = id
    var list = root.clients
    for (var i = 0; i < list.length; i++) {
      if (list[i].class === id) {
        sheet = list[i].sheet || ""
        label = list[i].label || id
        break
      }
    }
    root.activeLabel = label
    if (!sheet) {
      KeymapData.setSections(root.emptySheetSections(label))
      root.rebuild()
      return
    }
    root.sheetPath = root.sourceDir + "/sheets/" + sheet
  }

  function appIsHidden(cls) {
    for (var i = 0; i < root.hiddenApps.length; i++) {
      if (root.hiddenApps[i] === cls)
        return true
    }
    return false
  }

  // Apps bucketed by the sheet they answer to, because that is what
  // decides their keybindings: every Chrome PWA is one "Web apps" entry.
  // Kind order follows first appearance, and the dump sorts the focused
  // window first, so the app you came from leads the list.
  // dump-keymap's label for apps with no bindings of their own; kept here
  // so the sort below and the fallback cannot drift apart.
  readonly property string noSheetKind: "No keymap sheet"

  readonly property var appTree: {
    var out = []
    var index = ({})
    var list = root.clients || []
    var only = root.workspaceFilter
    for (var i = 0; i < list.length; i++) {
      var app = list[i]
      var windows = app.windows || []
      // Filtering scopes an app to the windows it has on that workspace,
      // rather than showing the whole app because one of its windows
      // qualifies. An app with nothing there drops out entirely.
      if (only > 0) {
        var kept = []
        for (var w = 0; w < windows.length; w++) {
          if (windows[w].workspace === only)
            kept.push(windows[w])
        }
        if (!kept.length)
          continue
        var scoped = ({})
        for (var f in app)
          scoped[f] = app[f]
        scoped.windows = kept
        scoped.count = kept.length
        app = scoped
      }
      var kind = app.kind || root.noSheetKind
      if (index[kind] === undefined) {
        index[kind] = out.length
        out.push({ title: kind, apps: [], hidden: true })
      }
      // Apps keep their windows so the tree can nest them: an app with
      // more than one window becomes a branch of its own.
      var entry = out[index[kind]]
      entry.apps.push(app)
      // A kind is hidden only when every app under it is, so the row
      // itself always survives to offer a way back.
      if (!root.appIsHidden(app.class))
        entry.hidden = false
    }
    // Apps with no keymap are the least useful branch of a keymap overlay,
    // so they sit last however recently one of them was focused.
    var kinds = []
    var noSheet = []
    for (var k = 0; k < out.length; k++) {
      if (out[k].title === root.noSheetKind)
        noSheet.push(out[k])
      else
        kinds.push(out[k])
    }
    return kinds.concat(noSheet)
  }

  readonly property var allAppClasses: {
    var out = []
    var list = root.clients || []
    for (var i = 0; i < list.length; i++)
      out.push(list[i].class)
    return out
  }

  readonly property bool allAppsHidden: {
    var list = root.clients || []
    if (!list.length)
      return false
    for (var i = 0; i < list.length; i++) {
      if (!root.appIsHidden(list[i].class))
        return false
    }
    return true
  }

  readonly property bool allGroupsHidden: {
    var list = root.groupList
    if (!list || !list.length)
      return false
    for (var i = 0; i < list.length; i++) {
      if (!list[i].hidden)
        return false
    }
    return true
  }

  function setAppsVisible(classes, show) {
    var set = ({})
    for (var i = 0; i < classes.length; i++)
      set[classes[i]] = true
    var next = []
    for (var j = 0; j < root.hiddenApps.length; j++) {
      if (!set[root.hiddenApps[j]])
        next.push(root.hiddenApps[j])
    }
    if (!show) {
      for (var k = 0; k < classes.length; k++)
        next.push(classes[k])
    }
    root.hiddenApps = next
    root.saveConfig()
  }

  function toggleApp(cls) {
    var next = []
    var hiding = !root.appIsHidden(cls)
    for (var i = 0; i < root.hiddenApps.length; i++) {
      if (root.hiddenApps[i] !== cls)
        next.push(root.hiddenApps[i])
    }
    if (hiding)
      next.push(cls)
    root.hiddenApps = next
    root.saveConfig()
  }

  function showAllApps() {
    root.hiddenApps = []
    root.saveConfig()
  }

  function groupIsHidden(title) {
    for (var i = 0; i < root.hiddenGroups.length; i++) {
      if (root.hiddenGroups[i] === title)
        return true
    }
    return false
  }

  function toggleGroup(title) {
    root.preSoloHidden = null
    var next = []
    var hiding = !root.groupIsHidden(title)
    for (var i = 0; i < root.hiddenGroups.length; i++) {
      if (root.hiddenGroups[i] !== title)
        next.push(root.hiddenGroups[i])
    }
    if (hiding)
      next.push(title)
    root.hiddenGroups = next
    root.saveConfig()
  }

  // Snapshot of hiddenGroups taken before the first solo, so closing the
  // overlay can put the user's real group settings back.
  property var preSoloHidden: null

  // Click a branch in the tree to show only that branch: every Omarchy
  // group outside `titles` is hidden, so the board shows just the one
  // area/group you picked. This is a *view* filter — deliberately not
  // written to the config, and undone on close, so a stray click cannot
  // leave the keymap permanently mostly-hidden.
  function soloGroups(titles) {
    if (root.preSoloHidden === null)
      root.preSoloHidden = root.hiddenGroups.slice()
    var keep = {}
    for (var i = 0; i < titles.length; i++)
      keep[titles[i]] = true
    var next = []
    // omarchyTree already holds every group, bucketed by area.
    var areas = root.omarchyTree || []
    for (var a = 0; a < areas.length; a++) {
      var groups = areas[a].groups || []
      for (var g = 0; g < groups.length; g++) {
        if (!keep[groups[g].title])
          next.push(groups[g].title)
      }
    }
    root.hiddenGroups = next
    root.applyConfigToData()
    root.rebuild()
  }

  function clearSolo() {
    if (root.preSoloHidden === null)
      return
    root.hiddenGroups = root.preSoloHidden.slice()
    root.preSoloHidden = null
    root.applyConfigToData()
    root.rebuild()
  }

  function setGroupsVisible(titles, show) {
    root.preSoloHidden = null
    var set = {}
    for (var i = 0; i < titles.length; i++)
      set[titles[i]] = true
    var next = []
    for (var j = 0; j < root.hiddenGroups.length; j++) {
      if (!set[root.hiddenGroups[j]])
        next.push(root.hiddenGroups[j])
    }
    if (!show) {
      for (var k = 0; k < titles.length; k++)
        next.push(titles[k])
    }
    root.hiddenGroups = next
    root.saveConfig()
  }

  function modifierMode(name) {
    if (name === "Super") return root.modSuper
    if (name === "Shift") return root.modShift
    if (name === "Ctrl") return root.modCtrl
    if (name === "Alt") return root.modAlt
    return "any"
  }

  function cycleModifier(name) {
    var cur = root.modifierMode(name)
    var next = cur === "any" ? "must" : (cur === "must" ? "hide" : "any")
    if (name === "Super") root.modSuper = next
    else if (name === "Shift") root.modShift = next
    else if (name === "Ctrl") root.modCtrl = next
    else if (name === "Alt") root.modAlt = next
    root.saveConfig()
  }

  function setAllModifiers(mode) {
    var next = mode === "must" || mode === "hide" ? mode : "any"
    root.modSuper = next
    root.modShift = next
    root.modCtrl = next
    root.modAlt = next
    root.saveConfig()
  }

  function cycleChipStyle() {
    root.chipStyle = root.chipStyle === "full" ? "short"
      : (root.chipStyle === "short" ? "icons" : "full")
    root.saveConfig()
  }

  function cycleRowLayout() {
    root.rowLayout = root.rowLayout === "keys" ? "action" : "keys"
    root.saveConfig()
  }

  function cycleSortBy() {
    root.sortBy = root.sortBy === "section" ? "action"
      : (root.sortBy === "action" ? "key" : "section")
    root.saveConfig()
  }

  function setFontScale(value) {
    var next = Math.max(0.6, Math.min(1.4, Math.round(Number(value) * 20) / 20))
    if (next === root.fontScale)
      return
    root.fontScale = next
    root.saveConfig()
  }


  // Everything the options panel can change, back to how it ships - the
  // filters and hidden branches included, since those are the settings
  // most likely to leave the board looking broken.
  function restoreDefaults() {
    root.chipStyle = "icons"
    root.rowLayout = "action"
    root.sortBy = "key"
    root.grouping = "topic"
    root.searchMode = "all"
    root.keyboardType = "windows"
    root.iconBorders = false
    root.fontScale = 1.0
    root.modSuper = "any"
    root.modShift = "any"
    root.modCtrl = "any"
    root.modAlt = "any"
    root.hiddenGroups = []
    root.hiddenApps = []
    root.preSoloHidden = null
    root.doubleTap = true
    root.holdEnabled = true
    root.holdSeconds = 5
    root.filterText = ""
    var hadSuperK = root.superK
    root.superK = true
    root.saveConfig()
    if (!hadSuperK)
      root.reloadHyprland()
  }

  // Super+K is bound in hyprland.lua, which only re-reads omarkeys.json
  // when Hyprland reloads its config, so flipping this has to ask for one.
  function toggleDoubleTap() {
    if (root.isLastOpener(root.doubleTap))
      return
    root.doubleTap = !root.doubleTap
    root.saveConfig()
  }

  // Hold lives in hyprland.lua like Super+K does, so turning it off has to
  // reach Hyprland the same way.
  function toggleHoldEnabled() {
    if (root.isLastOpener(root.holdEnabled))
      return
    root.holdEnabled = !root.holdEnabled
    root.saveConfig()
    root.reloadHyprland()
  }

  function setSuperK(on) {
    var next = !!on
    if (root.superK === next)
      return
    if (!next && root.isLastOpener(root.superK))
      return
    root.superK = next
    root.saveConfig()
    root.reloadHyprland()
  }

  // Debounced, and deliberately after the write: the config file has to be
  // on disk before hyprland.lua reads it back, and a run of clicks should
  // cost one reload rather than one each.
  function reloadHyprland() {
    hyprReloadTimer.restart()
  }

  function cycleKeyboardType() {
    root.keyboardType = root.keyboardType === "text" ? "mac"
      : (root.keyboardType === "mac" ? "windows"
      : (root.keyboardType === "windows" ? "omarchy" : "text"))
    root.saveConfig()
  }

  function cycleGrouping() {
    root.grouping = root.grouping === "topic" ? "keytype"
      : (root.grouping === "keytype" ? "off" : "topic")
    root.saveConfig()
  }

  function toggleIconBorders() {
    root.iconBorders = !root.iconBorders
    root.saveConfig()
  }

  function cycleSearchMode() {
    root.searchMode = root.searchMode === "all" ? "keys"
      : (root.searchMode === "keys" ? "action" : "all")
    root.saveConfig()
  }

  function setAllGroupsVisible(show) {
    root.preSoloHidden = null
    if (show) {
      root.hiddenGroups = []
    } else {
      var next = []
      var list = root.groupList
      for (var i = 0; i < list.length; i++)
        next.push(list[i].title)
      root.hiddenGroups = next
    }
    root.saveConfig()
  }

  function focusGroup(title) {
    if (root.groupIsHidden(title))
      root.toggleGroup(title)
    for (var i = 0; i < root.navItems.length; i++) {
      if (root.navItems[i].sectionTitle === title) {
        root.selected = i
        root.syncSelection()
        return
      }
    }
  }

  function syncSelection() {
    var item = root.navItems[root.selected]
    if (!item) {
      root.selectedKeys = ""
      root.selectedAction = ""
      root.selectedSectionTitle = ""
      return
    }
    root.selectedKeys = item.keys
    root.selectedAction = item.action
    root.selectedSectionTitle = item.sectionTitle || ""
  }

  function moveSelection(delta) {
    if (!root.navItems.length)
      return
    var n = root.navItems.length
    root.selected = (root.selected + delta + n) % n
    root.syncSelection()
  }

  function jumpSection(number) {
    var starts = KeymapData.sectionStarts(root.navItems)
    var idx = number - 1
    if (number === 0)
      idx = 9
    if (idx < 0 || idx >= starts.length)
      return
    root.selected = starts[idx]
    root.syncSelection()
  }

  function jumpNeighborSection(delta) {
    var starts = KeymapData.sectionStarts(root.navItems)
    if (!starts.length)
      return
    var current = 0
    for (var i = 0; i < starts.length; i++) {
      if (starts[i] <= root.selected)
        current = i
    }
    var next = current + delta
    if (next < 0)
      next = starts.length - 1
    if (next >= starts.length)
      next = 0
    root.selected = starts[next]
    root.syncSelection()
  }

  function selectKeys(keys, action) {
    for (var i = 0; i < root.navItems.length; i++) {
      if (root.navItems[i].keys === keys && root.navItems[i].action === action) {
        root.selected = i
        root.syncSelection()
        return
      }
    }
  }

  function toHyprChord(keys) {
    var parts = KeymapData.splitKeys(keys)
    var out = []
    for (var i = 0; i < parts.length; i++) {
      var p = parts[i]
      if (p === "Super") out.push("SUPER")
      else if (p === "Shift") out.push("SHIFT")
      else if (p === "Ctrl" || p === "Control") out.push("CTRL")
      else if (p === "Alt") out.push("ALT")
      else out.push(String(p).toUpperCase())
    }
    return out.join(" + ")
  }

  function qtKeyName(event) {
    if (event.key >= Qt.Key_A && event.key <= Qt.Key_Z)
      return String.fromCharCode(65 + (event.key - Qt.Key_A))
    if (event.key >= Qt.Key_0 && event.key <= Qt.Key_9)
      return String(event.key - Qt.Key_0)
    if (event.key === Qt.Key_Space) return "SPACE"
    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) return "RETURN"
    if (event.key === Qt.Key_Tab) return "TAB"
    if (event.key === Qt.Key_Backspace) return "BACKSPACE"
    if (event.key === Qt.Key_Delete) return "DELETE"
    if (event.key === Qt.Key_Escape) return "ESCAPE"
    if (event.key === Qt.Key_Print) return "PRINT"
    if (event.key === Qt.Key_Home) return "HOME"
    if (event.key === Qt.Key_End) return "END"
    if (event.key === Qt.Key_Left) return "LEFT"
    if (event.key === Qt.Key_Right) return "RIGHT"
    if (event.key === Qt.Key_Up) return "UP"
    if (event.key === Qt.Key_Down) return "DOWN"
    if (event.key === Qt.Key_Comma) return "COMMA"
    if (event.key === Qt.Key_Period) return "PERIOD"
    if (event.key === Qt.Key_Minus) return "MINUS"
    if (event.key === Qt.Key_Equal) return "EQUAL"
    if (event.key === Qt.Key_Slash) return "SLASH"
    return ""
  }

  function eventToHyprChord(event) {
    if (root.isSuperKey(event) && !(event.modifiers & (Qt.ShiftModifier | Qt.ControlModifier | Qt.AltModifier)))
      return ""
    var key = root.qtKeyName(event)
    if (!key || key === "ESCAPE")
      return ""
    var mods = []
    if (event.modifiers & Qt.MetaModifier) mods.push("SUPER")
    if (event.modifiers & Qt.ShiftModifier) mods.push("SHIFT")
    if (event.modifiers & Qt.ControlModifier) mods.push("CTRL")
    if (event.modifiers & Qt.AltModifier) mods.push("ALT")
    if (!mods.length && !key)
      return ""
    return (mods.length ? mods.join(" + ") + " + " : "") + key
  }

  function startCapture(keys, action) {
    if (!root.omarchyActive || !root.editMode)
      return
    if (!KeymapData.isRunnable(keys)) {
      root.editStatus = "That row cannot be remapped"
      return
    }
    root.captureOldKeys = keys
    root.captureAction = action
    root.capturing = true
    root.editStatus = "Press the new shortcut for “" + action + "”"
  }

  function applyCapture(newHypr) {
    if (!root.capturing || !newHypr)
      return
    var oldHypr = root.toHyprChord(root.captureOldKeys)
    if (!oldHypr)
      return
    root.editStatus = "Saving…"
    editProc.command = [
      root.sourceDir + "/apply-edit", "remap",
      "--old-keys", oldHypr,
      "--old-action", root.captureAction,
      "--new-keys", newHypr,
      "--action", root.captureAction
    ]
    editProc.running = false
    editProc.running = true
  }

  function setEditMode(on) {
    if (!root.omarchyActive)
      on = false
    root.editMode = !!on
    root.capturing = false
    if (root.editMode)
      root.editStatus = "Edit: select a command, then press its new chord"
    else
      root.editStatus = ""
  }

  // Double-click a workspace branch to go to it.
  //
  // The same call Omarchy's own "Switch to workspace N" bind makes, and
  // for the same reason the overlay dispatches actions instead of
  // replaying chords: with the Lua config provider, `hyprctl dispatch`
  // parses its argument as Lua, so a bare `dispatch workspace 3` becomes
  // `hl.dispatch(workspace 3)` and dies with a syntax error.
  function focusWorkspace(id) {
    if (!id || root.launching)
      return
    root.pendingDispatcher = "lua"
    root.pendingArg = 'hl.dsp.focus({ workspace = "' + id + '" })'
    root.pendingFocus = ""
    root.launching = true
    root.dismiss()
    runTimer.restart()
  }

  // The workspace an app sits on, or 0 when its windows disagree. An app
  // with windows in two places has no single one to label, and guessing
  // one would be worse than showing none.
  // Whether an app has any window on the given workspace. The filter asks
  // this of the board the same way appTree asks it of the tree.
  function appOnWorkspace(app, ws) {
    var windows = (app && app.windows) || []
    for (var i = 0; i < windows.length; i++) {
      if ((windows[i].workspace || 0) === ws)
        return true
    }
    return false
  }

  function appWorkspace(app) {
    var windows = (app && app.windows) || []
    if (!windows.length)
      return 0
    var id = windows[0].workspace || 0
    for (var i = 1; i < windows.length; i++) {
      if ((windows[i].workspace || 0) !== id)
        return 0
    }
    return id
  }

  function setWorkspaceFilter(id) {
    root.workspaceFilter = Number(id) || 0
  }

  function focusWindow(address) {
    if (!address || root.launching)
      return
    root.pendingFocus = address
    root.pendingDispatcher = ""
    root.pendingArg = ""
    root.pendingMods = ""
    root.pendingKey = ""
    root.launching = true
    root.dismiss()
    runTimer.restart()
  }

  function executeSelected() {
    if (root.editMode) {
      var editItem = root.navItems[root.selected]
      if (editItem)
        root.startCapture(editItem.keys, editItem.action)
      return
    }
    if (root.launching || !root.opened)
      return
    var item = root.navItems[root.selected]
    if (!item)
      return
    // Dimmed rows are dimmed because we cannot issue them; running the
    // chord anyway would just close the overlay and do nothing.
    if (item.runnable === false)
      return
    // Prefer the binding's own action. Replaying the chord only works for
    // app sheet rows, which are the app's shortcuts rather than Hyprland
    // binds - a synthetic key sent to a window never reaches Hyprland's
    // bind matcher, so dispatching by chord silently did nothing.
    if (item.dispatcher) {
      root.pendingFocus = ""
      root.pendingDispatcher = item.dispatcher
      root.pendingArg = item.dispatchArg || ""
      root.pendingMods = ""
      root.pendingKey = ""
      root.launching = true
      root.dismiss()
      runTimer.restart()
      return
    }
    var sc = item.shortcut
    if (!sc || !sc.key)
      sc = KeymapData.shortcut(item.keys)
    if (!sc || !sc.key)
      return
    root.pendingFocus = ""
    root.pendingDispatcher = ""
    root.pendingArg = ""
    root.pendingMods = sc.mods || ""
    root.pendingKey = sc.key
    root.launching = true
    root.dismiss()
    runTimer.restart()
  }

  // A single click only moves the highlight. Running a command is a
  // double-click (or Enter): a stray click on the way to reading a row
  // should not fire a shortcut and close the overlay under you.
  function selectRow(keys, action) {
    root.selectKeys(keys, action)
  }

  function activateRow(keys, action) {
    root.selectKeys(keys, action)
    if (root.editMode)
      root.startCapture(keys, action)
    else
      root.executeSelected()
  }

  function isSuperKey(event) {
    return event.key === Qt.Key_Meta
        || event.key === Qt.Key_Super_L
        || event.key === Qt.Key_Super_R
  }

  function chordMods(event) {
    return event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier)
  }

  function handleKey(event) {
    if (root.capturing) {
      if (event.key === Qt.Key_Escape) {
        root.capturing = false
        root.editStatus = "Capture cancelled"
        event.accepted = true
        return
      }
      var chord = root.eventToHyprChord(event)
      if (chord) {
        root.applyCapture(chord)
        event.accepted = true
      } else {
        event.accepted = true
      }
      return
    }
    // Armed capture runs ahead of every control key, or Escape and Return
    // would never reach it.
    if (root.filterCapturing) {
      if (root.isModifierKey(event))
        return
      var captured = root.captureChord(event)
      if (captured) {
        root.filterCapturing = false
        root.setFilter(captured)
      }
      event.accepted = true
      return
    }

    if (event.key === Qt.Key_Escape) {
      if (root.branchMenuOpen || root.optionsMenuOpen) {
        root.branchMenuOpen = false
        root.optionsMenuOpen = false
      }
      else if (root.filterText)
        root.setFilter("")
      else
        root.dismiss()
      event.accepted = true
    } else if (event.key === Qt.Key_W
        && (event.modifiers & Qt.MetaModifier)
        && !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.ShiftModifier))) {
      root.dismiss()
      event.accepted = true
    } else if (root.filterCapturesKey(event)) {
      root.appendFilter(root.namedFilterKey(event))
      event.accepted = true
    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
      root.executeSelected()
      event.accepted = true
    } else if (event.key === Qt.Key_Down) {
      root.moveSelection(1)
      event.accepted = true
    } else if (event.key === Qt.Key_Up) {
      root.moveSelection(-1)
      event.accepted = true
    } else if (event.key === Qt.Key_Home) {
      if (root.navItems.length) {
        root.selected = 0
        root.syncSelection()
      }
      event.accepted = true
    } else if (event.key === Qt.Key_End) {
      if (root.navItems.length) {
        root.selected = root.navItems.length - 1
        root.syncSelection()
      }
      event.accepted = true
    } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab) {
      root.jumpNeighborSection(1)
      event.accepted = true
    } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Backtab) {
      root.jumpNeighborSection(-1)
      event.accepted = true
    } else if ((event.modifiers & Qt.ControlModifier)
        && !(event.modifiers & (Qt.AltModifier | Qt.MetaModifier | Qt.ShiftModifier))) {
      var jump = -1
      if (event.key >= Qt.Key_1 && event.key <= Qt.Key_9)
        jump = event.key - Qt.Key_0
      else if (event.key === Qt.Key_0)
        jump = 0
      else if (event.key >= Qt.Key_Keypad1 && event.key <= Qt.Key_Keypad9)
        jump = event.key - Qt.Key_Keypad0
      else if (event.key === Qt.Key_Keypad0)
        jump = 0
      if (jump >= 0) {
        root.jumpSection(jump)
        event.accepted = true
      }
    }
    if (event.accepted)
      return
    if (root.isSuperKey(event)) {
      event.accepted = true
    } else if (Util.editsFilter(event, root.filterText)) {
      root.setFilter(Util.editedFilter(event, root.filterText))
      event.accepted = true
    } else if (event.text && event.text.length === 1 && event.text.charCodeAt(0) >= 32 && event.text.charCodeAt(0) !== 127
        && !root.chordMods(event)) {
      root.appendFilter(event.text)
      event.accepted = true
    } else if (!root.chordMods(event) && event.key >= Qt.Key_A && event.key <= Qt.Key_Z) {
      var letter = String.fromCharCode(65 + (event.key - Qt.Key_A))
      if (!(event.modifiers & Qt.ShiftModifier))
        letter = letter.toLowerCase()
      root.appendFilter(letter)
      event.accepted = true
    } else if (!root.chordMods(event) && event.key >= Qt.Key_0 && event.key <= Qt.Key_9) {
      root.appendFilter(String(event.key - Qt.Key_0))
      event.accepted = true
    } else if (event.key === Qt.Key_Space && !root.chordMods(event)) {
      root.appendFilter(" ")
      event.accepted = true
    }
  }

  Variants {
    model: Quickshell.screens

    delegate: Component {
      PanelWindow {
        id: panel
        required property var modelData
        screen: modelData
        visible: root.opened
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        WlrLayershell.namespace: "romills-omarkeys"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: (root.grabKeys && panel.hasKeyboard)
          ? WlrKeyboardFocus.Exclusive
          : WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore

        // Sized against the display rather than a fixed cap: 1100x760 was
        // barely half of a 2048x1152 screen and under half of a 2560x1440
        // one, which is why the board had to scroll so much. The caps stop
        // it sprawling on an ultrawide.
        readonly property int cardWidth: Math.min(Style.space(1700),
          Math.max(Style.space(900), Math.round(width * 0.92) - Style.gapsOut * 2))
        readonly property int cardHeight: Math.min(Style.space(1100),
          Math.max(Style.space(620), Math.round(height * 0.90) - Style.gapsOut * 2))
        readonly property bool hasKeyboard: !!modelData && root.cardMonitor !== ""
          && root.cardMonitor === modelData.name

        function takeFocus() {
          if (root.opened && panel.hasKeyboard)
            keyCatcher.forceActiveFocus()
        }

        Connections {
          target: root
          function onGrabKeysChanged() {
            if (root.grabKeys)
              Qt.callLater(panel.takeFocus)
          }
          function onOpenedChanged() {
            if (root.opened)
              Qt.callLater(panel.takeFocus)
          }
          function onFocusTickChanged() {
            if (root.opened)
              Qt.callLater(panel.takeFocus)
          }
        }

        Connections {
          target: Hyprland
          function onFocusedMonitorChanged() {
            if (root.opened && root.grabKeys && panel.hasKeyboard)
              Qt.callLater(panel.takeFocus)
          }
        }

        Rectangle {
          anchors.fill: parent
          color: root.scrim
        }

        MouseArea {
          anchors.fill: parent
          onClicked: root.dismiss()
        }

        // The scrim covers every screen; the card belongs to the one the
        // overlay was opened on. A second display should not get a copy of the
        // keymap nobody is looking at.
        //
        // Keeping a panel on every screen is what makes that safe. The overlay
        // stays under the pointer wherever it goes, so crossing to another
        // monitor does not activate a window there and trip the activeToplevel
        // dismissal above. Explicit activation and output reconfiguration
        // still can.
        BorderSurface {
          id: card
          visible: panel.hasKeyboard
          width: panel.cardWidth
          height: panel.cardHeight
          radius: root.cornerRadius
          anchors.centerIn: parent
          color: root.background
          borderSpec: root.borderSpec
          padding: root.contentMargin

          MouseArea { anchors.fill: parent; onClicked: {} }

          Shortcut {
            sequences: ["Return", "Enter"]
            enabled: root.opened && root.grabKeys && panel.hasKeyboard
            onActivated: root.executeSelected()
          }

          Item {
            id: keyCatcher
            anchors.fill: parent
            focus: root.grabKeys && panel.hasKeyboard
            Keys.priority: Keys.BeforeItem
            Keys.onPressed: function(event) { root.handleKey(event) }
            Keys.onReleased: function(event) {
              if (root.isSuperKey(event))
                event.accepted = true
            }

            Column {
              id: body
              anchors.fill: parent
              anchors.topMargin: card.contentTopInset
              anchors.rightMargin: card.contentRightInset
              anchors.bottomMargin: card.contentBottomInset
              anchors.leftMargin: card.contentLeftInset
              spacing: Style.spacing.md

              Item {
                width: parent.width
                height: Math.max(Style.space(28), headerLabel.implicitHeight)

                Text {
                  id: headerLabel
                  anchors.left: parent.left
                  anchors.verticalCenter: parent.verticalCenter
                  anchors.right: hintLabel.left
                  anchors.rightMargin: Style.spacing.md
                  text: root.filterText || "OmarKEYS"
                  textFormat: Text.PlainText
                  color: root.foreground
                  opacity: root.filterText ? 1 : 0.58
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.heading
                  elide: Text.ElideRight
                }

                Text {
                  id: hintLabel
                  anchors.right: parent.right
                  anchors.verticalCenter: parent.verticalCenter
                  text: "↑↓ command · Ctrl+1–9 window · type to search · Enter run"
                  textFormat: Text.PlainText
                  color: root.foreground
                  opacity: 0.72
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                }
              }

              Row {
                id: mainRow
                width: parent.width
                height: parent.height - headerLabel.parent.height - body.spacing
                spacing: Style.spacing.md

                KeymapSidebar {
                  id: sideBar
                  host: root
                  height: parent.height
                }

                KeymapBoard {
                  id: listFlick
                  host: root
                  width: parent.width - sideBar.width - mainRow.spacing
                  height: parent.height
                }
              }

            }
          }

          Text {
            id: buildInfo
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: Style.spacing.sm
            visible: !!(root.gitBranch || root.gitHash)
            textFormat: Text.PlainText
            // Says what it is before it says which one. Unlabelled, a bare
            // "Nightly @ 21d223c" in a corner reads as a build stamp
            // rather than something you can click and change.
            //
            // Then the channel, which is the part most people care about.
            // The branch name only adds information on Untested, where it
            // is not implied by the channel.
            text: (root.branchMenuOpen ? "▾ " : "▴ ")
              + "Version: "
              + root.channelLabel(root.gitChannel)
              + (root.gitChannel === "version" && root.gitDescribe
                ? " · " + root.gitDescribe
                : (root.gitChannel === "untested" && root.gitBranch
                  ? " · " + root.gitBranch : ""))
              + (root.gitHash ? " @ " + root.gitHash : "")
              + (root.shellStale ? "  · restart to load" : "")
              + (root.gitUpdateAvailable ? " •" : "")
            color: root.gitUpdateAvailable ? root.chipFg : root.foreground
            opacity: buildInfoArea.containsMouse || root.branchMenuOpen ? 0.9 : 0.35
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption

            MouseArea {
              id: buildInfoArea
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.toggleBranchMenu()
            }
          }


          KeymapOptionsMenu {
            id: optionsMenu
            host: root
            visible: root.optionsMenuOpen
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.leftMargin: Style.spacing.sm
            // Just above the "Other Options" link, which sits inside the
            // tree's border at the foot of the sidebar now.
            anchors.bottomMargin: card.contentBottomInset
              + sideBar.optionsLinkHeight + Style.space(8)
            // All the room there is above it; past that the popup scrolls
            // rather than overflow.
            maxHeight: Math.max(Style.space(280),
              card.height - optionsMenu.anchors.bottomMargin - Style.space(20))
          }

          KeymapBranchMenu {
            host: root
            visible: root.branchMenuOpen
            anchors.right: parent.right
            anchors.bottom: buildInfo.top
            anchors.rightMargin: Style.spacing.sm
            anchors.bottomMargin: Style.space(4)
          }
        }
      }
    }
  }
}
