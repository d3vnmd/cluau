# Independent Review — Code Doesn't Grade Its Own Homework

> Last verified: 2026-11-22

The author of a piece of code is the worst person to review it: they read what they *meant*, not what they wrote. Big studios require a second pair of eyes on anything touching money, data, trades or remotes. Cluau reproduces that with a **fresh reviewer that has none of the author's context**.

## Contents
1. When a review is mandatory
2. How to run it (subagent / Claude Code agent / fallback)
3. The reviewer prompt (copy verbatim)
4. Acting on the findings
5. Review checklist by system

---

## 1. When a review is mandatory

| Change touches | Review |
|---|---|
| RemoteEvents / RemoteFunctions, ProximityPrompt/ClickDetector/Touched handlers | **Required** |
| DataStore / ProfileStore / MemoryStore / OrderedDataStore | **Required** |
| ProcessReceipt, game passes, paid random items | **Required** |
| Trading, inventory, currency, rewards | **Required** |
| Round/state machines, teleports, respawn logic | **Required** |
| Pure UI layout, art, copy, docs | Optional (use the UI anti-slop audit instead) |
| One-line fixes | Optional — but re-run the linter |

## 2. How to run it

1. **Claude Code with this plugin installed:** launch the **`cluau-reviewer`** agent (Agent tool, `subagent_type: "cluau-reviewer"`) with the list of changed files.
2. **Any environment that can spawn subagents:** launch a fresh general-purpose agent with the prompt in §3, the file paths, and the absolute paths to `references/sharp-edges.md` and `references/networking-security.md`.
3. **No subagents available (e.g. plain chat):** do a *separate, explicit* adversarial pass after writing: re-read the code top to bottom as an exploiter and as a server crash, using §5. Say in the reply that this was a self-review, not an independent one.

Never skip the linter: `python3 <skill-dir>/scripts/luau_lint.py <files>`.

## 3. Reviewer prompt (verbatim)

```
You are an adversarial senior Roblox reviewer. You did NOT write this code and you assume it is broken
until proven otherwise. Review ONLY for defects that would ship: exploits, item/currency duplication,
data loss, purchase bugs, leaks, crashes, lag, wrong client/server placement, deprecated APIs.

Read first: <skill>/references/sharp-edges.md and <skill>/references/networking-security.md.
Then read every file listed. If you can run commands, run:
    python3 <skill>/scripts/luau_lint.py <files>

For each handler that receives client input, trace: argument types -> rate limit -> state checks ->
ANY yield (task.wait, *Async, InvokeServer) -> mutation. A yield between check and mutation is a bug.
For every Connect, find what disconnects it. For every client read of workspace, ask what happens if it
has not streamed in. For every purchase/trade, ask what happens if the server crashes between steps.

Output, most severe first, one block per finding:
  [CX-id or NEW] [CRITICAL|HIGH|MEDIUM|LOW] file:line
  Failure: concrete scenario (who does what, in what order)
  Consequence: what breaks / who loses what
  Fix: the specific change
Mark each finding OBSERVED (provable from the code) or HYPOTHESIS (depends on unseen code).
No style comments, no "consider using a framework", no praise. If nothing survives, say "No findings"
and list what you checked. Never claim the code was run or tested.
```

## 4. Acting on the findings

- Fix every **CRITICAL** and **HIGH** before replying to the user; re-run the linter (and tests, if any).
- MEDIUM/LOW: fix if cheap, otherwise list them under "Known limitations".
- If the reviewer marks a HYPOTHESIS, check the unseen code or state the assumption explicitly.
- Tell the user a review ran and what it changed, in one or two lines (no wall of text).

## 5. Checklist by system

**Remote handler:** `unknown` params narrowed · NaN/inf rejected · strings via `utf8.len` · instance args checked for class + ancestry + distance · rate limit + server cooldown · no yield between check and mutate · server computes prices/damage/rewards.

**Data:** session lock · load failure kicks, never saves defaults · `UpdateAsync` callbacks pure · `BindToClose` waits for saves · no key-pattern change on live games · budgets read, not hard-coded.

**Purchases:** single `ProcessReceipt` · `PurchaseId` recorded in the locked profile · saved before `PurchaseGranted` · `NotProcessedYet` when unsure · never grant on `PromptProductPurchaseFinished` · odds disclosed for paid random items.

**Trades:** server-owned session · whitelist + bounded offers · version-tied ready · quiet period · re-validate both inventories at execution · atomic two-sided mutation · executing flag · cancel on leave.

**Rounds:** participants updated on death/leave/respawn · per-round connections disconnected · min-player re-checks · `EndsAt` replicated once · maps cleaned up even if the round errors.

**Client:** `WaitForChild` with timeouts for streamed content · `ResetOnSpawn` decided · per-character cleanup on respawn · input contexts switched when menus open.

**Performance:** no per-frame remotes · batching/quantization for dense data · one update loop for many entities · CanvasGroup/flex limits respected.
