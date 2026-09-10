-- Super detection tests for hyprland.lua.
--
-- Driven from tests/super-detection.test.js so `node --test tests/*.test.js`
-- covers it; run it directly with `lua5.4 tests/super-detection.test.lua` to
-- read the case names. Pure Lua, no dependencies.
--
-- Two things about the key handler are easy to get wrong, and both are pinned
-- here because the runtime is otherwise the only thing that catches them.
--
-- The first is the namespace. input.keyboard.key reports XKB keycodes, not
-- evdev ones: the event bridge pushes keyEvent.keycode + 8. So the codes below
-- are XKB, with the evdev key each one means:
--   xkb 64  = evdev 56  KEY_LEFTALT   Command on a Mac board, altwin:swap_lalt_lwin
--   xkb 37  = evdev 29  KEY_LEFTCTRL
--   xkb 38  = evdev 30  KEY_A
--   xkb 133 = evdev 125 KEY_LEFTMETA  an ordinary Super
--   xkb 125 = evdev 117 KEY_KPEQUAL   a keypad key, and not Super at all
--
-- The second is the ordering. Hyprland runs the Lua handler before the keybind
-- manager records the press, so hl.is_key_down() answers about the state before
-- the current event. press() and release() below reproduce that: the handler
-- runs first, and only then does the pressed set change. A harness that updated
-- the state first would pass against code that cannot work.

-- Default to the hyprland.lua beside this tests/ directory. OMARKEYS_LUA points
-- somewhere else, which is how the pre-fix file is checked to still fail.
local HERE = (arg and arg[0] and arg[0]:match("^(.*)[/\\][^/\\]*$")) or "."
local PLUGIN = os.getenv("OMARKEYS_LUA") or (HERE .. "/../hyprland.lua")

-- A Mac-layout board: Command sits on KEY_LEFTALT and types Super_L, which is
-- the whole case under test. The rest are ordinary keys that must stay ordinary.
local MAC = {
  [64] = "Super_L",
  [133] = "Alt_L",
  [37] = "Control_L",
  [38] = "a",
  [125] = "equal",
}

-- An ordinary board. The attribution cases need a real Super that is NOT the
-- key under test, and under MAC the 133 position types Alt_L, so a sequence
-- written against MAC never puts Super_L down at all and passes for the wrong
-- reason.
local PC = {
  [133] = "Super_L",
  [37] = "Control_L",
  [38] = "a",
}

-- An input method (fcitx5, ibus) registers its own virtual keyboard and
-- re-emits what you press, so Hyprland delivers one physical press twice.
-- Confirmed on hardware: a single tap logged two state=1 events and two
-- state=0. Every case runs both ways, because the echo is invisible while the
-- Super table is seeded and fatal once it is not.
local echo = false

local keymap = {}
local pressed = {}
local timers = {}
local clock = 0
local dispatched = {}
local key_handler = nil

local function reset(map, echoing)
  keymap = map
  echo = echoing == true
  pressed = {}
  timers = {}
  clock = 0
  dispatched = {}
end

_G.hl = {
  is_key_down = function(key)
    return pressed[key] == true
  end,
  timer = function(fn, opts)
    local timer = { at = clock + opts.timeout, fn = fn, enabled = true }
    table.insert(timers, timer)
    return {
      set_enabled = function(_, value)
        timer.enabled = value
      end,
    }
  end,
  dispatch = function(command)
    table.insert(dispatched, command)
  end,
  dsp = {
    exec_cmd = function(command)
      return command
    end,
    window = {
      close = function()
        return "close"
      end,
    },
  },
  on = function(event, cb)
    if event == "input.keyboard.key" then
      key_handler = cb
    end
  end,
  unbind = function() end,
  layer_rule = function() end,
}

_G.o = { bind = function() end }

-- Run every timer due by now, earliest first, so a probe scheduled inside
-- another timer's callback still fires in order.
local function advance(ms)
  local target = clock + ms
  while true do
    local next_timer, next_index = nil, nil
    for index, timer in ipairs(timers) do
      if timer.enabled and timer.at <= target and (not next_timer or timer.at < next_timer.at) then
        next_timer = timer
        next_index = index
      end
    end
    if not next_timer then
      break
    end
    table.remove(timers, next_index)
    clock = next_timer.at
    next_timer.fn()
  end
  clock = target
end

-- Handler first, pressed set second. This is the ordering the fix turns on.
-- The echo arrives after the state has settled, which is what the hardware log
-- shows: the second copy of a press already sees Super down.
local function press(code)
  key_handler(code, 0, 1)
  if keymap[code] then
    pressed[keymap[code]] = true
  end
  if echo then
    key_handler(code, 0, 1)
  end
end

local function release(code)
  key_handler(code, 0, 0)
  if keymap[code] then
    pressed[keymap[code]] = nil
  end
  if echo then
    key_handler(code, 0, 0)
  end
end

local function summoned()
  for _, command in ipairs(dispatched) do
    if tostring(command):match("shell summon") then
      return true
    end
  end
  return false
end

local failures = 0

local function check(name, got, want)
  if got == want then
    print("  ok   " .. name)
    return
  end
  failures = failures + 1
  print(string.format("  FAIL %s\n         overlay opened: %s, expected: %s", name, tostring(got), tostring(want)))
end

-- read_config() reads $HOME/.config/omarchy/omarkeys.json. Point HOME at an
-- empty directory so these run against the defaults rather than whoever's
-- settings happen to be on the machine.
local HOME = (os.getenv("TMPDIR") or "/tmp") .. "/omarkeys-test-home"
os.execute("mkdir -p '" .. HOME .. "/.config/omarchy'")

local original_getenv = os.getenv
os.getenv = function(name)
  if name == "HOME" then
    return HOME
  end
  return original_getenv(name)
end

local function load_plugin()
  dofile(PLUGIN)
end

-- The two gestures the overlay advertises, on a board that puts Super somewhere
-- other than the META pair.
reset(MAC)
load_plugin()
press(64)
advance(2)
advance(5000)
check("holding Command opens the overlay", summoned(), true)
release(64)

reset(MAC)
load_plugin()
press(64)
advance(2)
release(64)
advance(50)
check("one tap of Command leaves the overlay closed", summoned(), false)
press(64)
advance(2)
release(64)
advance(2)
check("double-tapping Command opens the overlay", summoned(), true)

reset(MAC)
load_plugin()
press(64)
advance(2)
release(64)
advance(900)
press(64)
advance(2)
release(64)
advance(2)
check("two taps beyond the double-tap window leave it closed", summoned(), false)

-- An ordinary keyboard now learns its Super like any other, so the hold starts
-- a tick later than it used to. Nothing is seeded, so this is the case that
-- would break if probing regressed.
reset({ [133] = "Super_L" })
load_plugin()
press(133)
advance(2)
advance(5000)
check("holding an ordinary Super opens the overlay", summoned(), true)
release(133)

-- The same two gestures behind an input method.
reset(MAC, true)
load_plugin()
press(64)
advance(2)
advance(5000)
check("holding Command opens the overlay behind an input method", summoned(), true)
release(64)

reset(MAC, true)
load_plugin()
press(64)
advance(2)
release(64)
advance(50)
press(64)
advance(2)
release(64)
advance(2)
check("double-tapping Command opens the overlay behind an input method", summoned(), true)

reset({ [133] = "Super_L" }, true)
load_plugin()
press(133)
advance(2)
release(133)
advance(50)
press(133)
advance(2)
release(133)
advance(2)
check("double-tapping an ordinary Super works behind an input method", summoned(), true)

-- Under a swap the META position types Alt_L. Seeding it as Super meant holding
-- Alt opened the overlay -- the same bug as the Mac miss, pointed the other way.
reset(MAC)
load_plugin()
press(133)
advance(2)
advance(5000)
check("the key vacated by a swap is not treated as Super", summoned(), false)
release(133)

-- 125 used to sit in the Super table, where it means KP-equals.
reset(MAC)
load_plugin()
press(125)
advance(2)
advance(5000)
check("a keypad key is not treated as Super", summoned(), false)
release(125)

-- Probing costs a timer, so it must never happen while someone is typing.
reset(MAC)
load_plugin()
press(38)
release(38)
check("letter keys schedule no probe", #timers == 0, true)

-- Attribution: "some Super is held" cannot say which key put it there, so a
-- candidate that merely overlaps another key's Super must not inherit it.
reset(PC)
load_plugin()
press(37)
press(133)
advance(5)
release(133)
release(37)
advance(1000)
dispatched = {}
press(37)
advance(5)
advance(6000)
check("Ctrl pressed just before Super is not learned as Super", summoned(), false)
release(37)

reset(MAC)
load_plugin()
press(64)
press(37)
advance(5)
release(37)
release(64)
advance(1000)
dispatched = {}
press(37)
advance(5)
advance(6000)
check("Ctrl held under an unlearned Command is not learned as Super", summoned(), false)
release(37)

-- A chord landing inside the probe window must neither open the overlay nor
-- teach us that the chorded letter is Super.
reset(MAC)
load_plugin()
press(64)
press(38)
advance(5)
check("a chord during the probe does not open the overlay", summoned(), false)
release(38)
release(64)
advance(1000)
dispatched = {}
press(38)
advance(5)
advance(6000)
check("the chorded letter is not learned as Super", summoned(), false)
release(38)

-- Abandoning a probe must not poison the key for good.
reset(MAC)
load_plugin()
press(64)
press(38)
advance(5)
release(38)
release(64)
advance(1000)
dispatched = {}
press(64)
advance(2)
advance(5000)
check("Command still learns on a later clean press", summoned(), true)
release(64)

-- A tap that finishes before its own probe runs would strand super_down if the
-- probe replayed a press for a key already up.
reset(PC)
load_plugin()
press(133)
release(133)
advance(5)
advance(6000)
check("a Super tap completed before its probe leaves nothing held", summoned(), false)

if failures == 0 then
  print("\nALL PASS")
  os.exit(0)
end

print("\n" .. failures .. " FAILURE(S)")
os.exit(1)
