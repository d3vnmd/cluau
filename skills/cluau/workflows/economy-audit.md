# Workflow: economy audit

1. **Map currencies:** every currency/item that acts like money — sources (earn rates per minute at key stages)
   and sinks (upgrades, cosmetics, rerolls). Flag sources without sinks (inflation).
2. **Pacing:** build the upgrade table → `python3 scripts/economy_sim.py economy.json` → fix SLOW_START,
   GRIND_WALL, SPIKE, TRIVIAL, UNREACHABLE. Real players are 1.5–3× slower than the sim.
3. **Multipliers:** list every multiplier (passes, pets, rebirths, boosts, events) and how they stack; cap or
   diminish stacking; check the max-stack case doesn't trivialize content.
4. **Exploits:** client-sent amounts, check-then-deduct races, NaN/negative amounts, trade dupes, AFK farming,
   receipt replays (sharp-edges CX-01/02/05/36–40).
5. **Policy:** paid random items (exact odds, restricted path), paid-item trading (`IsPaidItemTradingAllowed`),
   regional prices for gifting, no pay-to-skip pain (monetization-policy.md).
6. **Output:** currency map, sim table with flags, multiplier table, exploit list, prioritized changes.
