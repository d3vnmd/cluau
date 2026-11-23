# Workflow: new game

1. **Brief** (game-design.md §1): fantasy, audience/age, genre, session length, social hook. Ask at most one
   question if the genre is unclear; otherwise propose two directions and pick one.
2. **Genre playbook** (genre-playbooks.md): copy the matching row → server/client ownership, data schema, entity
   budget, top exploits, monetization fit, live-ops hook.
3. **Core loop + first session** (retention-design.md §4): action → reward → progression → reinvestment, with
   timestamps for the first 15 minutes.
4. **Economy table** → run `scripts/economy_sim.py` on it; fix SLOW_START / GRIND_WALL / SPIKE before coding.
5. **Ownership map** (state | owner | lives on | replicated how | persisted) for every system.
6. **MVP plan** (`templates/docs/plan.md`): ≤ 6 systems, build order, what's out of scope.
7. **Scaffold**: `scripts/scaffold.py <dir>` (Rojo) or the Explorer hierarchy for Studio-only users.
8. **Build in order**: data → core loop server → client feedback/UI → monetization → polish. After each system:
   lint → independent review (review-workflow.md) → playtest checklist.
9. **Art direction line + UI tokens** (ui-design-system.md) before the first screen.

**Output:** design brief, economy table + sim result, ownership map, MVP plan, then code system by system.
