#!/usr/bin/env python3
"""Unit tests for apply-edit helpers that do not need Hyprland."""

from __future__ import annotations

import json
import os
import tempfile
import types
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
_src = ROOT / "apply-edit"
mod = types.ModuleType("apply_edit")
mod.__file__ = str(_src)
exec(compile(_src.read_text(), str(_src) + ".py", "exec"), mod.__dict__)


class ChordRules(unittest.TestCase):
    def test_protected_summons(self) -> None:
        self.assertTrue(mod.is_protected_chord("SUPER + K"))
        self.assertTrue(mod.is_protected_chord("Super + K"))
        self.assertTrue(mod.is_protected_chord("Hold Super 5s"))
        self.assertTrue(mod.is_protected_chord("Double-tap Super"))
        self.assertFalse(mod.is_protected_chord("SUPER + RETURN"))

    def test_exec_stanza_reuses_the_command(self) -> None:
        text = mod.bind_stanza(
            "SUPER + RETURN", "Terminal",
            "SUPER + T", "Terminal",
            "exec", "ghostty",
        )
        self.assertIn('hl.unbind("SUPER + RETURN")', text)
        self.assertIn('hl.dsp.exec_cmd("ghostty")', text)
        self.assertIn('description = "Terminal"', text)
        self.assertIn('hl.bind("SUPER + T"', text)
        self.assertNotIn("o.bind", text)

    def test_lua_stanza_reuses_the_recovered_expr(self) -> None:
        expr = 'hl.dsp.workspace({ workspace = 3 })'
        text = mod.bind_stanza(
            "SUPER + 3", "Switch to workspace 3",
            "SUPER + F3", "Switch to workspace 3",
            "lua", expr,
        )
        self.assertIn(expr, text)

    def test_refuses_to_invent_an_action(self) -> None:
        with self.assertRaises(ValueError):
            mod.bind_stanza("SUPER + A", "X", "SUPER + B", "X", "exec", "")
        with self.assertRaises(ValueError):
            mod.bind_stanza("SUPER + A", "X", "SUPER + B", "X", "lua", "os.execute('rm')")
        self.assertIsNone(mod.lua_dispatcher("lua", "print(1)"))

    def test_to_bind_keys_normalizes_overlay_chords(self) -> None:
        self.assertEqual(mod.to_bind_keys("Super + Return"), "SUPER + RETURN")
        self.assertEqual(mod.to_bind_keys("SUPER + RETURN"), "SUPER + RETURN")
        self.assertEqual(mod.to_bind_keys("Shift + Super + T"), "SUPER + SHIFT + T")


class ChordIndex(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        root = Path(self.tmp.name)
        mod.CHORD_INDEX = root / "omarkeys-chords.json"
        mod.EDITS_LUA = root / "omarkeys-edits.lua"
        mod.BINDINGS_LUA = root / "bindings.lua"
        mod.HISTORY = root / "history"
        mod.BINDINGS_LUA.write_text("-- bindings\n", encoding="utf-8")
        os.environ["OMARKEYS_SKIP_RELOAD"] = "1"

    def tearDown(self) -> None:
        self.tmp.cleanup()
        os.environ.pop("OMARKEYS_SKIP_RELOAD", None)

    def test_seed_does_not_overwrite_a_stored_default(self) -> None:
        first = mod.seed_defaults([
            {"action": "Terminal", "keys": "Super + Return", "dispatcher": "exec", "arg": "ghostty"},
        ])
        self.assertEqual(first["added"], 1)
        second = mod.seed_defaults([
            {"action": "Terminal", "keys": "Super + T", "dispatcher": "exec", "arg": "ghostty"},
        ])
        self.assertEqual(second["added"], 0)
        data = mod.load_index()
        self.assertEqual(data["defaults"]["Terminal"]["keys"], "Super + Return")

    def test_swap_unbinds_both_chords_before_binding(self) -> None:
        mod.seed_defaults([
            {"action": "Terminal", "keys": "Super + Return", "dispatcher": "exec", "arg": "ghostty"},
            {"action": "Browser", "keys": "Super + Shift + Return", "dispatcher": "exec", "arg": "chromium"},
        ])
        data = mod.load_index()
        data["moves"] = [
            {
                "action": "Browser",
                "from": "Super + Shift + Return",
                "to": "Super + Return",
                "because": "Terminal",
                "dispatcher": "exec",
                "arg": "chromium",
            },
            {
                "action": "Terminal",
                "from": "Super + Return",
                "to": "Super + Shift + Return",
                "because": "",
                "dispatcher": "exec",
                "arg": "ghostty",
            },
        ]
        text = mod.emit_overrides(data)
        unbind_at = text.find("hl.unbind")
        bind_at = text.find("hl.bind")
        self.assertGreater(unbind_at, 0)
        self.assertGreater(bind_at, unbind_at)
        self.assertIn('hl.unbind("SUPER + RETURN")', text)
        self.assertIn('hl.unbind("SUPER + SHIFT + RETURN")', text)
        self.assertLess(
            text.find('hl.unbind("SUPER + RETURN")'),
            text.find("hl.bind"),
        )
        self.assertLess(
            text.find('hl.unbind("SUPER + SHIFT + RETURN")'),
            text.find("hl.bind"),
        )

    def test_restore_plan_unwinds_a_displaced_chain(self) -> None:
        mod.seed_defaults([
            {"action": "Terminal", "keys": "Super + Return", "dispatcher": "exec", "arg": "ghostty"},
            {"action": "Browser", "keys": "Super + Shift + Return", "dispatcher": "exec", "arg": "chromium"},
            {"action": "Files", "keys": "Super + F", "dispatcher": "exec", "arg": "nautilus"},
        ])
        data = mod.load_index()
        data["moves"] = [
            {"action": "Browser", "from": "Super + Shift + Return", "to": "Super + F", "because": "Terminal"},
            {"action": "Files", "from": "Super + F", "to": "Super + N", "because": "Terminal"},
            {"action": "Terminal", "from": "Super + Return", "to": "Super + Shift + Return", "because": ""},
        ]
        related = mod.related_actions("Terminal", data["moves"])
        self.assertEqual(related, {"Browser", "Files", "Terminal"})
        plan = mod.restore_plan("Terminal", data)
        self.assertEqual(sorted(s["action"] for s in plan), ["Browser", "Files", "Terminal"])
        by_name = {s["action"]: s for s in plan}
        self.assertEqual(by_name["Files"]["new_keys"], "Super + F")
        self.assertEqual(by_name["Terminal"]["new_keys"], "Super + Return")

    def test_apply_plan_writes_index_and_lua(self) -> None:
        mod.seed_defaults([
            {"action": "Terminal", "keys": "Super + Return", "dispatcher": "exec", "arg": "ghostty"},
        ])
        result = mod.apply_plan(
            [{
                "action": "Terminal",
                "old_keys": "Super + Return",
                "new_keys": "Super + T",
                "dispatcher": "exec",
                "arg": "ghostty",
                "because": "",
            }],
            "test remap",
        )
        self.assertTrue(result["ok"])
        index = json.loads(mod.CHORD_INDEX.read_text(encoding="utf-8"))
        self.assertEqual(index["moves"][-1]["to"], "Super + T")
        text = mod.EDITS_LUA.read_text(encoding="utf-8")
        self.assertIn('hl.unbind("SUPER + RETURN")', text)
        self.assertIn('hl.bind("SUPER + T"', text)
        self.assertIn('hl.dsp.exec_cmd("ghostty")', text)


if __name__ == "__main__":
    unittest.main()
