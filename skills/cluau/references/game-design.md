# Game Design — Loops, Progression, Retention (without manipulation)

Cluau gives concrete, numeric design advice. When the user asks "make a game", first lock down the **core loop**, then build the smallest playable version (vertical slice), then layer meta-progression.

## Contents
1. Design brief template
2. Core loop patterns by genre
3. Progression math
4. Economy design
5. First-time user experience (FTUE)
6. Session design & retention
7. Social features
8. Content cadence & live ops
9. Scope control — the MVP checklist

---

## 1. Design brief (fill before building)

```
Title (working):
Genre / reference feel (describe mechanics, not "like <game>"):
Target audience & age:
Session length target: e.g. 15–25 min
Core loop (verb → reward → upgrade → verb):
Win/lose conditions or long-term goal:
Meta progression (what persists between sessions):
Social hook (why play with friends):
Monetization fit (what's for sale and why it's fair):
Art direction line:
MVP features (≤ 6):
Out of scope for v1:
```

Help the user make it **original**: combine mechanics in a fresh theme, give the world its own characters, names and art direction. Don't clone a specific existing game's name, characters, maps, or look.

## 2. Core loops

| Genre | Loop | Key tuning |
|---|---|---|
| **Obby** | Run stage → checkpoint → harder stage | Difficulty ramps with relief stages every 5–10; checkpoint saves; skip-stage product optional; deaths ≤ ~10 per stage for median player |
| **Simulator** | Collect → sell/convert → upgrade capacity/speed → unlock zone | Each zone ~1.5–3× income of previous; first upgrade within 30 s; rebirth resets for a permanent multiplier |
| **Tycoon** | Earn passively → buy droppers/buildings → income grows | Buttons appear in clear order; first 5 purchases within 2 min; idle income keeps flowing; plot ownership on server |
| **Round-based (PvP / survival / murder-mystery-like)** | Lobby → intermission (15–30 s) → round (2–5 min) → results → rewards | Round state machine on server; join-in-progress rules; min players; AFK handling |
| **Tower defense** | Place units → wave → earn → upgrade/place | Wave HP growth ~ 1.1–1.2× per wave; boss every 10; placement validated server-side |
| **Horror** | Explore → find objective → threat escalates → escape | Tension pacing; audio-first; checkpoints; short sessions (10–20 min) |
| **RPG/Adventure** | Quest → combat/explore → loot → level → harder area | Level curve, gear tiers, quest log; party play |
| **Hangout/Roleplay** | Customize → socialize → express | Housing, emotes, jobs; moderation & text filtering crucial |

## 3. Progression math

- XP to next level: `xpForLevel(n) = floor(base * n ^ exponent)` with `base 50–100`, `exponent 1.5–2.0`. Level 1→2 should take < 2 min.
- Income/cost growth: costs grow faster than income (`cost *= 1.15–1.35` per tier, `income *= 1.1–1.25`) to keep goals meaningful; add multipliers (rebirths, passes) to restore pace.
- Rebirth/prestige: unlock when the next upgrade costs > ~10 min of play; reward a visible permanent multiplier (+10–50%).
- Time-to-first-reward: < 30 s. Time-to-first-unlock: < 3 min. First "wow" moment: < 10 min.
- Keep numbers readable: abbreviate (`1.2K`, `3.4M`, `5.6B`, `7.8T`) with a formatter; for extreme scales use suffix tables.

## 4. Economy

- **Sources** (coins from collecting, quests, daily rewards) vs **sinks** (upgrades, cosmetics, rerolls). Track both; inflation kills long-term goals.
- Separate soft currency (earned) and premium currency (Robux-bought, also earnable slowly) only if needed — one currency is simpler.
- Rewards scale with progression (percent-based) so early quests aren't worthless later.
- Trading economies need: server-held trades, value guidance, scam protection (confirmation delay, trade history), and duplicate protection (session-locked data).

## 5. FTUE (first 5 minutes)

- Spawn facing the first objective. Minimal text; teach by doing (arrows/beams, highlighted target, one prompt at a time).
- First reward within 30 s with celebration.
- Don't show the shop, codes, settings, and 6 menus at once; reveal UI as it becomes relevant.
- Save tutorial progress; skip for returning players.
- Measure: % reaching step N (use `AnalyticsService:LogOnboardingFunnelStepEvent` / custom events where available).

## 6. Session design & retention (ethical)

- Clear short-, mid-, and long-term goals visible at all times (next upgrade, next zone, next rank).
- Daily rewards with a calendar (no punishment beyond losing the streak bonus).
- Quests: 3 daily, 1 weekly; varied verbs.
- Natural stopping points (end of round, zone unlocked) — players who leave satisfied return.
- Updates: weekly or bi-weekly small content + monthly events beat rare huge updates.
- Avoid: FOMO-heavy mechanics for kids, loss aversion traps, notifications spam.

## 7. Social

- Friends join → small bonus (server-validated via `player:IsFriendsWith`, pcall).
- Co-op objectives, party queues, trading, showing off (leaderboards, cosmetics, plots).
- Invite prompts via `SocialService:PromptGameInvite(player)` only on explicit button press.

## 8. Live ops

- Codes system: server-validated codes in config or DataStore, expiry dates on server time, one redemption per player recorded in data.
- Events: toggle via DataStore/MemoryStore config read on server start + MessagingService live switch.
- Analytics: funnel, retention D1/D7/D30, session length, conversion — from Creator Dashboard; use `AnalyticsService` custom/economy/progression events where available.

## 9. MVP checklist

A playable v1 needs only:
1. Core loop works end-to-end on the server.
2. Data saves/loads reliably.
3. HUD shows the core number(s) and the next goal.
4. One shop or upgrade screen.
5. Mobile + gamepad controls usable.
6. Basic sound feedback.

Everything else (pets, trading, quests, events) comes after the loop is fun.
