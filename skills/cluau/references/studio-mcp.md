# Studio MCP — Let Claude Inspect, Edit and Playtest Roblox Studio

> Last verified: 2026-11-23 against Roblox/creator-docs `studio/mcp.md` and `studio/mcp-open-cloud.md`.

Roblox Studio ships a built-in MCP server. With it connected, Cluau stops *guessing* and starts *verifying*: read the real place, make the edit, playtest, read Output, and look at the screen.

## Contents
1. Setup (Studio + Claude Code / Claude Desktop)
2. Tool map
3. The verify loop (use for every non-trivial change)
4. Safety rules (what always needs the user's yes)
5. Open Cloud through MCP
6. Troubleshooting

---

## 1. Setup

1. Studio → **Assistant** → **…** → **Manage MCP Servers** → turn on **Enable Studio as MCP server**.
2. Connect a client: **Quick connect** supports Claude Code, Claude Desktop, Codex CLI, Cursor, Gemini CLI, VS Code, Antigravity (Assistant Settings → MCP Servers → Quick connect). Otherwise add the `Roblox_Studio` entry to the client's MCP JSON config, or use the client's CLI command shown in that panel. Restart the client afterwards.
3. Studio shows a green indicator with the number of connected clients. Several Studio windows can be open: use `list_roblox_studios` and pick the right one.

Only connect clients you trust: MCP clients can read and modify open places.

## 2. Tool map

| Need | Tools |
|---|---|
| Orient | `list_roblox_studios`, `get_studio_state`, `search_game_tree`, `inspect_instance` |
| Read code | `script_search` (fuzzy by name, ≤10), `script_grep` (pattern across scripts, ≤50), `script_read` (dot-path like `game.ServerScriptService.Main`) |
| Change code | `multi_edit` (several edits in one operation; creates the script if missing; Edit datamodel) |
| Run code | `execute_luau` with `datamodel_type` Edit, Client or Server |
| Playtest | `start_stop_play`, `get_console_output`, `screen_capture`, `character_navigation`, `user_keyboard_input`, `user_mouse_input` |
| Assets | `search_asset`, `insert_asset`, `generate_mesh`, `generate_material`, `generate_procedural_model` + `wait_job_finished`, `generate_avatar`, `generate_animation` (≤10 s), `upload_image`, `store_image` |
| Docs | `http_get` (allowed Roblox docs URLs), `skill` (Roblox's own guidance) |
| Delegate | `subagent` (`explore`, `playtest`) |
| Persist | `save_place` (**ask first**) |

## 3. The verify loop

```
1. list_roblox_studios → get_studio_state            (right place? edit or play mode?)
2. search_game_tree / script_grep / script_read       (read before you write; follow existing conventions)
3. multi_edit                                         (one writer at a time — not while Rojo/Script Sync also writes)
4. luau lint locally if available (scripts/luau_lint.py on exported code)
5. start_stop_play (start) → reproduce with character_navigation / user_*_input
6. get_console_output                                  (errors? warnings? your [System] logs?)
7. screen_capture                                       (UI on screen? overlaps? safe areas?)
8. start_stop_play (stop) → fix → repeat from 3
9. Report exactly what ran and what it showed; never claim checks you didn't run.
```

Tips:
- `execute_luau` in **Edit** mutates the place — read-only queries are fine; writes should go through `multi_edit` so they're reviewable.
- For server logic, run in **Server** during play; for UI/input, **Client**.
- Multi-player behavior (trades, rounds, replication) still needs Studio's **Server & Clients** test — say so if MCP couldn't cover it.

## 4. Safety rules — always ask the user first

- `save_place` (creates a new place version) and anything that publishes.
- `upload_image` / uploading any asset (moderation applies to the account).
- `insert_asset` of Creator Store items that contain scripts — inspect for `require(<id>)`, `loadstring`, `getfenv`, `LinkedSource` first (assets-pipeline.md §10).
- Deleting user content or large refactors across many scripts.
- Open Cloud write scopes (below).
Stage generated/inserted assets in `ServerStorage/_AssetStaging`; quarantine rejects in `ServerStorage/_AssetQuarantine` (assets-pipeline.md §12).

## 5. Open Cloud through MCP

The server adds `open_cloud_invoke` (method, endpoint, body, scopes, files). Studio manages credentials — the client never sees an API key. Permissions are saved per published game: the user decides which scopes are allowed, which local folders can be uploaded from, and whether `execute_luau` may call DataStores/MemoryStores or make HTTP requests. Group games require a group role that allows the granted actions. Treat every write scope as a "ask first" action.

## 6. Troubleshooting

| Symptom | Check |
|---|---|
| No tools in the client | MCP server enabled in Studio? Client restarted after adding config? |
| Edits land in the wrong place | `list_roblox_studios` — several Studio windows are open |
| `execute_luau` can't reach DataStores | Permission not granted for this game, or the place isn't published |
| Edits overwritten | Rojo or Script Sync is also writing the same scripts — pick one writer |
