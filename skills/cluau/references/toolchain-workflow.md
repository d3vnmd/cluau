# Toolchain & Studio Workflow — How Big Teams Ship

> Last verified: 2026-11-22 against Roblox/creator-docs @ a23352b (docs snapshot 2026-11-21). Re-verify with `tools/verify_api_refs.py`.

## Contents
1. Evidence levels (what a check proves)
2. Studio-only workflow (beginners & small teams)
3. Rojo workflow (partially vs fully managed)
4. Toolchain (Rokit, Wally/pesde, Selene, StyLua, luau-lsp, Lune, Jest-Lua)
5. CI/CD shape
6. Studio MCP: verifying instead of asserting
7. Script Sync
8. Team conventions

---

## 1. Evidence levels

| Evidence | Establishes | Does NOT establish |
|---|---|---|
| Generated code / static review | The proposed logic | That it runs |
| cluau-lint | No known deprecated/unsafe patterns | Correctness, security of logic |
| Type checking (luau-lsp with Roblox definitions) | Type compatibility with the configured checker | Runtime payload safety |
| Unit tests (Jest-Lua/TestEZ/Lune) | The tested pure logic | Real replication, physics, persistence |
| Studio multiplayer playtest | Observed engine behavior in that session | All devices / production load |
| Profiling (MicroProfiler, Script Profiler, Scene Analysis) | Measured cost in one workload | Universal speedups |
| Security probing (spamming remotes with bad args) | Those attack paths are closed | Absence of all exploits |

**Report exactly which checks ran and what remains unverified.** Never invent playtests, outputs, or test results. "Silence is not a pass."

## 2. Studio-only workflow

Most Mongolian beginners work only in Studio — that's first-class:
- Give the Explorer hierarchy with instance types for every script.
- Use Packages for reused models; Team Create with Collaborative Editing for teams.
- Back up with File → Save to File (`.rbxl`) before big changes; use place version history.

## 3. Rojo

- **Partially managed:** code lives in Git and syncs via Rojo; the place (maps, models, UI built in Studio) lives in Roblox. Best default for most teams.
- **Fully managed:** the entire place is built from the repo; **places are never edited by hand**; CI builds and publishes.
- Don't run two writers at once (Rojo sync + Script Sync / MCP edits on the same scripts).
- `assets/project/default.project.json` + `scripts/scaffold.py` set up the cluau layout.

## 4. Toolchain

| Tool | Role |
|---|---|
| **Rokit** | pins tool versions per repo (`rokit.toml`) |
| **Rojo** | file ↔ Studio sync / place builds |
| **Wally** or **pesde** | packages |
| **Selene** | lint (`std = "roblox"`) |
| **StyLua** | format |
| **luau-lsp** | language server + `analyze` with Roblox type definitions |
| **Lune** | run Luau scripts outside Roblox (build tooling; *not* a full engine) |
| **Jest-Lua** / TestEZ | unit tests (don't assume bare `describe/it/expect` globals exist) |
| **cluau-lint** | deprecated/unsafe/UI-slop patterns from official docs |

## 5. CI/CD shape

1. Branch → PR.
2. CI: StyLua check → Selene → cluau-lint → `luau-lsp analyze` → Rojo build.
3. Engine tests via the **Open Cloud Luau Execution API** on a test place (optional but best).
4. Merge to main → publish to a **dev/staging** place automatically.
5. **Gated** promotion to production (manual approval).
Nobody edits CI-owned places by hand.

## 6. Studio MCP — verify instead of assert

Studio ships a built-in MCP server (enable under Assistant → Manage MCP Servers) usable from Claude Code/Desktop. When it's connected, verify changes:

1. Find the Studio instance and read state (studio list / state tools).
2. Inspect before editing (`search_game_tree`, `inspect_instance`, `script_grep`).
3. Make the edit (`multi_edit` / script tools) — one writer at a time.
4. `start_stop_play` → reproduce → `get_console_output` for errors → `screen_capture` for UI.
5. `execute_luau` for focused runtime checks (in Edit mode it mutates the place — be careful).
6. Never call `save_place`/publish or upload images without the user's explicit approval (see `assets-pipeline.md` §12).

Without MCP, say "not run in Studio" and give a precise manual test plan.

## 7. Script Sync

Studio's Script Sync (stable 2026-06) edits scripts as local files without Rojo. Pick one sync method per project.

## 8. Team conventions

- One bootstrap per side; services/controllers with `Init`/`Start`.
- Economy mutations take a `reason` argument (for logs and analytics).
- No global "GameManager"; if two systems claim the same state, redesign (ownership map in `genre-playbooks.md`).
- Code review: findings with severity, location, failure scenario, fix (`sharp-edges.md` format). No style-only nits.
