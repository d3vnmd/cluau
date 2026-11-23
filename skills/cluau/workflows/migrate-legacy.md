# Workflow: migrate legacy code

1. **Dry run:** `python3 scripts/migrate_legacy.py <src>` → review the diff (wait→task.wait, :connect→:Connect,
   game.X→GetService, SetPrimaryPartCFrame→PivotTo, pre-2025 names→…Async, …).
2. **Apply:** `--write` (commit or back up first). Strings and comments are never touched.
3. **Manual list:** every `MANUAL` line needs judgement — BodyMovers → constraints (physics-vehicles.md),
   FindPartOnRay/Region3 → Raycast/OverlapParams, PhysicsService → workspace collision groups, legacy teleports →
   TeleportAsync + ReservedServerId, SetAsync player data → session-locked UpdateAsync, legacy chat →
   TextChatService. Use deprecated-apis.md / deprecated-index.md.
4. **Architecture smells** after syntax is modern: 40 loose Scripts → bootstrap + services; client-trusted remotes →
   validators; `_G` state → modules. Do these only if the user wants a refactor; otherwise list them.
5. **Verify:** lint (0 errors), `audit_project.py`, playtest. Report what changed and what remains.
