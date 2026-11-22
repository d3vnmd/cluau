# Roblox data persistence, live ops, analytics and monetization: verified fact sheet (as of Nov 2026)

**How this was researched:** Most facts come from a sparse clone of the official `Roblox/creator-docs` GitHub repo, which is the source of create.roblox.com/docs. Its last commit was **2026-11-21**, so these are the docs as published on that date. Engine API facts come from `content/en-us/reference/engine/classes/*.yaml` in the same repo. Library facts come from shallow clones of each library's GitHub repo. Dates come from web search snippets of Roblox newsroom and DevForum posts. devforum.roblox.com could not be fetched directly in this session (DNS blocked), so DevForum facts rely on search-result excerpts and are marked as such.

URL pattern: the repo file `content/en-us/X.md` is the page `https://create.roblox.com/docs/X`.

---

## 1. DataStores: changes from 2024 to 2026, limits, versioning, tools, RTBF

### Takeaway
On **July 29, 2026**, Roblox merged the in-game and Open Cloud request budgets into one per-experience budget per request type. The base for that budget is now 300 requests/min. The storage limit was raised to **500 MB + 1 MB × lifetime users**, measured on the compressed size of each key's latest version. The old per-server formulas (for example, GetAsync = 60 + numPlayers × 10) are **obsolete**. Servers now have configurable defaults, set with `SetRateLimitForRequestType`, and the categories have new names: StandardRead, StandardWrite, StandardList and StandardRemove, with matching Ordered* categories.

### Cited Findings

**Data and metadata size limits**
- Each of these is limited to 50 characters: data store name, key name and scope. The value is limited to **4,194,304 characters per key** (4 MB), measured as JSON-encoded size. — [Error codes & limits](https://create.roblox.com/docs/cloud-services/data-stores/error-codes-and-limits)
- User metadata limits: key name 50 characters, value 250 characters. The total of all metadata key-value pairs must be 300 characters or fewer. — [same](https://create.roblox.com/docs/cloud-services/data-stores/error-codes-and-limits)
- Throttled requests wait in four queues: Set, Ordered set, Get and Ordered get. Each queue holds **30 requests**. Once a queue is full, new requests fail with error codes **301–306**. — [same](https://create.roblox.com/docs/cloud-services/data-stores/error-codes-and-limits)

**Per-key throughput limits** (applies across all servers, using a rolling 60-second window)
- Reads (GetAsync, GetVersionAsync, GetVersionAtTimeAsync, ListVersionsAsync, and the read half of UpdateAsync): **25 MB per minute per key**.
- Writes (SetAsync, IncrementAsync, UpdateAsync, RemoveAsync): **4 MB per minute per key**.
- Each request's throughput is rounded **up to the next KB**. Throttling shows up as `DatastoreThrottled` or `KeyThrottled`. — [same](https://create.roblox.com/docs/cloud-services/data-stores/error-codes-and-limits)

**Storage limit**
- The formula is `500 MB + 1 MB × lifetime user count`. A lifetime user is anyone who has joined at least once. — [same](https://create.roblox.com/docs/cloud-services/data-stores/error-codes-and-limits)
- Only the **compressed size of each key's latest version** counts. Deleted keys and superseded versions do not count.
  - Exception: data stores deleted through Open Cloud `DeleteDataStore` keep counting during their 30-day deletion window.
  - Docs advise against pre-compressing data: "Pre-compression adds unnecessary CPU overhead and may reduce the effectiveness of data stores' built-in compression."
  - Source: [same](https://create.roblox.com/docs/cloud-services/data-stores/error-codes-and-limits)
  - Community caveat: one DevForum commenter (search excerpt) pointed out that the **4 MB per-key limit is checked against the raw string**, so self-compression still helps a single key fit under 4 MB. — [DevForum thread](https://devforum.roblox.com/t/unifying-data-stores-open-cloud-and-game-apis-and-increasing-storage-limits/4739240)
- History of the change:
  - The **DataStores Access and Storage Updates** post (2025, thread 3597255) announced the first limit, `100 MB + 1 MB × lifetime players`. Roblox said fewer than 30 experiences were expected to be affected. — [DevForum](https://devforum.roblox.com/t/datastores-access-and-storage-updates/3597255) (search excerpt)
  - The base was raised from 100 MB to 500 MB. "As of today, July 29, the increased storage limit and the unified Data Stores limits for Open Cloud and games are officially live." — [DevForum: Unifying Data Stores Open Cloud and Game APIs, and Increasing Storage Limits](https://devforum.roblox.com/t/unifying-data-stores-open-cloud-and-game-apis-and-increasing-storage-limits/4739240); [Weekly Recap July 13–17 "5× more data store storage"](https://devforum.roblox.com/t/weekly-recap-july-13-%E2%80%93-17-animation-graphs-go-live-5%C3%97-more-data-store-storage/4743286) (year inferred as 2026 from thread IDs and the recap title)
- Going over the limit:
  - Creators over the limit who are not on Extended Services "continue consuming storage as an overage and will not be throttled on storage writes." — DevForum search excerpt
  - Data Stores Manager shows **"Est. Monthly Costs"** when Total Size exceeds the Storage Limit. — [Data Stores Manager](https://create.roblox.com/docs/cloud-services/data-stores/data-stores-manager)
- **Conflict to flag:** the Extended Services pricing table still lists data store storage as "100 MB + (1 MB × Lifetime Players)". Its default request formulas, such as "250 + CCU×40" for Get, also differ from the limits page. The limits page and the July 2026 announcement both say 500 MB and base 300, so the Extended Services table looks stale. — [Extended Services](https://create.roblox.com/docs/cloud-services/extended-services)

**Experience-level request budgets** (shared by game servers and Open Cloud, in requests per minute)
- Game server calls and Open Cloud calls draw from the **same** budget, so each can throttle the other. — [Error codes & limits](https://create.roblox.com/docs/cloud-services/data-stores/error-codes-and-limits)

| Category | Standard data stores | Ordered data stores |
|---|---|---|
| Read | **300 + CCU × 40** (GetAsync, GetVersionAsync, GetVersionAtTimeAsync, UpdateAsync) | **300 + CCU × 40** (GetAsync, **BatchGetAsync**, UpdateAsync) |
| Write | **300 + CCU × 20** (SetAsync, IncrementAsync, UpdateAsync) | **300 + CCU × 20** |
| List | **300 + CCU × 2** (ListDataStoresAsync, ListKeysAsync, ListVersionsAsync) | **300 + CCU × 2** (GetSortedAsync) |
| Remove | **300 + CCU × 40** (RemoveAsync; Open Cloud Delete/Undelete Data Store) | **300 + CCU × 40** |

- **UpdateAsync uses both the read and the write budget.**
- For Open Cloud scripts, docs recommend sleeping `60 / desired-rpm` seconds between calls, or using a leaky-bucket limiter. Node.js samples are on the page.
- Source: [same](https://create.roblox.com/docs/cloud-services/data-stores/error-codes-and-limits)

**Server-level default limits** (apply when `SetRateLimitForRequestType` is not called)

| Category | Standard | Ordered |
|---|---|---|
| Read | 60 + numPlayers × 40 | 60 + numPlayers × 40 |
| Write | 60 + numPlayers × 40 | 30 + numPlayers × 5 |
| List | 5 + numPlayers × 2 | 5 + numPlayers × 2 |
| Remove | 60 + numPlayers × 40 | 30 + numPlayers × 5 |

- `RemoveVersionAsync` is **deprecated**; its limit is 5 + numPlayers × 2.
- Servers get a **one-time startup burst** of extra budget.
- Studio Run mode has separate static limits that may be lower. Docs recommend testing in Team Create.
- Source: [same](https://create.roblox.com/docs/cloud-services/data-stores/error-codes-and-limits)

**Configuring server limits with `DataStoreService:SetRateLimitForRequestType(requestType, baseLimit, perPlayerLimit)`**
- The resulting limit is `baseLimit + perPlayerLimit × numPlayers`.
- Call it once per type at server init.
- UpdateAsync and OnUpdate cannot be configured.
- Allowed ranges: new categories (StandardRead … OrderedRemove) accept base [0, 10000] and per-player [0, 200]. Legacy enums keep their old bounds, for example GetAsync base [0, 60] and per-player [0, 40], and GetSortedAsync [0, 5] / [0, 2].
- Use `GetRequestBudgetForRequestType` to read the current budget.
- Source: [DataStoreService reference (yaml)](https://create.roblox.com/docs/reference/engine/classes/DataStoreService)

**New error names**
- `StandardReadExperienceThrottled`, `StandardReadGameServerThrottled`, and the same pair for Write, List and Remove, plus Ordered* equivalents. The legacy names (`GetAsyncThrottle`, `SetAsyncThrottle`, …) are still listed. — [Error codes](https://create.roblox.com/docs/cloud-services/data-stores/error-codes-and-limits)

**New API: `GlobalDataStore:BatchGetAsync(keys)`**
- Works **only on OrderedDataStore**. Calling it on a standard DataStore throws.
- Default maximum of 100 keys per call. It is charged to the OrderedRead budget per key requested.
- Returns `{key = {value = …}}`. Missing keys are omitted. No DataStoreKeyInfo is returned.
- Source: [GlobalDataStore reference](https://create.roblox.com/docs/reference/engine/classes/GlobalDataStore)

**Versioning**
- SetAsync, UpdateAsync and IncrementAsync create a versioned backup **from the first write to each key in each UTC hour**.
- Backups **expire 30 days after they are overwritten**. The latest version never expires.
- RemoveAsync writes a tombstone version. Older versions stay readable through ListVersionsAsync and GetVersionAsync.
- Docs include a sample that restores a key to its state at a timestamp: ListVersionsAsync with a maxDate, then GetVersionAsync, then SetAsync with the metadata copied across.
- Source: [Versioning, listing, caching](https://create.roblox.com/docs/cloud-services/data-stores/versioning-listing-and-caching)

**Snapshots**
- The Open Cloud **Snapshot Data Stores** API snapshots all data stores in a game, at most **once per day**.
- Docs say to "take a snapshot before you publish any game update that changes your data storage logic."
- Source: [same](https://create.roblox.com/docs/cloud-services/data-stores/versioning-listing-and-caching)

**Scopes and prefixes**
- Scopes are legacy. For new games, organize keys with ListKeysAsync and prefixes instead.
- With `DataStoreOptions.AllScopes = true`, the scope argument must be `""` and keys must be written as `scope/key`.
- Source: [same](https://create.roblox.com/docs/cloud-services/data-stores/versioning-listing-and-caching)

**Caching and `DataStoreGetOptions`**
- GetAsync caches values locally for **4 seconds**, per DataStore instance.
- Set `DataStoreGetOptions.UseCache = false` to bypass the cache.
- Docs explicitly recommend `UseCache = false` for verification reads after a write errored, before you decide whether to retry or refund.
- GetVersionAsync, ListVersionsAsync, ListKeysAsync and ListDataStoresAsync are never cached.
- Source: [same](https://create.roblox.com/docs/cloud-services/data-stores/versioning-listing-and-caching)

**Serialization**
- Stored as JSON. Supported types: nil, booleans, numbers, strings, tables and **buffers**.
- Avoid inf, -inf and NaN. Open Cloud returns them as tagged objects.
- Numeric keys become strings when the table length is 0.
- Use `HttpService:JSONEncode` to preview exactly what will be stored.
- Source: [same](https://create.roblox.com/docs/cloud-services/data-stores/versioning-listing-and-caching)

**OnUpdate**
- Polls for changes made by other servers **once per minute**. — [GlobalDataStore reference](https://create.roblox.com/docs/reference/engine/classes/GlobalDataStore)

**Official best practices (2026 page)**
- Use few data stores, with one key or a few keys per player, for example `User_{UserId}` in a `PlayerData` store.
- Use static key patterns. They are required for automated RTBF.
- Prefer UpdateAsync over SetAsync.
- Buffer data in memory. Save periodically, on leave, on shutdown and on purchase. The official sample autosaves every **180 seconds**, and the autosave interval must be shorter than the session-lock expiry.
- Stagger loops with random offset and jitter.
- Use exponential backoff with jitter. Process retries **in order per key**, and treat a failed write as having an unknown outcome.
- Shard hot read-only keys, for example `Weather_1..N`, choosing the shard by hashing JobId.
- **DataStore2 is legacy and should not be used for new experiences.** Roblox ships an official beta DataStore2 migration tool, asset 82521207271039.
- Use the Data Stores Batch Processor CLI (github.com/Roblox/data-stores-batch-processor-cli) for bulk work.
- Configure custom alerts on data store metrics.
- Source: [Best practices](https://create.roblox.com/docs/cloud-services/data-stores/best-practices)

**Data Stores Manager (Creator Hub → Configurations → Data stores manager)**
- Browse stores and keys by prefix. View a key's value, metadata, version history and status. Compare versions. Delete keys and stores.
- Deleted data stores have a 30-day restore buffer.
- Size and key counts are hidden when a game has more than 100 data stores.
- Source: [Data Stores Manager](https://create.roblox.com/docs/cloud-services/data-stores/data-stores-manager); [Best practices](https://create.roblox.com/docs/cloud-services/data-stores/best-practices)

**Observability dashboard (Monitoring → Data Stores)**
- Charts: Storage Usage Bytes, Request Count by API, Request Count by Status, Request by API × Status, Read Quota Usage, Write Quota Usage. — [Observability](https://create.roblox.com/docs/cloud-services/data-stores/observability)

**Right to be forgotten (RTBF), automated**
- Set up through Data Stores Manager → **RTBF Deletion** tab, or the Open Cloud **Configs API** (repository `DataStoresConfig`, config `user_data_templates`).
- Up to **100 templates**. Each uses the case-sensitive `{UserId}` token.
- Template types:
  - Key template: STANDARD or ORDERED; `data_store_name`, `key_pattern`, and optionally `scope_pattern` (defaults to `global`).
  - Data store template: STANDARD only.
- The user ID must appear in the store or key Name or Scope as a static pattern.
- Verify deletion within 30 days.
- When the schema doesn't fit templates, fall back to the **right-to-erasure webhook**.
- Source: [RTBF](https://create.roblox.com/docs/cloud-services/data-stores/right-to-be-forgotten); [Best practices](https://create.roblox.com/docs/cloud-services/data-stores/best-practices)

**Extended Services** (pay for usage above the default quotas)
- Account requirements: ID-verified, 18+, in a supported country (list includes US, UK, EU, etc.).
- Minimum monthly budget $0.50. You are billed at month end or when usage reaches $10.
- Requests are throttled once the budget is exceeded. Email alerts at 80% and 100%.
- Extended prices:

| Item | Extended price |
|---|---|
| Standard Get | $0.08 per 1M |
| Standard Set | $0.80 per 1M |
| Standard List | $0.60 per 1M |
| Standard Remove | $0.80 per 1M |
| Ordered Set | $0.25 per 1M |
| Ordered GetSorted | $0.32 per 1M |
| Data store storage | $0.12 per GB-month |
| Memory store requests | $0.003 per 1M |
| Memory store storage | $0.10 per GB-hour |
| Compute | first 100K playtime-hours per month free, then $0.001 per playtime-hour |

- Source: [Extended Services](https://create.roblox.com/docs/cloud-services/extended-services)

### Inferences
- A skill should **never** hard-code the old "60 + numPlayers × 10" GetAsync budget. It should read `GetRequestBudgetForRequestType(Enum.DataStoreRequestType.StandardRead)` (or the legacy enum) before bursts.
- Because the budget is shared with Open Cloud, ops scripts need their own rate limiting.
- For durable player data the current default is one key per player under `User_{UserId}`. That pattern gives RTBF eligibility and one atomic UpdateAsync per save.
- Take a snapshot before every release that changes the data schema.

### Gaps
- I could not read the July 2026 DevForum post in full: devforum.roblox.com was blocked in this session. The exact posting date and any grace period come from search excerpts only.
- The text "Overages via Robux deductions or Extended Services … rather than immediate write failures (April 2026)" comes from a search summary only. Unverified.
- No public schedule exists for removing the deprecated legacy request-type enums.

---

## 2. ProfileStore (loleris), ProfileService status, and alternatives

### Takeaway
**ProfileStore** is the maintained successor. The latest release is v1.0.3 (Wally package `lm-loleris/profilestore`); the last commit was 2025-07-31. Its README is explicit that **ProfileService is "no longer supported"**. GlobalUpdates is replaced by `ProfileStore:MessageAsync` plus `Profile:MessageHandler`. Mocking uses `ProfileStore.Mock`. Lapis (v0.3.4, Feb 2025) and DataKeep (v7.0.0, Sep 2025) are alive but small.

### Cited Findings
- ProfileService README: "FOR NEW PROJECTS - USE ProfileStore … This project is no longer supported." Last commit 2024-10-13. — [ProfileService GitHub](https://github.com/MadStudioRoblox/ProfileService)
- ProfileStore package: `wally.toml` gives name `lm-loleris/profilestore`, version **1.0.3**, realm server. Last commit 2025-07-31. — [ProfileStore GitHub](https://github.com/MadStudioRoblox/ProfileStore); DevForum thread [ProfileStore](https://devforum.roblox.com/t/profilestore/3190543)

**ProfileStore API** (from the `ProfileStore.luau` header)
- Module level:
  - `ProfileStore.New(store_name, template?)`
  - `ProfileStore.SetConstant(name, value)`
  - `ProfileStore.Mock`, a store backed by a mock DataStore. It is also used automatically in Studio when API access is off.
  - Flags and signals: `ProfileStore.IsClosing`, `IsCriticalState`, `OnError(message, store_name, key)`, `OnOverwrite`, `OnCriticalToggle`.
  - `DataStoreState`: "NotReady", "NoInternet", "NoAccess" or "Access".
- Store methods:
  - `:StartSessionAsync(key, {Steal=true?, Cancel=fn?})` returns a Profile or nil.
  - `:MessageAsync(key, messageTable)` returns a bool.
  - `:GetAsync(key, version?)` reads without a session and does not autosave.
  - `:VersionQuery(key, sortDir?, minDate?, maxDate?)`, then `:NextAsync()` on the result.
  - `:RemoveAsync(key)`.
- Profile members:
  - `Data`.
  - `LastSavedData` (read-only). The docs call it "useful for proper developer product purchase receipt handling."
  - `FirstSessionTime`, `SessionLoadCount`, `Session {PlaceId, JobId}`, `RobloxMetaData`, `UserIds`, `KeyInfo`.
  - Signals: `OnSave`, `OnLastSave(reason: "Manual" | "External" | "Shutdown")`, `OnSessionEnd`, `OnAfterSave(last_saved_data)`.
- Profile methods:
  - `IsActive()`. Its guarantee only holds until the code yields.
  - `Reconcile()`, `EndSession()`, `AddUserId()` (for GDPR), `RemoveUserId()`.
  - `MessageHandler(fn(message, processed))`.
  - `Save()`, an immediate UpdateAsync.
  - `SetAsync()`, only for profiles loaded with GetAsync or VersionQuery.
- Source: [ProfileStore.luau](https://github.com/MadStudioRoblox/ProfileStore/blob/main/ProfileStore.luau)

**ProfileStore internal constants**
- AUTO_SAVE_PERIOD = 300 s.
- On a session conflict: first retry after 5 s, then every 10 s, and the session is **stolen after 40 s**.
- ASSUME_DEAD = 630 s; START_SESSION_TIMEOUT = 120 s.
- Critical state starts after 5 errors within 120 s.
- MAX_MESSAGE_QUEUE = 1000.
- It uses MessagingService topics `"PS_" .. sessionId` to tell the server holding a session to release it quickly. — [ProfileStore.luau](https://github.com/MadStudioRoblox/ProfileStore/blob/main/ProfileStore.luau)
- Data rules: no numeric tables with gaps, no mixed tables, no Instances, no userdata (Vector3, CFrame, etc.), no functions. — [same](https://github.com/MadStudioRoblox/ProfileStore/blob/main/ProfileStore.luau)

**ProfileStore developer-product docs**
- Two patterns are shown:
  - (a) The official Roblox handler with `profile:Save()` added.
  - (b) A more robust one: cache the last N (example: 100) `PurchaseId`s in `Profile.Data`, grant the item, and **yield ProcessReceipt until the PurchaseId shows up in `Profile.LastSavedData`**, then return `PurchaseGranted`.
- Pattern (b) closes the rare case where the server crashes before any save succeeds. — [ProfileStore docs/devproducts](https://github.com/MadStudioRoblox/ProfileStore/tree/main/docs/devproducts)

**Alternatives**
- **Lapis** (nezuo): v0.3.4, released 2025-02-11 ("Pass the document's key to migrations"). Has built-in migrations. — [nezuo/lapis CHANGELOG](https://github.com/nezuo/lapis)
- **DataKeep** (noahrepublic): v7.0.0, released 2025-09-14. — [noahrepublic/DataKeep CHANGELOG](https://github.com/noahrepublic/DataKeep)
- **Suphi's DataStore Module**: has a DevForum thread with **always-on** session locking backed by MemoryStore. Users report Studio does not share the lock with live servers. I found no 2025–2026 update evidence. — [DevForum: Suphi's DataStore Module](https://devforum.roblox.com/t/suphis-datastore-module/2425597) (search excerpt)
- Roblox's own guidance: evaluate a module's "ownership, maintenance status, and feature sets" and "understand how to access and migrate your data without the module." — [Best practices](https://create.roblox.com/docs/cloud-services/data-stores/best-practices)

### Inferences
- Default to ProfileStore for player data.
- Use `MessageAsync` for offline gifts and admin grants, in place of ProfileService's GlobalUpdates.
- In tests, use `ProfileStore.Mock`.
- Because ProfileStore autosaves every 300 s and the official sample uses 180 s, call `profile:Save()` after purchases or trades rather than waiting for the next autosave.

### Gaps
- I could not open the ProfileStore DevForum thread to check for post-July-2025 announcements.
- There is no GitHub stars or activity data for Suphi's module because its source is not on GitHub.

---

## 3. Session locking, schema migration, backups, rollback, preventing dupes

### Takeaway
Roblox's official reference design routes **every** operation through UpdateAsync. It stores a `LockId` GUID in the key's **metadata**, refreshes the lock with each autosave, uses one ordered retry queue per key, and marks a profile "errored" when its load fails so it is never saved. Recovery uses versioning (30-day history), daily Open Cloud snapshots, and Data Stores Manager or the Batch Processor.

### Cited Findings

**Official sample design** (`DataStoreWrapper`, `SessionLockedDataStoreWrapper`, `ReceiptHandler`, `PlayerData.Server` / `PlayerData.Client`)
- Retries are processed in order **per key**, through a ThreadQueue.
- `skipAllQueuesToLastEnqueued` is used in BindToClose.
- Locks are written atomically into metadata inside the same UpdateAsync, then released in the final save on PlayerRemoving or BindToClose.
- Any server may take over an expired lock.
- On load failure the player gets default data and the profile is flagged with `hasErrored`. Such a profile must not be saved, and **purchases should be blocked**.
- Keys marked private with `setValueAsPrivate` are not replicated to the client.
- Roblox labels the code "not proven … in a popular game. Don't use as-is without extensive testing."
- Source: [Implement player data and purchasing systems](https://create.roblox.com/docs/cloud-services/data-stores/player-data-purchasing)

**Why dupes happen**
- Fast server hops, such as teleports, let server B load stale data while server A's final save is still retrying or queued. Exploiters abuse this in trading games. — [same](https://create.roblox.com/docs/cloud-services/data-stores/player-data-purchasing)

**Rollback**
- Use ListVersionsAsync with a time window, then GetVersionAsync, then SetAsync with the old metadata. — [Versioning](https://create.roblox.com/docs/cloud-services/data-stores/versioning-listing-and-caching)
- Daily snapshots via Open Cloud. — [same](https://create.roblox.com/docs/cloud-services/data-stores/versioning-listing-and-caching)
- Large-scale remediation via the Data Stores Batch Processor CLI or the Open Cloud data store APIs. — [Best practices](https://create.roblox.com/docs/cloud-services/data-stores/best-practices)

**Migrations**
- Lapis supports migrations, and its v0.3.4 passes the key to each migration function. — [Lapis](https://github.com/nezuo/lapis)
- ProfileStore offers `Reconcile()` to fill missing fields from the template. — [ProfileStore.luau](https://github.com/MadStudioRoblox/ProfileStore/blob/main/ProfileStore.luau)

**Regional-price arbitrage in trading and gifting**
- `MarketplaceService:GetUsersPriceLevelsAsync` returns a value from 1 to 1000, where 1000 means the full global price. Use it to gate trades and gifts between users at different price levels. — [Regional pricing](https://create.roblox.com/docs/production/monetization/regional-pricing)

### Inferences
- Recommended schema practice, derived from the sources above:
  - Store a `version` number field in the data.
  - Run ordered migration functions on load.
  - Never downgrade.
  - Snapshot before release.
  - Keep a per-profile `PurchaseId` ring buffer to make purchase processing idempotent.
  - For trades, commit both players' changes within session-locked profiles and save both immediately.

### Gaps
- I found no public write-ups from large studios (for example Adopt Me or Pet Simulator) describing their rollback tooling in 2025–2026.

---

## 4. MemoryStoreService limits and uses

### Takeaway
- Memory quota: **64 KB + 1.2 KB × users**. It drops only after an 8-day trailing period.
- Requests: **1000 + 120 × CCU** request units per minute.
- Each sorted map or queue: at most **1M items or 100 MB**.
- Each item value: at most **32 KB**.
- Maximum TTL: **3,888,000 s (45 days)**, which is also the default.
- Hash maps spread across partitions, so they are the default choice unless you need sorting or FIFO order.

### Cited Findings

**Quotas**
- Memory quota is 64 KB + 1.2 KB × number of users, applied per game, not per server.
  - New users raise it immediately.
  - It "reevaluates to a lower value" only after an 8-day traceback period.
  - Once the quota is hit, any request that would grow memory fails.
  - Source: [Memory stores](https://create.roblox.com/docs/cloud-services/memory-stores)
- Requests are limited to 1000 + 120 × CCU request units per minute, game-wide.
  - SortedMap GetRangeAsync costs one unit per returned item, minimum 1.
  - Queue ReadAsync costs per item, plus 1 unit for every 2 s it waits.
  - HashMap ListItemsAsync costs partitions scanned plus items returned.
  - Source: [same](https://create.roblox.com/docs/cloud-services/memory-stores)

**Per-structure and per-partition limits**
- Each sorted map or queue: 1,000,000 items and 100 MB, keys included. Each data structure is also limited to **100,000 request units per minute** (`DataStructureRequestsOverLimit`). — [same](https://create.roblox.com/docs/cloud-services/memory-stores)
- Partitions throttle at roughly **30,000 request units per minute**. The docs call this an estimate and say not to design against it.
  - Each sorted map or queue lives on one partition.
  - Hash map single-key operations are limited to about **5,000 writes and 15,000 reads per minute per key**.
  - Exceeding either returns `PartitionRequestsOverLimit`.
  - Source: [same](https://create.roblox.com/docs/cloud-services/memory-stores)
- Value-size and TTL errors: `ItemValueSizeTooLarge` means the value is over 32 KB. `InvalidExpirationTime` means the expiration is outside 0–3,888,000 s. The default expiration is 45 days for Queue AddAsync and SortedMap SetAsync. — [same](https://create.roblox.com/docs/cloud-services/memory-stores)

**Recovery and testing**
- Recover from `TotalMemoryOverLimit` with the Open Cloud flush endpoint: `POST https://apis.roblox.com/cloud/v2/universes/{id}/memory-store:flush?scope=LIVE|TEST`. Then poll the returned operation. — [same](https://create.roblox.com/docs/cloud-services/memory-stores)
- Studio has the same quotas as live, which leaves it with a tiny quota because there is only one user. Studio and live memory stores are isolated from each other. — [same](https://create.roblox.com/docs/cloud-services/memory-stores)

**Typical uses**
- Cross-server trading and auctions use a sorted map; shared inventories use a hash map. Docs also list matchmaking queues and leaderboards. — [same](https://create.roblox.com/docs/cloud-services/memory-stores)
- Docs advise using memory stores for temporary or fast-changing data, because it doesn't add to persistent storage. — [Data stores best practices](https://create.roblox.com/docs/cloud-services/data-stores/best-practices)

### Inferences
- Always set short TTLs and delete items explicitly.
- Shard hot sorted maps, for example by the last digits of the UserId.
- Handle `DataUpdateConflict` with exponential backoff (2 s, 4 s, 8 s …), which is the doc's example.

### Gaps
- Exact Extended Services memory quotas beyond the default formula are not given. The docs give pricing only.

---

## 5. MessagingService limits

### Takeaway
- Messages are best-effort, usually arrive in **1–2 s**, are at most **1 KB**, and topics are 1–80 characters.
- Delivery is not guaranteed, so never use it as the only path for something like a purchase.

### Cited Findings
- Limits, which the docs say are "subject to change":

| Limit | Value |
|---|---|
| Message size | **1 kB** |
| Messages sent per server | **600 + 240 × players** per minute |
| Messages received per topic | **40 + 80 × servers** per minute |
| Messages received for the whole game | **400 + 200 × servers** per minute |
| Subscriptions per server | **20 + 8 × players** |
| Subscribe requests per server | **240** per minute |

  Source: [MessagingService reference](https://create.roblox.com/docs/reference/engine/classes/MessagingService)
- Open Cloud can publish to live servers or across experiences. — [same](https://create.roblox.com/docs/reference/engine/classes/MessagingService); [Cross-server messaging](https://create.roblox.com/docs/cloud-services/cross-server-messaging)

### Inferences
- For anything that must arrive, pair MessagingService with a durable fallback, such as ProfileStore MessageAsync or a DataStore or MemoryStore queue.

### Gaps
- None significant.

---

## 6. Monetization 2025–2026: receipts, products, subscriptions, pricing, ads, commerce, Roblox Plus, paid random items

### Takeaway
Six changes since 2025 that a skill must reflect:
1. ProcessReceipt correctness is now **audited by Roblox**. Listed developer products are sold **outside the game**: homepage, search, and the post-Robux-purchase page.
2. **Managed Pricing** combines price optimization and regional pricing, with regional prices bounded at 30–100% of the default.
3. **Roblox Plus** launched April 30, 2026 at $4.99/month and replaced new Premium sign-ups.
4. Rewarded video ads must grant **developer products** through ProcessReceipt.
5. The paid random items rules require exact odds summing to 100%, and **`ArePaidRandomItemsRestricted`** must be honored.
6. Commerce products are sold to US users only.

### Cited Findings

**ProcessReceipt guarantees and limits** (engine reference)
- When it is called: for unresolved purchases on purchase, when a successful prompt appears, and **on join**.
- **No time-based retry and no timeout.** A yielding callback's result is still accepted.
- If no callback is set, receipts are **auto-acknowledged** and cannot be recovered.
- Pending purchases are delivered in a non-deterministic order.
- The same purchase **can run on two servers at once** if the user joins a second server before the first returns.
- Returning PurchaseGranted can still fail to record.
- `receiptInfo` fields: PurchaseId, PlayerId, ProductId, PlaceIdWherePurchased, CurrencySpent, CurrencyType (always Robux) and **ProductPurchaseChannel** (new enum).
- Source: [MarketplaceService.ProcessReceipt](https://create.roblox.com/docs/reference/engine/classes/MarketplaceService#ProcessReceipt)

**Official sample handler**
- Uses a `productFunctions[productId]` table, runs the handler in a pcall, and returns PurchaseGranted on success, otherwise NotProcessedYet.
- It does **not** record PurchaseId. Idempotency is covered separately in the player-data guide: verify the PurchaseId isn't recorded, grant in memory, record the PurchaseId, save, and only then return PurchaseGranted.
- Source: [Developer products](https://create.roblox.com/docs/production/monetization/developer-products); [Player data & purchasing](https://create.roblox.com/docs/cloud-services/data-stores/player-data-purchasing)

**External sales and Roblox's ProcessReceipt audit**
- Listed developer products and passes are sold outside the game.
- Roblox "checks your ProcessReceipt implementation on an ongoing basis". Flagged developer products stop appearing on external surfaces, and a banner appears in Creator Hub → Monetization → Shop.
- Don't use `PromptProductPurchaseFinished` to grant items.
- Source: [Developer products](https://create.roblox.com/docs/production/monetization/developer-products)

**Developer product basics**
- Price range: 1 to 1,000,000,000 Robux.
- `receiptInfo` carries the exact price paid, even during a price test.
- `RankProductsAsync` has a strict rate limit, so call it once on join.
- `RecommendTopProductsAsync` returns up to 50 items, and needs at least one sale in the last 28 days.
- For price optimization, the purchase-prompt script should run on the client so players see personalized prices.
- Source: [Developer products](https://create.roblox.com/docs/production/monetization/developer-products)

**Subscriptions**

| | Robux subscription | Local-currency subscription |
|---|---|---|
| Price | ≥ 49 Robux | tiers $2.99, $4.99, $7.99, $9.99, $14.99 |
| Creator earnings | 70% every month | 70% first month, then 100% |
| Regional pricing | always on, can't be disabled | not available |
| Price changes | once per 60 days; increases need 30 days' notice | can't change; delete and recreate |
| Earnings hold | about 5 days | 30 days |
| Refunds | none | must refund all subscribers if you delete it |

- Up to 50 subscriptions per game.
- `GetUserSubscriptionStatusAsync` must be called from the **server**.
- Subscriptions are ineligible for cross-sell and affiliate fees.
- Source: [Subscriptions](https://create.roblox.com/docs/production/monetization/subscriptions)

**Price optimization**
- Usually needs **≥ 60,000 transactions in the last 30 days**.
- Tests run automatically at least every 90 days.
- During a test, 98% of users see test prices and 2% see the original.
- Hard-coded prices block tests. Prices must be read dynamically, for example with GetProductInfo.
- Up to 5 test accounts can be used to detect hard-coded prices.
- Source: [Price optimization](https://create.roblox.com/docs/production/monetization/price-optimization)

**Regional and Managed Pricing**
- Regional prices are never more than 70% below the default and never above it, so they fall between 30% and 100% of the default.
- Economic location is determined from VPN, billing and account signals.
- Subscriptions, Private Servers and Developer Servers are regionalized automatically.
- Source: [Regional pricing](https://create.roblox.com/docs/production/monetization/regional-pricing); [Managed pricing](https://create.roblox.com/docs/production/monetization/managed-pricing)

**Paid access in local currency**
- Price tiers and creator share: $9.99 → 50%, $29.99 → 60%, $49.99 → 70%.
- The creator must be 13+ and ID-verified. Payouts go through Tipalti, and the game gets a moderation review.
- **Paying for access must unlock the whole game.** Microtransactions are still allowed.
- Source: [Paid access (local currency)](https://create.roblox.com/docs/production/monetization/paid-access-local-currency)

**Roblox Plus**
- Launched globally **April 30, 2026** at $4.99/month. New Premium sign-ups stopped; existing Premium members keep their subscription.
  - Source: [Roblox newsroom](https://about.roblox.com/newsroom/2026/04/introducing-roblox-plus-subscription); [DevForum: Introducing Roblox Plus](https://devforum.roblox.com/t/introducing-roblox-plus/4567894) (search excerpt)
- Subscriber discount: 10% for the first two months, then 20%. **Roblox covers the discount**, so the creator's share per purchase rises from 70% to 78% at the 10% discount and 88% at the 20% discount.
- Plus sign-ups through `MarketplaceService:PromptRobloxSubscriptionPurchase` earn 250 Robux per month for 3 months, up to **750 Robux** per subscriber.
- Paid private servers earn up to 100 Robux per Plus subscriber who spends ≥ 60 minutes in them over 30 days.
- Robux transfers through `PromptRobuxTransferAsync` earn a 10% fee.
- Source: [Roblox Plus (creator docs)](https://create.roblox.com/docs/production/monetization/roblox-plus)

**U.S. 18+ DevEx rate**
- A higher DevEx rate of **0.0054** applies to eligible Earned Robux from US players who are age-verified as 18+.
- The game must use **R15 human-form characters 100% of active playtime**. R6 makes the game ineligible.
- Source: [18+ DevEx rate](https://create.roblox.com/docs/production/monetization/18-plus-devex-rate)

**Rewarded video ads**
- Ads are 6–30 s, full screen and click-to-play.
- **The reward must be a developer product; Robux can't be the reward.**
- Eligibility: creator 13+, ID-verified, public game with ≥ 2,000 unique visitors per month.
- Flow:
  1. Client: `AdService:GetAdAvailabilityNowAsync()`.
  2. Server: `AdService:CreateAdRewardFromDevProductId`.
  3. Server: `AdService:ShowRewardedVideoAdAsync`.
  4. Grant the reward in ProcessReceipt.
- "Join with Reward" is a closed beta that grants through ProcessReceipt when the player joins.
- Source: [Rewarded video ads](https://create.roblox.com/docs/production/promotion/rewarded-video-ads)

**Immersive ads**
- Formats: image, video and portal ads.
- Publisher requirements: public game, creator 13+, ID verification, 2FA, an approved Maturity/Content Rating questionnaire, and ≥ 2,000 unique visitors per month.
- Payouts arrive on the 25th of the following month.
- `PolicyService.AreAdsAllowed` is available for per-user checks.
- Source: [Immersive ads](https://create.roblox.com/docs/production/monetization/immersive-ads); [PolicyService](https://create.roblox.com/docs/reference/engine/classes/PolicyService)

**Commerce products**
- Creator must be 18+, among other requirements.
- **Buyers must be US-based, 13+, and 18+ in Texas.**
- Bundled digital benefits need either:
  - more than 100K average DAU and more than 1M Robux average monthly earnings over the last 90 days, or
  - an ad-spend agreement of at least $50K per year.
- A bundled benefit can't be Robux or in-game currency.
- Check `PolicyService.IsEligibleToPurchaseCommerceProduct` per user.
- Source: [Commerce products](https://create.roblox.com/docs/production/monetization/commerce-products)

**Paid random items** (capsules, enhancements, combinations, and probability modifiers such as luck boosts, pity and rate-ups)
- **All outcomes and their numerical odds** must be disclosed before purchase.
- Odds must be shown as percentages that sum to exactly 100%. Rounding is allowed with a disclaimer.
- A pop-up must be labeled "Info" or "Details". A bare (i) icon is not enough.
- If each user can obtain an outcome only once, the remaining odds must update per user.
- Indirect purchases count: keys, tickets, or premium currency bought with Robux.
- Odds boosters must show the boosted odds numerically and update them dynamically.
- Free, earned loot does not need disclosure.
- Source: [Paid random items](https://create.roblox.com/docs/production/monetization/paid-random-items)
- When `PolicyService:GetPolicyInfoForPlayerAsync().ArePaidRandomItemsRestricted == true`, you must apply one of these:
  - a free, earnable path to the item;
  - a fixed sequence of outcomes disclosed up front;
  - direct purchase at expected value (example: a 10-Robux box with 5% odds becomes a direct 200-Robux sale);
  - hiding or removing the item;
  - blocking the purchase with a message;
  - moving the player away, for example by teleporting.
- When `IsPaidItemTradingAllowed == false`, the user must not trade paid items or paid random outcomes.
- Source: [Paid random items](https://create.roblox.com/docs/production/monetization/paid-random-items)
- Other `GetPolicyInfoForPlayerAsync` fields:
  - AreAdsAllowed, IsContentSharingAllowed, IsEligibleToPurchaseCommerceProduct, IsEligibleToPurchaseSubscription, IsPhotoToAvatarAllowed, IsSubjectToChinaPolicies, IsEndlessContentLoadAllowed, IsEndlessContentAutoplayAllowed.
  - `AllowedExternalLinkReferences` is legacy and always empty.
  - The call errors if more than 100 calls are in flight. Wrap it in pcall.
  - Source: [PolicyService reference](https://create.roblox.com/docs/reference/engine/classes/PolicyService)

### Inferences
- A compliant 2026 shop template should:
  - Read prices dynamically, with GetProductInfo on the client.
  - Make ProcessReceipt idempotent, using a PurchaseId log and saving before PurchaseGranted, because the external-sales audit depends on it.
  - Call GetPolicyInfoForPlayerAsync on join and gate random items, trading, ads, commerce and subscriptions accordingly.
  - Show an odds "Details" panel.
  - Gate gifts and trades with GetUsersPriceLevelsAsync.

### Gaps
- I found no dedicated official "pay-to-skip" policy page in the docs snapshot. The Community Standards text on monetization tactics was not fetched.
- Game pass details are not extracted here: passes.md (25 KB) was not read in full, so price bounds and details are a gap.
- The rules for Robux transfers (robux-transfers.md) were not extracted.

---

## 7. Age, maturity and Community Standards changes affecting games (2025–2026)

### Takeaway
- **Chat now requires an age check.** It started in select markets in Dec 2025 and went global in early Jan 2026; the US requirement began Jan 7.
- **Age-based accounts** launched globally in June 2026: Roblox Kids (5–8), Roblox Select (9–15), and Roblox (16+, age-checked).
- Reaching players under 16 requires all of these: a Minimal, Mild or Moderate rating; a verified creator with 2FA; a Plus or Premium subscription held for 2+ months, or a refundable fee; and passing an evaluation of 100 unique plays by highly engaged age-checked users within 60 days.
- Games without content ratings get restricted playability.

### Cited Findings

**Chat age checks**
- After an age check, users are placed in a band: U9, 9–12, 13–15, 16–17, 18–20 or 21+. Chat is limited to similar ages unless the users are Trusted Connections. — [Roblox newsroom Nov 2025](https://about.roblox.com/newsroom/2025/11/roblox-requires-age-checks-limits-minor-and-adult-chat); [Jan 2026](https://about.roblox.com/newsroom/2026/01/roblox-age-checks-required-to-chat); [DevForum: Age Check Requirement to Chat Now Live Globally](https://devforum.roblox.com/t/age-check-requirement-to-chat-now-live-globally/4226101); US start date of Jan 7 per [Fast Company](https://www.fastcompany.com/91472515/roblox-gaming-child-safety-adults) (search excerpt)

**Account types and creator requirements**
- Kids and Select were announced in April 2026 and became globally available in June 2026. — [Newsroom Apr 2026](https://about.roblox.com/newsroom/2026/04/introducing-roblox-kids-and-select-accounts); [Newsroom Jun 2026](https://about.roblox.com/newsroom/2026/06/age-based-roblox-kids-and-select-accounts-now-globally-available)
- Account tiers:

| Tier | Who | Content allowed | Chat |
|---|---|---|---|
| Roblox Kids | self-declared or age-checked age 5–8 | Minimal or Mild | off by default |
| Roblox Select | self-declared 9+ until age-checked, or age-checked 9–15 | up to Moderate | off when self-declared; gradual once age-checked |
| Roblox | age-checked 16+ | all except Restricted (18+ verified only) | on by default where available |

- Creator requirements for under-16 audiences:
  - Facial age estimation if the creator is under 18, government ID if 18+, plus 2FA.
  - A Roblox Plus or Premium subscription for 2 consecutive months, **or** a one-time refundable fee.
  - Evaluation: a trial with age-checked users 16+, then **100 unique plays by highly engaged age-checked users within 60 days**, plus a safety review.
  - An optional expedited review costs **50,000 Robux** (refundable).
- Releasing to 16+ only requires an account at least 2 days old and an age check. Answering "No" to the restricted-content question gives a **"Content May Vary"** rating, available to age-checked users 16+.
- Source: [Roblox Kids and Select](https://create.roblox.com/docs/production/publishing/kids-and-select); [DevForum: New Publishing Requirements & Evaluation Process](https://devforum.roblox.com/t/new-publishing-requirements-evaluation-process-for-games/4573166) (search excerpt)

**Content maturity ratings and IARC**
- Ratings map to audiences as follows:
  - Minimal or Mild: eligible for Kids and Select.
  - Moderate: Select and Roblox (16+).
  - Content May Vary: age-checked users 16+ only.
  - Restricted: age-verified users 18+ only.
- IARC regional ratings (ESRB, PEGI, USK, ClassInd, GRAC, etc.) are generated from the same questionnaire. Roblox pays the IARC fee.
- "If a game does not have content ratings, Roblox restricts the playability of the game on the platform for all players."
- Resubmitting the questionnaire temporarily removes ads eligibility.
- Source: [Content ratings](https://create.roblox.com/docs/production/promotion/content-ratings); [Immersive ads](https://create.roblox.com/docs/production/monetization/immersive-ads)

### Inferences
- Code-level consequences:
  - Don't rely on chat for core gameplay; many players won't have chat.
  - Gate user-generated content sharing on `IsContentSharingAllowed`.
  - Keep a "Moderate or below" content profile to reach players under 16.
  - Fill in the questionnaire before launch.

### Gaps
- Specific social-hangout restrictions (for example private-space rules, or limits on unrated games beyond the quote above) were not located in the docs snapshot.
- The Community Standards page itself was not fetched.

---

## 8. Analytics: AnalyticsService events, Creator Dashboard metrics

### Takeaway
AnalyticsService provides economy, funnel (including onboarding), journey, progression and custom events. The global rate limit is **120 + 20 × CCU per minute**. Cardinality caps are tight: 10 resource types, 10 funnels, 100 custom event names, and 3 custom fields. The dashboard reports D1, D7 and D30 retention, payer conversion, ARPPU and ARPDAU. Roblox publishes no benchmarks.

### Cited Findings
- Methods: `LogEconomyEvent`, `LogFunnelStepEvent`, `LogOnboardingFunnelStepEvent`, `LogJourneyEvent` (new: branching paths), `LogProgressionStartEvent`, `LogProgressionCompleteEvent`, `LogProgressionFailEvent`, `LogProgressionEvent`, and `LogCustomEvent`. — [AnalyticsService reference](https://create.roblox.com/docs/reference/engine/classes/AnalyticsService)
- Limits:

| Limit | Value |
|---|---|
| Global rate limit (all AnalyticsService calls) | 120 + 20 × CCU per minute |
| Custom fields | 3 (unique values unlimited, but after 8,000 combined values they are grouped as "Other") |
| Economy resource types | 10 |
| transactionTypes | grouped as "Other" after 20 |
| itemSkus | grouped as "Other" after 100 |
| Funnels | 10 |
| Steps per funnel | 100 |
| Custom event names | 100 |

  - Limits reset daily. Events roll off 90 days after the last data received. Charts take about 24 h to appear; use the "View Events" tool for near-real-time checks.
  - Log events only **after** the action succeeds.
  - Use custom fields rather than separate names, for example currency `XP` with field values Warrior or Mage.
  - Source: [Event types](https://create.roblox.com/docs/production/analytics/event-types)
- Funnel behavior:
  - A user's saved step expires after 180 days of inactivity.
  - Only the 10 most recent `funnelSessionId` values per user per funnel are tracked.
  - Repeated steps are ignored but still count toward the rate limit.
  - Logging a later step auto-completes the skipped ones.
  - Funnels are attributed by cohort.
  - Validate step numbers on the server to stop exploiters.
  - Source: [Funnel events](https://create.roblox.com/docs/production/analytics/funnel-events)
- Retention: D1, D7 and D30 by cohort, plus daily cohorts over 10 days and weekly cohorts over 10 weeks. Also cumulative 7D playtime per user, 7D player conversion rate, and 7D and 30D revenue per user. — [Retention](https://create.roblox.com/docs/production/analytics/retention)
- Monetization: payer conversion is the % of DAU who pay; ARPDAU is average revenue per DAU; ARPDAU = conversion × ARPPU. Docs advise welcome offers, a wide range of price points, and a mix of consumables and durables. — [Monetization analytics](https://create.roblox.com/docs/production/analytics/monetization)
- Other dashboards in the docs set: custom alerts, Performance, Error report, Acquisition, Engagement, Custom dashboards, and Experiments (`production/experiments.md`). — [Analytics index](https://create.roblox.com/docs/production/analytics)

### Inferences
- Wrap AnalyticsService calls in a server-side helper that:
  - checks the call happens after success;
  - batches counts into value events to stay under 120 + 20 × CCU;
  - uses a fixed enum of currencies (at most 10) and funnels (at most 10).

### Gaps
- **No official public benchmarks** for D1/D7 retention, ARPDAU or conversion were found in Roblox docs. Community figures such as "D1 above 30%" could not be verified from primary sources.
- RDC 2025 talk content was not retrieved.
