# Open Cloud — Automating a Roblox Game From Outside

> Last verified: 2026-11-23 against Roblox/creator-docs (`cloud/auth/api-keys.md`, `cloud/guides/usage-place-publishing.md`, data-store limits).

Open Cloud is Roblox's web API: publish places from CI, read/patch player data for support, broadcast to all servers, manage products, ban users, run Luau in a cloud server for tests. Use it for **ops and tooling**, never as a hidden channel from game clients.

## Contents
1. Authentication & key hygiene
2. Endpoint map (what to automate)
3. Rate limits and 429 handling
4. CI/CD: publish a place
5. Support tooling: player data without breaking session locks
6. Calling Open Cloud from inside a game
7. Security checklist

---

## 1. Authentication

- **API keys** (most automation): header `x-api-key: <key>`. Created in Creator Dashboard → Credentials → API Keys. A key can do what its owner can; restrict scopes to specific experiences and the minimum operations.
- **OAuth 2.0**: apps acting for *other* users.
- Legacy cookie auth: never for production.

Key hygiene:
- One key per application/pipeline; minimum scopes; experience-restricted where possible.
- IP restrictions (CIDR) for CI runners — **not** for keys used from Roblox game servers (their IPs aren't predictable).
- Keys **auto-expire after 60 days unused or unmodified** — scheduled jobs that run rarely silently break; rotate or touch them.
- Group games: generate the key from a dedicated account that only has the needed group role.
- Store keys in CI secrets / a secrets manager; in-game, only via the **Secrets Store** (`HttpService:GetSecret`) on the server.

## 2. Endpoint map (base `https://apis.roblox.com/cloud/v2/...` unless noted)

| Goal | API |
|---|---|
| Publish a place from CI | Assets API `PATCH https://apis.roblox.com/assets/v1/assets/{placeId}` with the place file (see §4), then poll the returned operation |
| Restart servers after a hotfix | `RestartUniverseServers` |
| Broadcast to every server | `PublishUniverseMessage` (external counterpart of MessagingService) |
| Support: inspect/fix player data | Data store entries (`GetDataStoreEntry`, `UpdateDataStoreEntry`, revisions/`ListDataStoreEntryRevisions`), `SnapshotDataStores` before risky changes |
| Leaderboards / live state | Ordered data stores, memory store sorted maps/queues, `FlushMemoryStore` |
| Moderation | User restrictions (bans) list/get/update + logs |
| Monetization ops | Create/update developer products and game passes |
| Tests in the real engine | Luau Execution session tasks (`universe.place.luau-execution-session:*` scopes) |
| Live config | Configs API (pairs with ConfigService in game) |

## 3. Rate limits and 429s

- Responses carry `x-ratelimit-limit`, `x-ratelimit-remaining`, `x-ratelimit-reset` (seconds until the quota resets).
- On HTTP 429: wait at least `x-ratelimit-reset` seconds (plus jitter), then retry; never hammer.
- **Data store calls from Open Cloud share the same per-experience budget as live game servers** (July 2026 change). A support script that loops over thousands of keys can starve live servers' saves — throttle it, run off-peak, and prefer snapshots/exports.

## 4. CI/CD: publish a place

```bash
# Build with Rojo, then publish (API key needs the place-publish scope for this experience)
rojo build default.project.json -o game.rbxl
curl --fail --location --request PATCH "https://apis.roblox.com/assets/v1/assets/${PLACE_ID}" \
  --header "x-api-key: ${ROBLOX_API_KEY}" \
  --form "request={\"assetId\": ${PLACE_ID}, \"assetType\": \"Place\", \"published\": true}" \
  --form 'fileContent=@game.rbxl;type=application/octet-stream'
# Response: { "path": "operations/{operationId}" } → poll GET https://apis.roblox.com/assets/v1/operations/{operationId}
```

Gate production publishes behind a manual approval; publish to a staging place on every merge. Never let CI and humans edit the same place by hand ("fully managed" Rojo).

## 5. Support tooling without breaking session locks

Player data written by a session-locked DataService must not be overwritten while a server holds the lock:
- Read freely (`GetDataStoreEntry`).
- To fix data: only when the player is **offline and the lock is released/expired**; write through `UpdateDataStoreEntry` keeping the record shape (`{ Data, Lock }`), bump nothing else, and log the change.
- Prefer a "grant" mechanism the game applies on next load (e.g. ProfileStore `MessageAsync`, or a support MemoryStore queue the DataService reads in a load step) over editing records directly.

## 6. From inside a game

`HttpService` can call Open Cloud with a key from the Secrets Store (`HttpService:GetSecret("name")` — server-only, URL/headers only, can be domain-restricted). Use it sparingly (e.g. a cross-experience feature); most in-game needs have native services (DataStoreService, MessagingService, MemoryStoreService) that don't spend Open Cloud quota or risk key leaks.

## 7. Security checklist

- [ ] No key in source control, Studio scripts, ReplicatedStorage or attributes.
- [ ] Minimum scopes; experience-restricted; IP-restricted for CI.
- [ ] Rotation plan for the 60-day auto-expiry.
- [ ] Write scopes (publish, data, bans) only in protected CI jobs or with a human in the loop.
- [ ] 429 handling with `x-ratelimit-reset`; throttled bulk jobs.
