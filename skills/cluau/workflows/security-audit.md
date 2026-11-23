# Workflow: security audit

1. **Map:** `python3 scripts/audit_project.py <src>` → remote table (validated / rate-limited / yields), placement
   problems, DataStore map, ProcessReceipt locations.
2. **Lint:** `scripts/luau_lint.py` — CL060, CL073, CL110–CL118 are security rules.
3. **Trace every ❌ handler:** types → rate → state → yield → mutation (networking-security.md §3). Interaction
   handlers (prompts/clicks/touch) need server distance checks. Money paths: ProcessReceipt idempotency, trades
   (TradeService pattern), shop prices from server config.
4. **Data:** session lock, load-failure handling, BindToClose, key pattern, budgets (data-persistence.md).
5. **Movement & physics:** client-owned shared parts, speed/teleport sanity, Server Authority candidates.
6. **Independent reviewer** on the riskiest files (review-workflow.md).
7. **Output:** findings by severity (CX ids, location, scenario, fix), then the fixes, then what remains unverified.
