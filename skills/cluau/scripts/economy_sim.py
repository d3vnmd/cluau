#!/usr/bin/env python3
"""
cluau-economy: simulate a progression economy before players do.

    python3 economy_sim.py economy.json [--json]
    python3 economy_sim.py --example > economy.json      # starter config

Model: a player earns `base_income_per_sec × multiplier` and buys upgrades in the listed order as soon as
they can afford each one (a focused player — real players are slower). Optional rebirths reset coins and
upgrades for a permanent multiplier. The simulation is event-based and exact (no time steps).

Reports time-to-unlock for every upgrade/rebirth and flags:
  SLOW_START   first purchase later than targets.first_purchase_max_sec
  GRIND_WALL   a wait longer than targets.max_wait_sec
  SPIKE        a wait more than targets.max_wait_ratio × the previous wait
  TRIVIAL      a wait shorter than targets.min_wait_sec after the first few (content consumed too fast)
  UNREACHABLE  not reached within horizon_minutes
Exit code 1 if any flag is raised (useful in CI for tuning tables).
"""
from __future__ import annotations

import argparse
import json
import sys
from dataclasses import dataclass, field

EXAMPLE = {
    "currency": "Coins",
    "base_income_per_sec": 2,
    "horizon_minutes": 240,
    "upgrades": [
        {"id": "Bigger Bag", "cost": 30, "income_add": 1},
        {"id": "Fast Shovel", "cost": 120, "income_add": 3},
        {"id": "Zone 2", "cost": 600, "income_mult": 2},
        {"id": "Golden Shovel", "cost": 2500, "income_add": 15},
        {"id": "Zone 3", "cost": 12000, "income_mult": 2},
        {"id": "Drill", "cost": 60000, "income_add": 120},
        {"id": "Zone 4", "cost": 400000, "income_mult": 2.5},
    ],
    "rebirth": {"cost": 2000000, "multiplier_add": 0.5, "max_rebirths": 3},
    "targets": {
        "first_purchase_max_sec": 30,
        "max_wait_sec": 900,
        "max_wait_ratio": 4.0,
        "min_wait_sec": 5,
    },
}


@dataclass
class Event:
    kind: str  # "upgrade" | "rebirth"
    name: str
    cost: float
    at_sec: float
    wait_sec: float
    income_after: float
    flags: list[str] = field(default_factory=list)


def _fmt(seconds: float) -> str:
    seconds = int(round(seconds))
    h, rem = divmod(seconds, 3600)
    m, s = divmod(rem, 60)
    return f"{h}:{m:02d}:{s:02d}" if h else f"{m}:{s:02d}"


def simulate(cfg: dict) -> tuple[list[Event], list[str]]:
    base = float(cfg["base_income_per_sec"])
    horizon = float(cfg.get("horizon_minutes", 120)) * 60
    upgrades = cfg.get("upgrades", [])
    rebirth = cfg.get("rebirth")
    targets = cfg.get("targets", {})
    events: list[Event] = []
    unreached: list[str] = []

    t = 0.0
    rebirth_mult = 1.0
    rebirths = 0
    max_rebirths = int(rebirth.get("max_rebirths", 1)) if rebirth else 0

    while True:
        coins = 0.0
        add = 0.0
        mult = 1.0
        for up in upgrades:
            income = (base + add) * mult * rebirth_mult
            cost = float(up["cost"])
            wait = max(0.0, (cost - coins) / income) if income > 0 else float("inf")
            if t + wait > horizon:
                unreached.append(up["id"] + (f" (after rebirth {rebirths})" if rebirths else ""))
                return _flag(events, targets), unreached
            t += wait
            coins += wait * income - cost
            add += float(up.get("income_add", 0))
            mult *= float(up.get("income_mult", 1))
            events.append(Event("upgrade", up["id"], cost, t, wait, (base + add) * mult * rebirth_mult))
        if not rebirth or rebirths >= max_rebirths:
            break
        income = (base + add) * mult * rebirth_mult
        cost = float(rebirth["cost"])
        wait = max(0.0, (cost - coins) / income) if income > 0 else float("inf")
        if t + wait > horizon:
            unreached.append(f"Rebirth {rebirths + 1}")
            break
        t += wait
        rebirths += 1
        rebirth_mult += float(rebirth["multiplier_add"])
        events.append(Event("rebirth", f"Rebirth {rebirths}", cost, t, wait, base * rebirth_mult))
    return _flag(events, targets), unreached


def _flag(events: list[Event], targets: dict) -> list[Event]:
    first_max = targets.get("first_purchase_max_sec")
    max_wait = targets.get("max_wait_sec")
    ratio = targets.get("max_wait_ratio")
    min_wait = targets.get("min_wait_sec")
    for i, e in enumerate(events):
        if i == 0 and first_max is not None and e.wait_sec > first_max:
            e.flags.append("SLOW_START")
        if max_wait is not None and e.wait_sec > max_wait:
            e.flags.append("GRIND_WALL")
        if i > 0 and ratio is not None and events[i - 1].wait_sec > 0 and e.wait_sec > ratio * events[i - 1].wait_sec and e.wait_sec > 60:
            e.flags.append("SPIKE")
        if i >= 3 and min_wait is not None and e.wait_sec < min_wait:
            e.flags.append("TRIVIAL")
    return events


def report(cfg: dict, events: list[Event], unreached: list[str]) -> str:
    cur = cfg.get("currency", "Coins")
    lines = [f"{'#':>3}  {'Unlock':<24} {'Cost':>12} {'Reached at':>10} {'Wait':>9} {'Income/s after':>15}  Flags", "-" * 92]
    for i, e in enumerate(events, start=1):
        lines.append(f"{i:>3}  {e.name:<24} {e.cost:>12,.0f} {_fmt(e.at_sec):>10} {_fmt(e.wait_sec):>9} {e.income_after:>15,.1f}  {' '.join(e.flags)}")
    for name in unreached:
        lines.append(f"  -  {name:<24} {'':>12} {'—':>10} {'':>9} {'':>15}  UNREACHABLE")
    flags = sum(len(e.flags) for e in events) + len(unreached)
    lines += ["", f"{len(events)} unlock(s) in {_fmt(events[-1].at_sec) if events else '0:00'}; {flags} flag(s). Currency: {cur}.",
              "Model = a focused player buying in order; real players take 1.5–3× longer."]
    return "\n".join(lines)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="cluau-economy", description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("config", nargs="?")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--example", action="store_true", help="print a starter config")
    args = parser.parse_args(argv)
    if args.example:
        print(json.dumps(EXAMPLE, indent=2))
        return 0
    if not args.config:
        parser.error("config path required (or --example)")
    with open(args.config, encoding="utf-8") as fh:
        cfg = json.load(fh)
    events, unreached = simulate(cfg)
    if args.json:
        print(json.dumps({"events": [e.__dict__ for e in events], "unreached": unreached}, indent=2))
    else:
        print(report(cfg, events, unreached))
    return 1 if unreached or any(e.flags for e in events) else 0


if __name__ == "__main__":
    sys.exit(main())
