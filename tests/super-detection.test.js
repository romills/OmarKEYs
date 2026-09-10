const { test } = require("node:test")
const assert = require("node:assert/strict")
const { spawnSync } = require("node:child_process")
const path = require("node:path")

// hyprland.lua runs inside Hyprland's own Lua config, so its Super detection
// cannot be exercised from node: there is no `hl` here to stand it up against.
// super-detection.test.lua drives the real handler against a stub, and this
// wrapper runs it so `node --test tests/*.test.js` -- the command AGENTS.md
// documents -- covers the Lua side too, rather than leaving a suite nobody
// runs unless they read the file.
const harness = path.join(__dirname, "super-detection.test.lua")

// Whichever interpreter is on the machine. Omarchy ships lua, but a checkout
// on a box without one should skip rather than fail: the suite is about the
// plugin, not about what the contributor has installed.
function luaInterpreter() {
  for (const candidate of ["lua5.4", "lua", "luajit"]) {
    const probe = spawnSync(candidate, ["-v"], { stdio: "ignore" })
    if (!probe.error && probe.status === 0) return candidate
  }
  return null
}

test("Super is found wherever the keymap put it", (t) => {
  const lua = luaInterpreter()
  if (!lua) {
    t.skip("no lua interpreter on PATH")
    return
  }

  const run = spawnSync(lua, [harness], { encoding: "utf8" })
  // The harness names each case it pins, so hand its own output to the
  // assertion rather than reporting a bare exit code.
  assert.equal(run.status, 0, `\n${run.stdout}${run.stderr}`)
})
