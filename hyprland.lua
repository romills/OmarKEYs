-- OmarKEYS Hyprland activation.
-- Loaded from ~/.config/hypr/bindings.lua:
--   dofile(os.getenv("HOME") .. "/.config/omarchy/plugins/io.github.romills.omarkeys/hyprland.lua")

local PLUGIN_ID = "io.github.romills.omarkeys"
local NAMESPACE = "romills-omarkeys"
local DOUBLE_TAP_MS = 400
local CONFIG_PATH = (os.getenv("HOME") or "") .. "/.config/omarchy/omarkeys.json"

local function clamp(n, lo, hi)
  if n < lo then
    return lo
  end
  if n > hi then
    return hi
  end
  return n
end

local function read_config()
  local cfg = { doubleTap = true, holdSeconds = 5, superK = true, holdEnabled = true }
  local f = io.open(CONFIG_PATH, "r")
  if not f then
    return cfg
  end
  local raw = f:read("*a") or ""
  f:close()
  if raw:match('"doubleTap"%s*:%s*false') then
    cfg.doubleTap = false
  end
  if raw:match('"superK"%s*:%s*false') then
    cfg.superK = false
  end
  if raw:match('"holdEnabled"%s*:%s*false') then
    cfg.holdEnabled = false
  end
  local hold = tonumber(raw:match('"holdSeconds"%s*:%s*(%d+)'))
  if hold then
    cfg.holdSeconds = clamp(hold, 1, 10)
  end
  return cfg
end

-- Which keycodes carry Super, learned at runtime; see learn_super. Nothing is
-- assumed. A keycode is a physical position, and the XKB options that move
-- Super rewrite only the keysym, so no table of positions is right for every
-- keymap: whichever pair you hardcode, some layout has an ordinary key there.
--
-- This started as { 125, 126, 133, 134 }, and both halves were wrong.
-- input.keyboard.key reports XKB keycodes, not evdev ones -- the event bridge
-- pushes `keyEvent.keycode + 8` (LuaEventHandler.cpp) -- so 125 and 126 meant
-- evdev 117 and 118, KP-equals and KP-plusminus, and a keypad key counted as
-- Super. And 133/134 are the META pair only until an option vacates them:
-- under altwin:swap_lalt_lwin the Win position types Alt_L, so holding Alt
-- opened the overlay. Asking the keymap costs one probe per keyboard.
local SUPER = {}

-- Keycodes a keymap can carry Super on, so a probe is only ever scheduled for a
-- key that could plausibly answer yes and ordinary typing never schedules one.
-- XKB codes, with the evdev key each corresponds to:
--   37 LEFTCTRL   64 LEFTALT    66 CAPSLOCK    105 RIGHTCTRL  107 SYSRQ
--   108 RIGHTALT  133 LEFTMETA  134 RIGHTMETA  135 COMPOSE
-- The META pair sits here rather than being assumed, so a layout that has moved
-- Super off it fails the probe instead of firing the gestures from whatever key
-- took its place. Between them these cover the stock options that relocate
-- Super (altwin:swap_lalt_lwin, altwin:menu_win, altwin:alt_super_win,
-- altwin:prtsc_rwin, ctrl:swap_lwin_lctl, caps:super) and Mac-layout boards
-- whose CMD reports KEY_LEFTALT. A keymap that puts Super somewhere else
-- entirely still works through Super+K, as it does today.
local SUPER_CANDIDATES = {
  [37] = true,
  [64] = true,
  [66] = true,
  [105] = true,
  [107] = true,
  [108] = true,
  [133] = true,
  [134] = true,
  [135] = true,
}

local st = {
  super_down = false,
  chorded = false,
  overlay_open = false,
  close_tap = false,
  tap_armed = false,
  hold_timer = nil,
  tap_timer = nil,
  overlay_layers = 0,
  close_swallowed = false,
  restore_close_pending = false,
}

local function stop_timer(name)
  local timer = st[name]
  if not timer then
    return
  end
  pcall(function()
    timer:set_enabled(false)
  end)
  st[name] = nil
end

local function named_super_down()
  local down = false
  pcall(function()
    down = hl.is_key_down("Super_L") or hl.is_key_down("Super_R")
  end)
  return down
end

local on_key

-- Bumped by every key event for a key other than the one being probed, so a
-- probe can tell whether anything else happened while it was pending.
local key_seq = 0

-- The keycode a probe is waiting on, if any. Events for that same key must not
-- disturb it. An input method -- fcitx5, ibus -- sits between the keyboard and
-- the compositor as its own virtual keyboard and re-emits what you press, so
-- one physical press arrives here twice. Counting the echo as an intervening
-- key aborted every probe and learned nothing, which is invisible until the
-- table stops being seeded: with a hardcoded Super the duplicate is harmless,
-- because both copies are already recognised.
local probe_code = nil

-- Hyprland runs the input.keyboard.key handler before the keybind manager
-- records the press, so hl.is_key_down() read inside the handler describes the
-- state *before* the current event. Read a tick later it describes the state
-- the event produced, and the difference between the two is what says whether
-- this keycode carries Super under the active keymap.
--
-- Attribution is the whole difficulty. "Some Super is held" is an aggregate: it
-- cannot say which key put it there. So the probe only trusts its reading when
-- nothing else happened in between --
--
--   * Super must not already be down when the key arrives (some other key,
--     possibly one not learned yet, is holding it), and
--   * no event for another key may land between scheduling and reading, or an
--     interleaved press could be the real cause. An echo of the probed key
--     itself is not another key, which matters because an input method
--     delivers one; see probe_code above.
--
-- With nothing else touched across the window, a Super that is down now and was
-- not down then can only have come from this key. That also keeps the replay
-- below honest: nothing can have chorded, opened or closed the overlay while
-- the probe was pending, so replaying the press cannot overwrite newer state.
--
-- Only a yes is cached, so a probe that lands between a press and its release
-- can never demote a real Super key to an ordinary one.
local function learn_super(code)
  if SUPER[code] or not SUPER_CANDIDATES[code] or st.super_down or named_super_down() then
    return
  end
  local seq = key_seq
  probe_code = code
  hl.timer(function()
    probe_code = nil
    if key_seq ~= seq or not named_super_down() then
      return
    end
    SUPER[code] = true
    -- Replay the press this probe was still deciding about.
    local ok, err = pcall(on_key, code, 0, 1)
    if not ok then
      print("[OmarKEYS] super probe: " .. tostring(err))
    end
  end, { timeout = 1, type = "oneshot" })
end

local function grab_keys()
  hl.dispatch(hl.dsp.exec_cmd("omarchy-shell shell call " .. PLUGIN_ID .. " grab 1"))
end

-- Exclusive grab while Super is still down eats Super-up. Keep retrying
-- until Super is up so filter typing actually lands in OmarKEYS.
local function schedule_grab()
  hl.timer(function()
    if not st.overlay_open then
      return
    end
    if st.super_down then
      schedule_grab()
      return
    end
    grab_keys()
  end, { timeout = 40, type = "oneshot" })
end

local hide_overlay
local restore_super_w

-- SUPER+W is "close window". OmarKEYS is a layer plugin, not an app, so
-- that bind would kill the last focused window. Temporarily remap it to
-- close this layer; restore "Close window" when the overlay hides.
local function swallow_super_w()
  st.restore_close_pending = false
  if st.close_swallowed then
    return
  end
  st.close_swallowed = true
  hl.unbind("SUPER + W")
  o.bind("SUPER + W", "Close OmarKEYS", function()
    hide_overlay()
  end)
end

restore_super_w = function()
  if not st.close_swallowed then
    return
  end
  -- Don't restore mid-chord: Super+W just hid us, Super is still down.
  if st.super_down then
    st.restore_close_pending = true
    return
  end
  st.close_swallowed = false
  st.restore_close_pending = false
  hl.unbind("SUPER + W")
  o.bind("SUPER + W", "Close window", hl.dsp.window.close())
end

hide_overlay = function()
  st.overlay_open = false
  st.close_tap = false
  st.tap_armed = false
  stop_timer("hold_timer")
  stop_timer("tap_timer")
  restore_super_w()
  hl.dispatch(hl.dsp.exec_cmd("omarchy-shell shell hide " .. PLUGIN_ID))
end

local function show_overlay()
  st.overlay_open = true
  st.close_tap = false
  st.tap_armed = false
  stop_timer("tap_timer")
  swallow_super_w()
  hl.dispatch(hl.dsp.exec_cmd("omarchy-shell shell summon " .. PLUGIN_ID .. " '{}'"))
  schedule_grab()
end

on_key = function(keycode, _, state)
  local code = tonumber(keycode) or keycode
  if code ~= probe_code then
    key_seq = key_seq + 1
  end

  if state == 2 then
    return
  end

  local is_super = SUPER[code] == true
  if not is_super and state == 1 then
    learn_super(code)
  end

  if state == 1 then
    if is_super then
      if st.super_down then
        return
      end
      st.super_down = true
      st.chorded = false
      st.close_tap = st.overlay_open
      stop_timer("hold_timer")
      if not st.overlay_open then
        local cfg = read_config()
        local hold_ms = cfg.holdEnabled
          and math.floor((cfg.holdSeconds or 5) * 1000) or 0
        if hold_ms > 0 then
          st.hold_timer = hl.timer(function()
            st.hold_timer = nil
            if st.chorded or st.overlay_open or not st.super_down then
              return
            end
            show_overlay()
          end, { timeout = hold_ms, type = "oneshot" })
        end
      end
    elseif st.super_down then
      st.chorded = true
      st.close_tap = false
      st.tap_armed = false
      stop_timer("hold_timer")
      stop_timer("tap_timer")
    end
  elseif state == 0 and is_super then
    if not st.super_down then
      return
    end
    st.super_down = false
    stop_timer("hold_timer")
    if st.restore_close_pending then
      restore_super_w()
    end
    if st.chorded then
      -- Super+K (and other Super chords). If OmarKEYS just opened, Super
      -- is now up — take keyboard focus so typing/filter works.
      if st.overlay_open then
        st.close_tap = false
        grab_keys()
      end
      return
    elseif st.overlay_open and st.close_tap then
      hide_overlay()
    elseif st.overlay_open then
      st.close_tap = false
      grab_keys()
    elseif read_config().doubleTap and st.tap_armed then
      st.tap_armed = false
      stop_timer("tap_timer")
      show_overlay()
      grab_keys()
    elseif read_config().doubleTap then
      st.tap_armed = true
      stop_timer("tap_timer")
      st.tap_timer = hl.timer(function()
        st.tap_armed = false
        st.tap_timer = nil
      end, { timeout = DOUBLE_TAP_MS, type = "oneshot" })
    end
  end
end

-- Claiming Super+K means unbinding whatever had it (Omarchy ships
-- "Keybindings"). Turned off, we simply never take it, so the original
-- bind survives untouched -- no need to know what it was in order to give
-- it back. The overlay applies a change by asking Hyprland to reload:
-- bindings.lua re-runs, restores its own Super+K, and this file re-reads
-- the config and decides again.
if read_config().superK then
  hl.unbind("SUPER + K")
  o.bind("SUPER + K", "OmarKEYS", function()
    if st.overlay_open then
      hide_overlay()
    else
      show_overlay()
    end
  end)
end

hl.on("input.keyboard.key", function(keycode, timestamp, state)
  local ok, err = pcall(on_key, keycode, timestamp, state)
  if not ok then
    print("[OmarKEYS] key handler: " .. tostring(err))
  end
end)

-- Keep lua overlay_open / Super+W swallow in sync when Esc or a click
-- hides the layer without going through hide_overlay().
hl.on("layer.opened", function(layer)
  if not layer or layer.namespace ~= NAMESPACE then
    return
  end
  st.overlay_layers = st.overlay_layers + 1
  if st.overlay_layers == 1 then
    st.overlay_open = true
    swallow_super_w()
  end
end)

hl.on("layer.closed", function(layer)
  if not layer or layer.namespace ~= NAMESPACE then
    return
  end
  if st.overlay_layers > 0 then
    st.overlay_layers = st.overlay_layers - 1
  end
  if st.overlay_layers == 0 then
    st.overlay_open = false
    st.close_tap = false
    restore_super_w()
  end
end)

hl.layer_rule({
  match = { namespace = NAMESPACE },
  no_anim = true,
  animation = "none",
})
