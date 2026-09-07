#!/usr/bin/env python3
"""Unit tests for dump-keymap helpers that do not need a live Hyprland."""

from __future__ import annotations

import types
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
_src = ROOT / "dump-keymap"
dk = types.ModuleType("dump_keymap")
dk.__file__ = str(_src)
exec(compile(_src.read_text(), str(_src) + ".py", "exec"), dk.__dict__)


def workspace_row(n: int, **extra) -> dict:
    row = {
        "keys": f"Super + {0 if n == 10 else n}",
        "action": f"Switch to workspace {n}",
        "dispatcher": "workspace",
        "arg": str(n),
        "bindKey": str(0 if n == 10 else n),
        "mods": "SUPER",
        "runnable": True,
    }
    row.update(extra)
    return row


class CollapseNumbered(unittest.TestCase):
    def test_full_1_to_10_collapses_to_a_range(self) -> None:
        out = dk.collapse_numbered([workspace_row(n) for n in range(1, 11)])
        self.assertEqual(len(out), 1)
        self.assertEqual(out[0]["action"], "Switch to workspace 1-10")
        self.assertEqual(out[0]["keys"], "Super + 1-9, 0")
        self.assertNotIn("dispatcher", out[0])

    def test_sparse_keeps_dispatcher_metadata(self) -> None:
        out = dk.collapse_numbered([workspace_row(1), workspace_row(3)])
        self.assertEqual(len(out), 2)
        self.assertEqual(out[0]["dispatcher"], "workspace")
        self.assertEqual(out[0]["arg"], "1")
        self.assertEqual(out[1]["arg"], "3")
        self.assertEqual(out[1]["bindKey"], "3")

    def test_passthrough_rows_keep_their_fields(self) -> None:
        row = {
            "keys": "Super + Return",
            "action": "New terminal",
            "dispatcher": "exec",
            "arg": "ghostty",
            "runnable": True,
        }
        out = dk.collapse_numbered([row])
        self.assertEqual(out, [row])


if __name__ == "__main__":
    unittest.main()
