# System design: <system>

## Scope and existing code
<What exists, conventions to follow, what changes.>

## Ownership map
| State | Owner (writes) | Lives on | Replicated how | Persisted? |
|---|---|---|---|---|

## Remotes (intent-named)
| Remote | Direction | Args (types, bounds) | Rate limit | Server checks |
|---|---|---|---|---|

## Data shape & migration
```lua
-- fields, defaults, Version bump, migration step
```

## Failure modes
| Scenario | Handling |
|---|---|
| Player leaves mid-action | |
| Remote spam / bad args | |
| DataStore failure / throttle | |
| Server shutdown | |
| Streaming / respawn | |

## Performance budget
<entities, Hz, bytes per update, draw calls>

## Verification
- Unit tests (pure logic):
- Lint / audit / independent review:
- Playtest steps (Server & Clients, phone, gamepad):

## Open questions
