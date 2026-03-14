#!/usr/bin/env python3
"""
List Excellon drill tools with diameter, AperFunction and hit count.

Useful to decide which tools should be passed to:
  ./scripts/fabrication.sh --mechanical-tools Tn,Tm
"""

from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, Sequence


@dataclass
class DrillTool:
    diameter_mm: float
    aper_function: str
    hits: int = 0

    @property
    def is_npth(self) -> bool:
        af = self.aper_function.upper()
        return "NPTH" in af or "NONPLATED" in af or "NON_PLATED" in af


def parse_drill_tools(drill_file: Path) -> Dict[str, DrillTool]:
    lines = drill_file.read_text(encoding="utf-8", errors="ignore").splitlines()
    tool_re = re.compile(r"^T(\d+)C([0-9.]+)")
    xy_re = re.compile(r"^X(-?[0-9.]+)Y(-?[0-9.]+)")
    ta_re = re.compile(r"^;\s*#@!\s*TA\.AperFunction,(.+)$")

    tools: Dict[str, DrillTool] = {}
    pending_aper_function = ""
    cur_tool = None

    for line in lines:
        s = line.strip()
        if not s:
            continue

        ta_m = ta_re.match(s)
        if ta_m:
            pending_aper_function = ta_m.group(1).strip()
            continue

        tm = tool_re.match(s)
        if tm:
            tname = f"T{int(tm.group(1))}"
            tools[tname] = DrillTool(
                diameter_mm=float(tm.group(2)),
                aper_function=pending_aper_function,
            )
            continue

    for line in lines:
        s = line.strip()
        if not s:
            continue

        if s.startswith("T") and s[1:].isdigit():
            cur_tool = f"T{int(s[1:])}"
            continue

        if not xy_re.match(s) or cur_tool is None:
            continue

        if cur_tool in tools:
            tools[cur_tool].hits += 1

    return tools


def parse_args(argv: Sequence[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="List tools used in an Excellon drill file")
    parser.add_argument("--drill", required=True, type=Path, help="Path to Excellon drill file (.drl)")
    return parser.parse_args(argv)


def main(argv: Sequence[str]) -> int:
    args = parse_args(argv)
    if not args.drill.exists():
        print(f"ERROR: Drill file not found: {args.drill}", file=sys.stderr)
        return 1

    tools = parse_drill_tools(args.drill)
    if not tools:
        print(f"No tool definitions found in {args.drill}")
        return 0

    print(f"Drill file: {args.drill}")
    print("")
    print("Tool  Diameter(mm)  Hits  AperFunction                          DefaultMechanical")
    print("----  ------------  ----  ------------------------------------  ------------------")

    def sort_key(name: str) -> int:
        return int(name[1:]) if name[1:].isdigit() else 9999

    default_mech = []
    for tool_name in sorted(tools.keys(), key=sort_key):
        t = tools[tool_name]
        mech = "yes" if t.is_npth else "no"
        if t.is_npth:
            default_mech.append(tool_name)
        aper = t.aper_function or "-"
        print(f"{tool_name:<4}  {t.diameter_mm:>12.4f}  {t.hits:>4}  {aper:<36}  {mech}")

    print("")
    print("Suggested --mechanical-tools values:")
    if default_mech:
        print(f"  {','.join(default_mech)}")
    else:
        print("  (none auto-detected from NPTH)")

    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
