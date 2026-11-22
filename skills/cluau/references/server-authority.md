# Server Authority (2026) — Engine-Level Prediction & Anti-Movement-Cheat

> Last verified: 2026-11-22 against Roblox/creator-docs @ a23352b (docs snapshot 2026-11-21). Re-verify with `tools/verify_api_refs.py`.

Verified against `Roblox/creator-docs` (2026-11-21). Server Authority reached full release on **2026-07-09**.

## Contents
1. What it is and what it is not
2. When to recommend it (per genre)
3. Turning it on (Studio-only property)
4. Code shape: `BindToSimulation`
5. Rules that keep the simulation pure
6. Limits and costs
7. Migration checklist

---

## 1. What it is — and what it is not

- The server is the single source of truth for simulation state; **clients only send inputs**. The client predicts locally and, when the server disagrees, **rolls back and resimulates**.
- It blocks whole classes of movement cheats (fly, speed, teleport, noclip through owned physics) because client-owned physics no longer decides outcomes.
- It does **not** validate RemoteEvents, economy, inventory, purchases, prompts, trades or chat. *"RemoteEvents are not part of the simulation and are not rolled back."* Everything in `networking-security.md` still applies.

## 2. When to recommend it

| Game type | Recommendation |
|---|---|
| Competitive shooter, fighting, racing, sports, PvP movement | **Default on** for new projects |
| Physics puzzle / co-op with shared physics objects | Recommended after a prototype |
| Obby, simulator, tycoon, social hangout | Optional — classic architecture + server sanity checks is simpler |
| Existing large game | Only with a migration plan and profiling; never as a drive-by change |

State the trade-off in one line: stronger anti-cheat and smoother contested physics vs. a stricter coding model, resimulation CPU cost, and some features (Tools) still maturing.

## 3. Turning it on

In Studio: **Workspace → AuthorityMode = Server**. Scripts cannot set it. It automatically enables:
`StreamingEnabled`, `NextGenerationReplication`, `Workspace.PlayerScriptsUseInputActionSystem` (Input Action System), `SignalBehavior = Deferred`, and `UseFixedSimulation`.

Tell the user exactly this property change; don't pretend code can do it.

## 4. Code shape

Shared simulation code lives in a **ReplicatedStorage ModuleScript** required by both a server Script and a client LocalScript, bound with `RunService:BindToSimulation(fn, frequency, priority)`:

```lua
--!strict
-- ReplicatedStorage/Shared/Simulation/Dash (ModuleScript) — required by server AND client.
local RunService = game:GetService("RunService")

local Dash = {}

local DASH_COOLDOWN = 1.5
local DASH_SPEED = 80

-- Simulation state lives in ATTRIBUTES written only inside bound functions (they roll back).
local function step(deltaTime: number)
	for _, character in workspace:GetChildren() do
		local root = character:FindFirstChild("HumanoidRootPart")
		if root == nil or not root:IsA("BasePart") then
			continue
		end
		local wantsDash = character:GetAttribute("WantsDash") == true -- set from input actions
		local lastDash = character:GetAttribute("LastDash") :: number? or -math.huge
		local now = time() -- synchronized + rewinds on resimulation; NOT os.clock()/tick()/os.time()
		if wantsDash and now - lastDash >= DASH_COOLDOWN then
			character:SetAttribute("LastDash", now)
			root:ApplyImpulse(root.CFrame.LookVector * DASH_SPEED * root.AssemblyMass)
		end
	end
end

function Dash.Start()
	-- Default frequency is Hz30. Pass Hz60 explicitly for responsive action games.
	RunService:BindToSimulation(step, Enum.StepFrequency.Hz60)
end

return Dash
```

Treat this as a shape, not a drop-in: map inputs through the Input Action System, scope work to the characters you own, and follow Roblox's Soccer template for a complete reference.

## 5. Rules inside bound functions

1. **Only synchronized reads/writes.** Reading or writing unsynchronized properties or calling unsynchronized methods errors on purpose. Store state in attributes; apply visual-only properties in `PostSimulation`/`RenderStepped` by reading those attributes.
2. **Time = `time()`.** Never `os.clock()`, `tick()`, `os.time()` for simulation logic.
3. **No cached AnimationTracks.** Query `Animator:GetTrackByAnimationId()` each time (tracks may be recreated on resimulation).
4. **Deterministic spawning ("instance stitching").** Predicted objects get deterministic GUIDs so the client's predicted instance is matched to the server's.
5. **Smooth corrections visually.** Use a visual-only copy/offset for rendering so rollbacks don't snap the camera.
6. **Validate inputs on the server** exactly as you would remote arguments (range, rate, state).
7. **Handlers must be correct under Deferred signals** — no logic that assumes an event fires synchronously.

## 6. Limits and costs (as documented / reported)

- Default simulation frequency 30 Hz; set `Enum.StepFrequency.Hz60` explicitly when needed.
- Predicted attributes: among an instance's first 64, names/values capped at 50 characters (community reference).
- An Animator plays at most 8 tracks under Server Authority (community reference).
- Resimulation can cost up to ~6.25× simulation load at 100 ms latency (Roblox deep-dive) — profile with realistic ping.
- Tools: official docs say "not fully supported yet"; prefer input-action-driven abilities.

## 7. Migration checklist

- [ ] Move movement/physics logic into shared bound modules; delete client-trusted movement remotes.
- [ ] Replace `os.clock()`/`tick()` in simulation with `time()`.
- [ ] Convert ContextActionService/UserInputService gameplay bindings to InputContexts/InputActions.
- [ ] Re-test all event handlers under Deferred signals.
- [ ] Re-test streaming assumptions (client `WaitForChild` everywhere).
- [ ] Profile server CPU at 100–200 ms simulated latency with full player count.
- [ ] Keep every RemoteEvent validator — Server Authority doesn't replace them.
