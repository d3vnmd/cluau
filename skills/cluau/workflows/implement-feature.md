# Workflow: implement a feature

1. **Inspect first.** Read the existing structure and conventions (Studio MCP `search_game_tree`/`script_grep`,
   or the files the user shared). Follow them unless unsafe. Scale the change to the risk — a small fix gets a
   small diff.
2. **Plan (≤ 5 bullets):** server vs client, remotes (intent names), data fields, failure modes (leave mid-action,
   spam, streaming, respawn, shutdown). Ownership-map row for every new piece of state.
3. **Sharp edges:** scan `references/sharp-edges.md` rows for the touched areas.
4. **Write** complete code; prefer adapting a template (SKILL.md §10). Pure logic → a separate module that can be
   unit-tested (tests/luau pattern).
5. **Verify:** `scripts/luau_lint.py` → `scripts/audit_project.py` (remote table) → independent reviewer for
   remotes/data/purchases/trades → Studio MCP verify loop if connected (studio-mcp.md §3).
6. **Report:** files + exact locations, setup steps, test plan (Server & Clients, phone, gamepad), what was
   actually checked, known limitations.
