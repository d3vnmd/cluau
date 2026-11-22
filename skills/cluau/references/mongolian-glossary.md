# Монгол хэлний нэр томьёо (Mongolian Glossary)

Монгол хэлээр хариулахдаа энэ нэр томьёог тогтвортой ашигла. Roblox Studio дээр хэрэглэгч харж байгаа нэрс (API, Explorer дахь объект, Properties) **англиар** үлдэнэ — хаалтанд эсвэл код хэлбэрээр бич.

Use these consistently when answering in Mongolian. Keep Studio-visible names in English.

## Хэв маяг (Style)

- Энгийн, ойлгомжтой, найрсаг гэхдээ мэргэжлийн. "Та" гэж хандана.
- Эхлээд үр дүн (код + хаана тавих), дараа нь богино тайлбар.
- Англи үгийг шаардлагагүй хольж бичихгүй; харин техникийн нэр (RemoteEvent, DataStore) орчуулахгүй.
- Жишээ: "Энэ кодыг `ServerScriptService` дотор **Script** болгож тавина уу."

## Нэр томьёо

| English | Монгол | Тайлбар |
|---|---|---|
| Script (server) | сервер скрипт (`Script`) | Сервер дээр ажиллана |
| LocalScript | клиент скрипт (`LocalScript`) | Тоглогчийн төхөөрөмж дээр ажиллана |
| ModuleScript | модуль скрипт (`ModuleScript`) | `require`-ээр дуудагдана |
| server | сервер | |
| client | клиент / тоглогчийн тал | |
| replicate | хуулбарлагдах, синк хийгдэх | |
| RemoteEvent | `RemoteEvent` (сервер–клиент холбоос) | |
| exploit / exploiter | эксплойт / хууран мэхлэгч (читер) | |
| validate | шалгах, баталгаажуулах | |
| rate limit | хурдны хязгаар | |
| DataStore | `DataStore` (өгөгдөл хадгалах сан) | |
| save / load | хадгалах / ачаалах | |
| session lock | сессийн түгжээ | Хоёр сервер нэг өгөгдөлд зэрэг бичихээс сэргийлнэ |
| data loss | өгөгдөл алдагдах | |
| duplication (dupe) | хуулбарлах алдаа (дюп) | |
| deprecated | хуучирсан (deprecated) | Roblox цаашид дэмжихгүй |
| UI / GUI | интерфэйс (UI) | |
| HUD | HUD (дэлгэц дээрх үндсэн мэдээлэл) | |
| button | товч | |
| frame / panel | хүрээ / самбар | |
| layout | байрлал, зохион байгуулалт | |
| responsive | бүх дэлгэцэнд тохирох | |
| safe area | аюулгүй бүс (notch, камерын хэсэг) | |
| hover / pressed / disabled | хулгана дээр нь / дарагдсан / идэвхгүй | |
| gamepad / controller | геймпад | |
| touch / mobile | мэдрэгч дэлгэц / утас | |
| tween / animation | хөдөлгөөн (`TweenService`) / анимэйшн | |
| lag | гацалт, саатал | |
| memory leak | санах ойн алдагдал | |
| performance | гүйцэтгэл | |
| game pass | `Game Pass` (нэг удаа худалдан авах) | |
| developer product | `Developer Product` (давтан худалдан авах) | |
| receipt | төлбөрийн баримт (`ProcessReceipt`) | |
| loot box / egg | азын хайрцаг / өндөг | Магадлалыг заавал харуулна |
| odds | магадлал | |
| core loop | үндсэн тоглоомын цикл | |
| progression | ахиц, түвшин ахих систем | |
| rebirth | дахин төрөлт (rebirth) | |
| obby | обби (саадтай зам) | |
| simulator | симулятор | |
| tycoon | тайкун | |
| round | раунд | |
| checkpoint | хяналтын цэг (checkpoint) | |
| leaderboard | тэргүүлэгчдийн самбар | |
| respawn | дахин төрөх | |
| character | дүр (character) | |
| tag (CollectionService) | шошго (tag) | |
| attribute | аттрибут (`SetAttribute`) | |
| bug / error | алдаа | |
| Output window | `Output` цонх | |
| Explorer / Properties | `Explorer` / `Properties` цонх | |
| publish | нийтлэх (Publish to Roblox) | |
| Game Settings | `Game Settings` (тоглоомын тохиргоо) | |

## Түгээмэл өгүүлбэрүүд

- "Энэ код серверт ажиллах ёстой, учир нь клиент дээр байвал читерүүд өөрчилж чадна."
- "`wait()` хуучирсан — оронд нь `task.wait()` ашиглана."
- "Studio дээр DataStore туршихын тулд Game Settings → Security → **Enable Studio Access to API Services**-ийг асаана уу."
- "Тест хийхдээ Test → **Start Server** + 2 тоглогчоор шалгаарай."
- "UI-г утас, компьютер, геймпад гурвууланд нь шалгасан."
