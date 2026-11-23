# Retention Design — Why Players Come Back (Without Manipulating Kids)

> Last verified: 2026-11-23. Benchmarks: GameAnalytics 2025 Roblox report; policy: Roblox Creator Hub (paid random items, age-based accounts). Psychology sections are established game-design principles — present numbers as starting points, not laws.

Roblox's recommendation system rewards **low first-play bounce, playtime, and D1/D7 return** (polish-qa-launch.md §1). Most Roblox players are young: every hook here comes with an ethics line. If a hook only works by exploiting anxiety, it's out.

## Contents
1. The return-frequency insight
2. Hooks by time scale
3. Principles (and their ethical limits)
4. First-session script
5. Retention audit questions
6. Red lines (never build)

---

## 1. The insight

GameAnalytics 2025 medians: D1 10.3%, D7 1.6%, D30 0.5%; top 1%: D1 22.2%, D7 9.1%, D30 4.7%. The biggest gains came from **players coming back more often**, not from longer sessions. Design daily reasons to return that feel like progress, not chores.

## 2. Hooks by time scale

| Scale | Good hooks | Notes |
|---|---|---|
| First 60 s | Instant control, first reward ≤ 30 s, clear next goal on screen | First-play bounce is a ranking signal |
| Session | Short goals chained (next upgrade, next zone), visible progress bars, end-of-session summary | Natural stopping points make players *return*, not burn out |
| Daily | Timestamp growth (crops/eggs finish while away), daily quests (3), rotating shop (Restock.luau), streak calendar with **forgiving** misses | Offline progress rewards coming back |
| Weekly | Fixed update day, weekly quests, leaderboards reset, limited events | Predictable cadence builds habit |
| Long term | Rebirth/prestige, collections (index of pets/items), mastery, social status (cosmetics, titles), building/expression | Collections and expression outlast numbers |
| Social | Play-with-friends bonus, co-op goals, trading (safe), showing off | Friends are the strongest retention force |

## 3. Principles and their limits

| Principle | Use it | Limit |
|---|---|---|
| **Variable reward** (unpredictable drops) | Loot from earned activity, surprise bonuses | Paid randomness must show exact odds; offer the restricted-region path (PolicyService) |
| **Goal gradient / endowed progress** | Start bars partially filled; show "2/3 to next unlock" | Bars must be honest |
| **Completion pull** | Collections, "1 left!" indexes | Never lock the last piece behind Robux-only randomness |
| **Anticipation** | Timers on growth/hatches, countdown to events | Timers measure content, not pain to sell skips |
| **Competence** | Clear feedback, skill expression, readable difficulty ramps | Grind walls ≠ difficulty (use economy_sim.py) |
| **Autonomy** | Choices: builds, paths, cosmetics | Avoid single dominant purchases |
| **Relatedness** | Co-op, gifting, guilds | Chat requires age checks — never make core play depend on chat |
| **Scarcity** | Real limited events with real end dates | No fake countdowns, no resetting "limited" offers |
| **Loss aversion** | Gentle: "your crops are ready" | No threats ("your pet will die"), no punishing streak resets |

## 4. First-session script (timestamps for a simulator; adapt per genre)

| Time | Beat |
|---|---|
| 0:00–0:10 | Spawn facing the first action; one prompt |
| 0:15–0:30 | First reward + celebration (VFX, sound, number pop) |
| 1:00–3:00 | First upgrade bought; income visibly faster |
| 3:00–6:00 | New area or mechanic revealed (e.g. pets) |
| 8:00–12:00 | "Wow" moment (rare drop, big unlock) |
| 15:00+ | Daily-return hook introduced (growth timer, daily quest, tomorrow's reward preview) |

## 5. Retention audit (use with `workflows/retention-audit.md`)

1. Where do players stall? (funnel steps with big drop-off; economy_sim walls)
2. What's the reason to come back tomorrow? Is it visible before they leave?
3. Is there a session end screen with progress + next goal?
4. Do returning players get a welcome-back summary (offline earnings)?
5. Which hooks involve Robux? Are odds/prices clear, optional, fair?
6. Are D1/D7 tracked (AnalyticsService funnels, Creator Dashboard)? Is an Experiment planned for the biggest stall?

## 6. Red lines — never build, offer the fair alternative

- Fake timers, fake scarcity, resetting "limited" offers.
- Pay-to-skip timers you made painful on purpose.
- Guilt/fear copy aimed at kids ("your pet is sad, buy food!").
- Purchase prompts without explicit intent (on join, on death, on UI open).
- Streaks that wipe everything on one missed day.
- Paid random items without exact odds or without the restricted-player path.
- Social pressure to spend ("your friends bought this").
