# Genre Playbooks — Architecture That Fits the Game

Big studios pick architecture **per genre**, not per habit. Before designing a system, classify the game, then use the matching playbook for: what the server owns, what the client owns, the data schema, the remote list, entity budget, top exploits, monetization fit, and live-ops hook.

Engine facts here are verified (Roblox docs, 2026-11); per-genre design numbers are heuristics from successful games — present them as starting points to tune with analytics.

## Contents
1. The shared skeleton (every genre)
2. Ownership map template
3. Playbooks: obby · simulator/pet · tycoon · round-based · shooter/melee · tower defense · horror · RPG · farming/idle · steal/base-plot · fishing · dress-up/judging · survival co-op · social hangout
4. Cross-genre patterns: timestamp state, deterministic global schedules, client-rendered hordes
5. Benchmarks

---

## 1. Shared skeleton (Roblox's Plant reference project shape)

- One server entry Script, one client entry LocalScript; singleton systems (Services/Controllers).
- Per-player plots/instances cloned from a ServerStorage template and **rebuilt from saved data** on join.
- `Players.CharacterAutoLoads = false` until data loads when spawning depends on data; then `player:LoadCharacterAsync()`.
- One central network module that type-validates every client argument.
- Replication preference: (1) player-data snapshots/deltas, (2) attributes set **before** parenting, (3) CollectionService tags, (4) direct remote messages.

## 2. Ownership map (write this for every new system)

| State | Owner (writes) | Lives on | Replicated how | Persisted? |
|---|---|---|---|---|
| Coins | Server `DataService` | profile table | attribute `Coins` | yes |
| Shop stock slot | Server (derived from time) | computed | attribute `StockSlot` | no |
| Equipped cosmetic | Server | profile | snapshot event | yes |
| Hover/selection | Client | UI controller | — | no |

If a row has "Client" as owner for anything with value (currency, damage, progress), the design is wrong.

## 3. Playbooks

### Obby / parkour
- **Server owns:** stage index, best times, checkpoint validity. **Client owns:** Humanoid movement, moving-platform visuals.
- **Data:** `{ Stage: number, BestTimes: { [stage]: seconds }, Skips: number }`.
- **Technique:** checkpoints as tagged parts; server accepts stage **N only from N−1** and only if the run time is humanly possible (per-stage minimum time). Moving platforms tweened on the client from a shared server time to avoid physics jitter; killbricks via server-side touch + debounce.
- **Exploit:** teleport to the end → sequential validation + time sanity; flag, don't instantly ban.
- **Monetization:** skip-stage developer product (ProcessReceipt), trails, gravity coil-style cosmetics. **Live-ops:** new stage packs, seasonal towers.

### Simulator (incremental / pets)
- **Server owns:** currency, multipliers, pets, hatch RNG, rebirths. **Client owns:** orb/coin visuals, pet-follow animation, egg animation *after* the server result arrives.
- **Data:** `Currency`, `Rebirths`, `Pets = { [uid]: { id, level, shiny } }`, `Equipped = { uid }`, `Zone`.
- **Technique:** replicate aggregates (one coins value), never one remote per coin; collect via server proximity checks at 5–10 Hz or client request + rate limit + distance.
- **Exploit:** auto-farm → per-player collect rate limit + proximity; consider *selling* auto-collect so the exploit is worthless.
- **Numbers:** zone income 1.5–3× previous; first upgrade < 30 s; rebirth when next upgrade > ~10 min.
- **Monetization:** 2× currency pass, luck boosts, extra pet slots, limited eggs (show odds; see monetization-policy). **Live-ops:** weekly egg/zone, limited event pets.

### Tycoon
- **Server owns:** plot assignment, purchased buttons, income timer. **Client owns:** optional dropper visuals.
- **Data:** `{ Purchased = { [buttonId]: true }, Cash, Rebirths }` — save IDs, rebuild the plot from the template on join.
- **Technique:** plot pool from ServerStorage; buttons appear by prerequisite graph; income accrues as `rate × elapsed` on collect (no per-drop parts on the server for large tycoons).
- **Exploit:** button double-fire → ownership + prerequisite + funds checks under a per-player busy lock.
- **Monetization:** 2× cash, auto-collect, VIP areas.

### Round-based (minigames, murder-mystery-style, battle royale)
- **Server owns:** state machine (Lobby → Intermission → Round → Results), roles, map choice, eliminations. **Client owns:** UI, countdowns computed from `endsAt - workspace:GetServerTimeNow()`.
- **Technique:** replicate `Phase` and `EndsAt` attributes once per phase; maps streamed from ServerStorage; join-in-progress rules; minimum player count; AFK handling.
- **Exploit:** role leak → **never replicate secret roles globally**; send each player only their own role.
- **Monetization:** cosmetics, effects, private servers; avoid pay-to-win roles.

### Shooter / melee / fighting
- **Server owns:** damage, ammo, cooldowns, hit validation. **Client owns:** aim, recoil, prediction, VFX/SFX.
- **Technique:** follow Roblox's Laser Tag curriculum — client raycasts for feel; server re-derives spread, checks angle error, shooter-origin distance (moving shooters drift ~2–5 studs) and target-hit distance against tolerances, and re-raycasts for line of sight. Competitive games add a capped rewind buffer of hitbox CFrames. Use **Server Authority** for movement in competitive titles.
- **Projectiles:** FastCast is no longer maintained; use a maintained successor or a simple server-validated raycast stepper.
- **Exploit:** silent aim / wallbang → angle tolerance + LOS re-raycast; rapid fire → server fire-rate check per weapon.
- **Monetization:** cosmetics, battle pass; **no pay-to-win stats**.

### Tower defense / horde
- **Server owns:** enemy tables `{ id, pathProgress | spawnTime, hp, speed }`, tower placement, money. **Client owns:** enemy models, positioned from `spawnTime + speed × elapsed` along the path.
- **Technique:** send **spawn/death/hit deltas**, not positions per frame; clients interpolate. Reported smooth to ~1,000 enemies; the bottleneck becomes **tower targeting** → use a spatial index (grid/quadtree) and target at 5–10 Hz.
- **Placement validation:** server-repeatable raycast into a placement zone, overlap check against existing towers, per-player serialized placements, ownership of the tower type, funds.
- **Monetization:** unit crates (odds disclosure), 2×/3× speed.

### Horror (co-op / story)
- **Server owns:** monster AI and its network ownership (`SetNetworkOwner(nil)` outside Server Authority), seeded room generation, objectives. **Client owns:** lighting, local jumpscares, audio.
- **Technique:** chase by raycast when in line of sight, pathfinding (`CreatePath` + `ComputeAsync`) otherwise, recomputed on `path.Blocked`; audio-first design with the Audio API; short sessions (10–20 min).
- **Exploit:** client-owned monster → server ownership.
- **Monetization:** revives, cosmetics; no ads that break tension.

### RPG / adventure
- **Server owns:** quests, inventory (item IDs + rolled stats), NPC AI (5–10 Hz), loot rolls. **Client owns:** animation, interpolation, UI.
- **Technique:** StreamingEnabled with `ModelStreamingMode = Persistent/Atomic` only for quest-critical NPCs; data-driven quest definitions; session lock + atomic trades.
- **Exploit:** inventory dupes → session lock, no yields between check and mutate, two-profile atomic trades.
- **Monetization:** inventory space, convenience, cosmetics.

### Farming / idle (2025–26 breakout format)
- **Server owns:** plots, growth as `plantedAt + duration` (timestamp, not a ticking loop), mutations, weather events.
- **Technique:** **global restock derived from time** — `slot = math.floor(os.time() / 300)` seeds `Random.new(slot)` so every server shows the same stock without messaging. Offline growth falls out of timestamps.
- **Exploit:** buy from stale stock → recompute the current slot on every purchase.
- **Monetization:** instant restock product, luck/weather boosts. **Live-ops:** fixed weekly update slot + hour-long "admin abuse" style live event.

### Steal / base-plot
- **Server owns:** base lock expiry timestamps, carried-item attachment, slot income as `rate × elapsed` (lazy, computed on collect).
- **Exploit:** remote "steal" from anywhere → server proximity + lock-expiry + carrier-state checks.
- **Monetization:** lock extensions, special units.

### Fishing
- **Server owns:** the catch roll **at cast time** (weighted table), rod/bait stats. **Client owns:** cast/reel minigame visuals.
- **Technique:** accept "reel success" only inside a plausible time window from the cast; minigame difficulty from server-rolled fish.
- **Exploit:** macros → per-rod rate limit; consider selling auto-fish.

### Dress-up / judging
- **Server owns:** outfit as an item-ID list with a server-enforced cap, round state, votes.
- **Exploit:** vote rings → one vote per voter per target, ignore self-votes, weight by participation.
- **Monetization:** item-cap pass, theme picks.

### Survival co-op (session-based)
- **Server owns:** session world state (fuel, resource nodes, day clock). Little or no persistence beyond meta-unlocks → low DataStore risk.
- **Monetization:** classes, cosmetics.

### Social hangout / roleplay
- **Server owns:** housing plots, jobs, permissions. All player text through **TextChatService**; filter every sign/name.
- **Policy:** chat requires age checks; **never make core gameplay depend on chat**. Content questionnaire matters for reach.

## 4. Cross-genre patterns

- **Timestamp state** (growth, cooldowns, offline income, lock expiry) beats ticking loops: cheaper, survives server hops, naturally offline-friendly.
- **Deterministic global schedules** (`floor(os.time()/period)` seeds) give synchronized shops/events across servers without MessagingService.
- **Client-rendered hordes**: server simulates plain tables, replicates events; clients render (TD, RTS with 16-bit packed positions, conveyor belts).
- **Make cheating worthless**: sequential checkpoints, server-computed damage, reduced rewards for spawn-killing, selling convenience that exploiters would script.

## 5. Benchmarks (GameAnalytics 2025 Roblox report)

Median retention D1 10.3%, D7 1.6%, D30 0.5%; top 1% D1 22.2%, D7 9.1%, D30 4.7%. The biggest 2025 gains came from **return frequency** (reasons to come back daily) rather than session length.
