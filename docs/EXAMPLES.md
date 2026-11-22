# Cluau — Example Prompts / Жишээ хүсэлтүүд

Copy any of these into Claude with the Cluau skill installed. Cluau will answer with a plan,
complete files (with exact Studio locations), setup steps and a test plan.

Cluau суулгасан Claude-д эдгээрийг хуулж өгөөрэй. Хариулт нь: төлөвлөгөө → бүрэн код (Studio дахь
байршилтай) → тохиргоо → туршилтын заавар.

## Монгол

### Шинэ систем
- "Обби тоглоомд 50 үе шаттай checkpoint систем хий. Үхэхэд сүүлийн checkpoint дээр төрдөг, DataStore-д хадгалдаг, үе алгасах developer product-той."
- "Simulator: тоглогч газраас кристалл цуглуулж, зарж, цүнхний багтаамжаа ахиулдаг үндсэн цикл хийж өг. Rebirth систем нэм."
- "Раунд суурьтай тоглоом: lobby → 20 секунд intermission → 3 минутын раунд → үр дүн. Бүх тоглогчид таймер ижил харагддаг байх."
- "Tycoon: тоглогч бүрт plot оноож, товч дарж барилга худалдан авдаг, орлого автоматаар нэмэгддэг систем."
- "Tower defense-д нэгж байршуулах систем — байршлыг сервер шалгадаг, мөнгө хүрэлцэхгүй бол болохгүй."

### UI
- "Миний хоррор тоглоомд зориулсан минимал HUD хий: зөвхөн батарейны түвшин, objective текст. Ягаан градиент, emoji хэрэггүй."
- "Pet simulator-ын inventory UI: grid, rarity өнгө, equip товч, утсан дээр ч, геймпадаар ч ажилладаг."
- "Энэ UI-г AI хийсэн юм шиг харагдаж байна, засаад жинхэнэ дизайнер хийсэн юм шиг болгооч." *(screenshot эсвэл кодоо хавсаргана)*
- "Settings цонх: хөгжмийн/дууны түвшин, reduced motion, камер сэгсрэлт — датад хадгалдаг."

### Алдаа засах / шалгах
- "`ServerScriptService.Script:12: attempt to index nil with 'leaderstats'` гэж гарч байна. Код: ..."
- "Энэ скриптийг эксплойт, хуучирсан API, санах ойн алдагдлын талаар шалгаад засаад өг: ..."
- "Тоглогчид өгөгдлөө алдаж байна гэж гомдоллож байна. Миний DataStore код: ..."
- "Сервер 30 тоглогчтой үед гацаж байна. MicroProfiler дээр Heartbeat өндөр байна."

### Монетизаци
- "VIP game pass (chat tag + 1.5× coin) болон 3 төрлийн coin багц developer product хий."
- "Өндөг нээх систем хий — магадлалыг харуулдаг, PolicyService шалгадаг."

## English

### Systems
- "Build a melee combat system with server-side hit validation, combo windows and knockback using LinearVelocity."
- "Create a quest system: 3 daily quests that reset at UTC midnight, progress saved, rewards granted on the server."
- "Add a global weekly leaderboard for wins shown on a SurfaceGui in the lobby."
- "Make a secure trading system between two players with confirmation delay and inventory re-validation."
- "Set up a Rojo project for a new game using the cluau templates."

### UI
- "Design the main menu for a clean sci-fi racing game. Give me the art direction line and the tokens first."
- "My shop UI breaks on iPhone — the buttons go under the notch and are too small. Fix it."
- "Add gamepad support to my existing inventory (selection, B to close, focus restore)."

### Review & performance
- "Audit this LocalScript — what can an exploiter abuse?" *(paste code)*
- "Migrate this 2019 script to modern Luau." *(paste code)*
- "My game uses 1,400 MB on mobile. Where should I look?"

### Design
- "I want an original cozy fishing game. Give me a design brief, core loop with numbers, and an MVP list."
- "Tune my simulator's upgrade costs so the 10th zone takes about 2 hours of play."
