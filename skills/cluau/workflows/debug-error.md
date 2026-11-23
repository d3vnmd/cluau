# Workflow: debug an error

1. **Get the facts:** exact Output text (path:line, red vs orange), when it happens, Studio vs live, which device.
   Ask for the message and the script if missing — don't guess blind.
2. **Classify** with debugging-testing.md §2 (nil index, infinite yield, wrong container, deprecated API,
   permission, streaming, ResetOnSpawn, yield-in-callback…).
3. **One hypothesis at a time.** Read the failing line and the value before the dot. Check replication
   boundaries (architecture.md §2) and streaming (CX-48).
4. **Reproduce** — with Studio MCP: `start_stop_play` → reproduce → `get_console_output`; otherwise give the user a
   precise reproduction checklist.
5. **Fix the cause, not the symptom** (no blanket `pcall` to hide errors). Explain the cause in 1–2 sentences.
6. **Look around:** list other real bugs seen nearby (security, leaks, deprecated APIs) briefly; run the linter.
7. **Regression:** add a guard, a test (pure logic) or a lint rule if the bug class can recur.
