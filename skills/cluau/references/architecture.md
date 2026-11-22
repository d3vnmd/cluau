# Architecture — Where Code Lives and Why

## Contents
1. The replication model in one page
2. Container cheat-sheet
3. Default project layout
4. Service/Controller pattern
5. State & replication strategies
6. StreamingEnabled
7. Lifetimes & cleanup
8. Rojo / Wally / toolchain (optional)
9. Scaling to multiple places

---

## 1. The replication model

- The **server** owns the authoritative DataModel. Changes it makes to replicated containers (Workspace, ReplicatedStorage, Players, Lighting, Teams, StarterX copies) replicate to clients.
- A **client** can change anything locally; those changes **do not replicate** — with two exceptions you must design around:
  1. **Network ownership** of physics: the client owns its character and any unanchored parts the server assigns to it (or auto-assigns near it). Physics state of owned parts replicates. That's why exploiters can fly/teleport — you validate on the server.
  2. **Some character-related properties and animations** replicate from the owning client (Animator tracks, Humanoid states, tool equip via Humanoid).
- RemoteEvents/RemoteFunctions are the only intentional client→server communication.
- `ServerScriptService` and `ServerStorage` never replicate. Clients can't see code or assets there.
- `ReplicatedStorage`, `ReplicatedFirst`, `StarterPlayerScripts`, `StarterGui` contents are **fully readable** by any client (including ModuleScript source). Never put secrets or server logic there.

## 2. Container cheat-sheet

| Container | Replicates to client | Runs Scripts | Runs LocalScripts | Use for |
|---|---|---|---|---|
| `Workspace` | yes (streamed) | yes | only inside a player's Character | The 3D world |
| `ServerScriptService` | no | yes | no | Server code |
| `ServerStorage` | no | no | no | Server-only assets, maps, NPC templates |
| `ReplicatedStorage` | yes | no (modules only via require) | no | Shared modules, remotes, assets both sides need |
| `ReplicatedFirst` | yes (first) | no | yes | Loading screen only |
| `StarterPlayer.StarterPlayerScripts` | copied to each player's `PlayerScripts` folder | no | yes | Client bootstrap & controllers (persist across respawn) |
| `StarterPlayer.StarterCharacterScripts` | copied into each character | yes | yes | Per-character scripts (reset on respawn) |
| `StarterGui` | copied to `PlayerGui` | no | yes | ScreenGuis (`ResetOnSpawn = false` for most HUDs!) |
| `StarterPack` | copied to Backpack | – | yes (inside Tools) | Default tools |
| `Lighting`, `SoundService`, `Teams`, `Chat`/`TextChatService` | yes | – | – | Config |

`Script.RunContext`: setting `RunContext = Client` lets a `Script` run on the client from places like ReplicatedStorage/Workspace. Prefer the conventional containers unless you have a reason; mixing contexts confuses beginners.

`ScreenGui.ResetOnSpawn` defaults to `true` — HUDs and shops vanish and re-create on every death, breaking references held by controllers. Set it to `false` for persistent UI.

## 3. Default project layout

```
ReplicatedStorage
└─ Shared                      (Folder)
   ├─ Config                   (ModuleScript)  frozen game tuning, item tables, prices
   ├─ Types                    (ModuleScript)  export types shared by both sides
   ├─ Net                      (ModuleScript)  remote registry (templates/shared/Net.luau)
   ├─ Guard                    (ModuleScript)  validation helpers
   ├─ RateLimiter              (ModuleScript)
   ├─ Trove                    (ModuleScript)  cleanup helper
   └─ UI                       (Folder)
      ├─ Theme                 (ModuleScript)
      └─ Components            (ModuleScript)
ServerScriptService
├─ Main                        (Script)        bootstrap
└─ Services                    (Folder)
   ├─ DataService              (ModuleScript)
   ├─ MonetizationService      (ModuleScript)
   └─ <Feature>Service         (ModuleScript)
ServerStorage
└─ Assets / Maps / NPCs
StarterPlayer
└─ StarterPlayerScripts
   ├─ Main                     (LocalScript)   bootstrap
   └─ Controllers              (Folder)
      ├─ UIController          (ModuleScript)
      ├─ InputController       (ModuleScript)
      └─ <Feature>Controller   (ModuleScript)
```

Why one bootstrap per side: deterministic load order, a single place to catch init errors, easy dependency passing, and no "this Script ran before that one" races.

## 4. Service/Controller pattern (framework-free)

```lua
-- ServerScriptService/Main (Script)
--!strict
local ServerScriptService = game:GetService("ServerScriptService")

local servicesFolder = ServerScriptService:WaitForChild("Services")
local ORDER = { "DataService", "MonetizationService", "ShopService" } -- explicit order

local loaded = {}
for _, name in ORDER do
	local module = servicesFolder:FindFirstChild(name)
	if module and module:IsA("ModuleScript") then
		local service = require(module) :: any
		if type(service.Init) == "function" then
			service.Init()
		end
		table.insert(loaded, service)
	else
		warn(`[Main] Missing service module: {name}`)
	end
end
for _, service in loaded do
	if type(service.Start) == "function" then
		task.spawn(service.Start)
	end
end
```

- Don't adopt Knit/AeroGameFramework for new projects: Knit was archived in July 2024 and is unmaintained. Plain modules + explicit order are enough (this is also the shape of Roblox's own Plant reference project).
- Services may require each other **inside `Start`** or after Init to avoid cycles.
- Each Service exposes a small, typed API; other services never reach into its private tables.

## 5. State & replication strategies

| Data | Best transport |
|---|---|
| A few numbers per player visible to everyone (coins, level) | `leaderstats` IntValues or `player:SetAttribute` |
| Private per-player state (inventory, quests) | Server → owning client RemoteEvent with full snapshot on join, then deltas |
| World state (round phase, timer end time) | Attributes on a replicated Folder (`ReplicatedStorage.GameState:SetAttribute("RoundEndsAt", serverTime)`) — clients compute countdown locally from `workspace:GetServerTimeNow()` |
| High-frequency cosmetic (aim direction) | `UnreliableRemoteEvent`, throttled 10–20 Hz |
| Per-instance flags (door open, owner) | Attributes on the instance |

**Timers**: never fire a remote every second for a countdown. Replicate the end timestamp once; clients render `endsAt - workspace:GetServerTimeNow()`.

## 6. StreamingEnabled

On by default for new places. Consequences:

- Client `workspace.Map.Shop` may be `nil`. Use `WaitForChild` (with timeout) or listen for it to stream in.
- Parts streamed out are destroyed on the client; local references go stale. Re-acquire via CollectionService signals.
- `Model.ModelStreamingMode`: `Atomic` (all-or-nothing), `Persistent` (always present for all players — use sparingly), `PersistentPerPlayer` (server controls via `Model:AddPersistentPlayer`), `Nonatomic` (default).
- `Player:RequestStreamAroundAsync(position)` on the server before teleporting a player across the map.
- Server-side code is unaffected (server has everything).

## 7. Lifetimes & cleanup

Every `Connect` belongs to something that will end:

| Lifetime | End signal | Clean with |
|---|---|---|
| Player session | `Players.PlayerRemoving` | per-player Trove |
| Character life | `player.CharacterRemoving` / `humanoid.Died` | per-character Trove |
| UI screen | screen closed | screen Trove |
| Instance | `inst.Destroying` | Trove attached to instance |
| Round | round end | round Trove |

Memory leak smells: tables keyed by `Player` never cleared on leave; connections to `RunService` created per spawn; tweens referencing destroyed instances; UI rows created per update without destroying old ones.

## 8. Rojo / Wally / toolchain (optional, for external editors)

- **Rokit** (toolchain manager) → pins `rojo`, `wally`, `selene`, `stylua`, `lune` versions in `rokit.toml`.
- **Rojo**: sync files ↔ Studio. `default.project.json` maps folders to services (see `assets/project/default.project.json`).
- **Wally**: package manager (`wally.toml`). Common, well-maintained packages: `sleitnick/trove`, `sleitnick/signal`, `evaera/promise`, `lukadev-0/...`. ProfileStore is distributed via the Creator Store / GitHub; vendor it.
- **Selene**: linter (`selene.toml` with `std = "roblox"`). **StyLua**: formatter. **luau-lsp**: language server for VS Code with Roblox type definitions.
- Studio-only users are first-class: everything in this skill works without these tools.

## 9. Scaling to multiple places

- Lobby place + game places under one Experience; share code via Packages (Studio) or Rojo multi-project.
- `TeleportService:TeleportAsync` with `TeleportOptions:SetTeleportData` (teleport data is **client-visible and spoofable** — validate on arrival or pass via MemoryStore keyed by reserved server access code).
- Matchmaking: `MemoryStoreService` queue/sorted map + `TeleportAsync` with `TeleportOptions.ReservedServerId = HttpService:GenerateGUID(false)` (the old `ReserveServer` APIs are deprecated); store the GUID in MemoryStore so late joiners can follow.
