<div align="center">

# Cluau

**Roblox Studio тоглоом хийхэд зориулсан Claude skill**
**A Claude skill for building Roblox Studio games the right way**

Modern strict Luau · Exploit-proof networking · Session-locked DataStores · Fair monetization · Hand-crafted UI — not AI slop

[![CI](https://github.com/d3vnmd/cluau/actions/workflows/ci.yml/badge.svg)](https://github.com/d3vnmd/cluau/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/d3vnmd/cluau?sort=semver)](https://github.com/d3vnmd/cluau/releases)
[![License: MIT](https://img.shields.io/badge/license-MIT-informational.svg)](LICENSE)

[Монгол](#монгол) · [English](#english)

</div>

---

## Монгол

### Cluau гэж юу вэ?

**Cluau** нь Claude-ийг Roblox-ийн **ахлах инженер + тоглоомын дизайнер + UI зураач** болгодог skill юм. Энэ нь хоёр амлалт дээр суурилсан:

1. **Алдаатай, хуучирсан, аюултай код бичихгүй.** `wait()`, `spawn()`, `BodyVelocity`, `Humanoid:LoadAnimation`, `FindPartOnRay`, `SetPrimaryPartCFrame` гэх мэт deprecated API-г хэзээ ч ашиглахгүй. Бүх RemoteEvent сервер дээр төрөл, хязгаар, хурд, эзэмшил, төлөвөөр шалгагдана. Клиентэд мөнгө, damage, үнэ, шагналын талаар хэзээ ч итгэхгүй.
2. **"AI slop" UI хийхгүй.** Ягаан-цэнхэр градиент, emoji товч, бүх зүйл голдоо, `TextScaled` хаа сайгүй, "Welcome to the Game!" гэх мэт загварлаг бус зүйлгүй. Оронд нь тоглоомын өнгө төрхөөс гаргасан design token систем, жинхэнэ hover/pressed/disabled төлөв, утас/компьютер/геймпад бүгдэд ажиллах responsive байрлал.

### Юу багтсан бэ?

| Хэсэг | Агуулга |
|---|---|
| `SKILL.md` | Гол "prompt": ажиллах дараалал, заавал хийх өөрийгөө шалгах жагсаалт, архитектур, аюулгүй байдал, UI зарчим, өгөгдөл, монетизаци, гүйцэтгэл |
| `references/` | 19 гүнзгий гарын авлага: modern Luau, deprecated API (албан ёсны docs-оос автоматаар үүсгэсэн ~560 API), архитектур, **тоглоомын 14 төрлийн playbook**, Server Authority, аюулгүй байдал, DataStore, UI design system, гүйцэтгэлийн хатуу төсөв, монетизаци ба 2026 оны бодлого, **3D загвар/Blender/asset pipeline**, **polish, QA, launch**, sharp-edges (35 алдаа), toolchain, монгол нэр томьёо |
| `templates/` | 21 бэлэн Luau модуль: bootstrap, `Net`, `Guard`, `RateLimiter`, `Trove`, `Config`, `BufferCodec`, session-lock-той `DataService`, давхардалгүй `MonetizationService`, `ShopService`, `ModerationService`, **`TradeLogic`/`TradeService` (dupe-гүй солилцоо)**, **`RoundService`**, **`LeaderboardService`**, **`InputController` (Input Action System)**, `MovementService`, `Theme`, `Components`, `UIController` |
| `scripts/luau_lint.py` | 59 гар дүрэм (аюулгүй байдлын CL110–CL118 орсон) + **Roblox-ийн албан ёсны docs-оос үүсгэсэн 391 deprecated нэр**. Зөв Luau-г (`math.pow`, `unpack`) буруу гэж тэмдэглэдэггүй |
| `scripts/scaffold.py` | Rojo төсөл үүсгэгч (Selene, StyLua, Rokit, `.luaurc`) |

### 1.2 хувилбарт юу шинэ вэ? — өөрийгөө шалгадаг болсон

- **Тест:** цэвэр логиктой template-үүдэд (`RateLimiter`, `Guard`, `BufferCodec`, `Trove`, `TradeLogic`) Lune дээр Studio-гүйгээр ажилладаг 51 тест бий. Хамгаалалтыг санаатай устгахад тест унадаг эсэхийг (mutation) шалгасан.
- **Бие даасан review-г өөр дээрээ туршсан:** reviewer agent энэ хувилбарын шинэ template-үүдээс 2 HIGH, 7 MEDIUM алдаа олсон (trade crash-ийн үеийн dupe, map stream болоогүй үед унах, `writer(0)` төгсгөлгүй давталт…) — бүгдийг зассан.
- **Бие даасан review:** код бичсэний дараа зохиогчийн бодлыг мэдэхгүй шинэ `cluau-reviewer` agent кодыг "эвдэрсэн" гэж үзээд шалгана. Алдааны каталог 65 болж өргөжсөн (trade dupe, respawn race, streaming nil, teleport data trust…).
- **Хамгийн эрсдэлтэй системүүдийн template:** Trade, Round, Leaderboard, Input Action System.
- **Аюулгүй байдлын lint:** `SetAsync` player key-д, `PurchaseId`-гүй `ProcessReceipt`, хадгалахаас өмнө `PurchaseGranted`, зайн шалгалтгүй `Touched`/`ProximityPrompt`, шалгалтгүй remote гэх мэтийг автоматаар барина.
- **Eval:** монгол, англи 19 хүсэлтээр skill зөв асаж байгаа, хуучирсан код бичихгүй байгаа, монголоор хариулж байгааг хэмждэг.

### 1.1 хувилбарт юу шинэ вэ?

- **Албан ёсны Roblox docs-оос шалгасан.** Skill-д дурдсан бүх `Class:Method` (380+) Roblox-ийн `creator-docs`-д байгаа эсэхийг `tools/verify_api_refs.py` шалгадаг — зохиомол (hallucinated) API байхгүй. CI долоо хоног бүр Roblox шинэ API deprecated болгосон эсэхийг шалгана.
- **Том студи шиг сэтгэдэг:** тоглоомын төрлийг эхлээд тодорхойлж, түүнд тохирох архитектур (tower defense, simulator, shooter, farming, steal г.м. 14 төрөл), ownership map, гүйцэтгэлийн хатуу төсөв (KB/s, draw call, NPC тоо) ашиглана.
- **2026 оны өөрчлөлтүүд:** Server Authority, PhysicsService → `workspace`, Teleport GUID, `…Async` нэрс, Input Action System, Roblox Plus, DataStore-ийн шинэ хязгаар, нас-д суурилсан бүртгэл.
- **3D загвар ба чанар:** Blender экспорт тохиргоо, 20k триангл, PBR, instancing, SLIM LOD, free model шалгах, game feel, QA, launch checklist.
- **Шударга байдал:** Claude юу шалгасан, юу шалгаагүйгээ үнэнээр хэлнэ; тоглож үзээгүй бол "тест хийсэн" гэж хэзээ ч хэлэхгүй.

### Суулгах

**1. Claude Code — plugin marketplace (санал болгож байна)**

```
/plugin marketplace add d3vnmd/cluau
/plugin install cluau@cluau
```

**2. Claude.ai / Claude Desktop**

[Releases](https://github.com/d3vnmd/cluau/releases/latest) хуудаснаас `cluau-skill.zip`-ийг татаад → **Settings → Capabilities → Skills → Upload skill**.

**3. Гараар (Claude Code)**

```bash
# Хувийн (бүх төсөлд)
unzip cluau-skill.zip -d ~/.claude/skills/
# эсвэл тухайн төсөлд
unzip cluau-skill.zip -d .claude/skills/
```

### Хэрэглэх жишээ

Skill автоматаар идэвхжинэ — "Roblox" гэж хэлэхгүй байсан ч болно:

- "Обби тоглоомын checkpoint систем хийж өг, датаг нь хадгалдаг байх"
- "Simulator тоглоомд дэлгүүрийн UI хийж өг, гар утсан дээр ч гоё харагдах"
- "Энэ скрипт яагаад ажиллахгүй байна? `attempt to index nil with 'Humanoid'`"
- "Game pass худалдаж авахад 2× coin өгдөг болгох"
- "Миний тоглоом гацаад байна, юунаас болж байгааг олоход туслаач"

Илүү олон жишээ: [`docs/EXAMPLES.md`](docs/EXAMPLES.md)

### Linter ашиглах

```bash
python3 skills/cluau/scripts/luau_lint.py path/to/your/src
python3 skills/cluau/scripts/luau_lint.py --list-rules
```

```
src/Old.luau:7:1: error CL001 Deprecated `wait()` — use `task.wait()`.
src/Old.luau:24:18: error CL030 `Humanoid:LoadAnimation` is deprecated — use the `Animator` inside the Humanoid.
src/Hud.luau:43:7: warn CL090 `TextScaled = true` causes inconsistent text sizes ...
```

---

## English

### What is Cluau?

**Cluau** turns Claude into a senior Roblox engineer, systems-minded game designer and UI artist. It is built on two promises:

1. **No broken, deprecated or insecure code.** Every API exists today and is not deprecated; logic runs on the correct side of the client/server boundary; every remote is validated for type, range, rate, ownership and state; nothing about currency, damage, prices or rewards is trusted from the client; code survives lag, StreamingEnabled, respawns, players leaving mid-call and server shutdown.
2. **No AI-slop UI.** No default purple-blue gradients, emoji buttons, glass-on-glass, `TextScaled` everywhere or "Welcome to the Game!". Instead: an art direction derived from the game, a token system (color, type, space, radius, motion), real interaction states, safe-area-aware responsive layouts, and full mouse/touch/gamepad parity.

### What's inside

```
cluau/
├── .claude-plugin/            plugin.json + marketplace.json (Claude Code plugin)
├── skills/cluau/
│   ├── SKILL.md               the core prompt (operating loop, rules, self-review gate)
│   ├── references/            19 deep-dive guides, loaded on demand
│   │   ├── luau-modern.md         strict types, task library, idioms, pitfalls
│   │   ├── deprecated-apis.md     hand-written migration guide + "NOT deprecated" table
│   │   ├── deprecated-index.md    GENERATED from official docs: ~560 deprecated members
│   │   ├── platform-features.md   GENERATED: Roblox's agent-facing "use this now" feed
│   │   ├── genre-playbooks.md     14 genres: ownership, data, exploits, budgets, monetization
│   │   ├── server-authority.md    AuthorityMode=Server, BindToSimulation, limits
│   │   ├── assets-pipeline.md     Blender/FBX/glTF, meshes, PBR, LOD, rigs, lighting, free models
│   │   ├── polish-qa-launch.md    game feel, audio, accessibility, device lab, launch checklist
│   │   ├── sharp-edges.md         35 ID'd bugs that ship (review format)
│   │   ├── toolchain-workflow.md  evidence levels, Rojo, CI, Studio MCP verification
│   │   ├── architecture.md        containers, replication, services/controllers, streaming
│   │   ├── networking-security.md threat model, validation, rate limits, anti-cheat
│   │   ├── data-persistence.md    session locking, ProfileStore, budgets, failure modes
│   │   ├── ui-design-system.md    art direction → tokens → components → anti-slop audit
│   │   ├── performance.md         profiling workflow, scripts, physics, network, memory
│   │   ├── monetization-policy.md ProcessReceipt, passes, loot-box odds, dark patterns
│   │   ├── game-design.md         loops per genre, progression math, economy, FTUE
│   │   ├── debugging-testing.md   error → cause → fix table, test checklists
│   │   └── mongolian-glossary.md  consistent Mongolian terminology
│   ├── templates/             21 production Luau modules (all --!strict, lint-clean; pure ones unit-tested)
│   │   ├── server/            Main.server, DataService, MonetizationService, ShopService, ModerationService,
│   │   │                      TradeLogic + TradeService, RoundService, LeaderboardService, MovementService
│   │   ├── client/            Main.client, UIController, InputController
│   │   ├── shared/            Net, Guard, RateLimiter, Trove, Config, BufferCodec
│   │   └── ui/                Theme (design tokens), Components (stateful primitives)
│   ├── scripts/
│   │   ├── luau_lint.py       59 hand rules (incl. security CL110–CL118) + 391 generated deprecated names
│   │   ├── data/              deprecated_apis.json (generated)
│   │   └── scaffold.py        Rojo project generator
│   └── assets/project/        default.project.json, selene.toml, stylua.toml, rokit.toml, .luaurc
├── agents/cluau-reviewer.md   independent adversarial reviewer (Claude Code plugin agent)
├── evals/cases.json           19 Mongolian/English behavioral evals
├── tests/
│   ├── luau/                  Lune specs for pure templates (51 tests)
│   ├── fixtures/              good/bad/security fixtures for the linter
│   └── test_*.py              linter, eval-grader tests
├── tools/
│   ├── build.py               validate + package release zips
│   ├── sync_deprecations.py   regenerate deprecation data from Roblox/creator-docs
│   └── verify_api_refs.py     every Class:Member in the skill must exist in the docs
└── .github/workflows/         CI (tests, skill check, Luau syntax, docs verify), weekly docs drift, releases
```

### Install

**Claude Code — plugin marketplace (recommended)**

```
/plugin marketplace add d3vnmd/cluau
/plugin install cluau@cluau
```

**Claude.ai / Claude Desktop** — download `cluau-skill.zip` from the [latest release](https://github.com/d3vnmd/cluau/releases/latest), then **Settings → Capabilities → Skills → Upload skill**.

**Manual (Claude Code)** — unzip into `~/.claude/skills/` (personal) or `<project>/.claude/skills/` (shared with your team via git).

### Use

The skill triggers on any Roblox work — Studio, Luau, remotes, DataStores, UI, obby/simulator/tycoon/round-based games, Output errors, lag, exploits, game passes, Rojo — in English or Mongolian. Try:

- "Build a round-based lobby → intermission → match → results system with a synced countdown."
- "Make the shop UI for my cozy farming game. It must work on phones and with a controller."
- "Review this script for exploits and deprecated APIs." *(paste code)*
- "Add a 2× coins game pass and a 500-coin developer product."
- "Plan the architecture for a tower defense game that handles 1,000 enemies without lag."
- "What Blender export settings and triangle budget should my weapon models use?"
- "Give me a launch checklist for my obby."

### Tools

```bash
# Lint any Roblox codebase (no install needed)
python3 skills/cluau/scripts/luau_lint.py src/ --format json

# Generate a Rojo project with every template wired up
python3 skills/cluau/scripts/scaffold.py ./my-game --name my-game
cd my-game && rokit install && rojo serve
```

Suppress a finding with `-- cluau-ignore CL060` on the line, or `--!cluau-ignore-file` in the first lines of a file.

### Develop & release

```bash
python3 -m unittest discover -s tests   # linter tests (bad fixture + clean templates)
python3 tools/build.py check            # frontmatter, links, manifests, lint-clean templates
python3 tools/build.py package          # dist/cluau-skill-v<version>.zip + SHA256SUMS.txt
```

To publish a release: bump `version` in `.claude-plugin/plugin.json` and `marketplace.json`, add a `## [x.y.z]` section to `CHANGELOG.md`, then push a tag:

```bash
git tag v1.0.0 && git push origin v1.0.0
```

The **Release** workflow tests, packages and publishes the GitHub Release with install notes. See [CONTRIBUTING.md](CONTRIBUTING.md).

### How Cluau checks its own work

| Layer | What it proves | Command |
|---|---|---|
| Lune unit tests | Pure template logic (trades, buffers, limits, validation) behaves under edge cases | `lune run tests/luau/run.luau` |
| cluau-lint | No deprecated/unsafe patterns, security smells, UI slop | `python3 skills/cluau/scripts/luau_lint.py <src>` |
| API verifier | Every API the skill mentions exists in Roblox's official docs | `python3 tools/verify_api_refs.py <creator-docs>` |
| Independent review | A fresh agent with no author context hunts shippable defects | `cluau-reviewer` agent / `references/review-workflow.md` |
| Evals | The skill triggers, answers in Mongolian, and emits lint-clean code | `python3 tools/run_evals.py run --cmd "claude -p"` |
| Studio playtest | Real engine behavior — **still required**; nothing above replaces it | Server & Clients + a low-end phone |

### Staying current with Roblox

Roblox deprecates whole services on a cadence of months. Cluau tracks the official docs source:

```bash
git clone --depth 1 https://github.com/Roblox/creator-docs ../creator-docs
python3 tools/sync_deprecations.py ../creator-docs   # regenerate deprecation data + feature feed
python3 tools/verify_api_refs.py ../creator-docs     # every API the skill mentions must exist
```

The weekly **Roblox docs drift** workflow fails when the docs change, so a new release can follow.
Generated reference content derives from Roblox's creator-docs, licensed CC BY 4.0.

### Honest limits

Without a Studio connection, Claude cannot run your game. Cluau's code is checked against its rules, the linter, the official-docs verifier and a Luau syntax compile in CI. With Roblox Studio's MCP server connected, Cluau can play-test and read Output itself; otherwise always play-test (**Server & Clients** with 2+ players, plus a real low-end phone) before publishing.

### License

[MIT](LICENSE) © 2026 d3vnmd. Roblox, Roblox Studio and Luau are trademarks of Roblox Corporation; this project is not affiliated with or endorsed by Roblox.
