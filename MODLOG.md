# Ashen Oath: журнал разработки и проверки

## 2026-10-08 · версия 0.2.0

- Продолжена разработка звука и боевого представления. Созданы семь оригинальных PCM16 WAV через воспроизводимый `tools/generate_audio.py`, без внешних семплов или платных сервисов.
- Звуковой пул из четырёх голосов, тихая атмосфера только на 3D-вкладках, настройки громкости/отключения, остановка коротких звуков и пауза атмосферы в фоне. Старые schema-1 JSON совместимы.
- Фактический урон показан временными 3D-маркерами, третий удар уровня 3+ помечен резонансом. Эффекты отключаются при уменьшении движения и очищаются при навигации.
- Проверки: 111 core / 25 UI / 17 world / 12 audio, ноль ошибок. Исправлена очистка активных аудиоплееров при завершении тестового приложения.
- Реальный OpenGL-кадр боевого эффекта просмотрен. `um win launch` и `um win shot` использованы для нового тестового окна; `um-combat-02.png` просмотрен.
- Временный read-only AVD QuietJoyQA запущен с PID 41088, host GLES3.1, без окна и аудио. Реальными ADB-касаниями пройдена первая охота: 40 XP / 4 ресурса / 1 бой. Отключение звука и громкость 35% пережили перезапуск.
- Версия APK 0.2.0/code 2, minSDK24, targetSDK36, debug-подпись v2/v3. Итоговые суммы APK и ZIP — `artifacts/SHA256SUMS.txt`; предыдущие записи ниже относятся к 0.1.0.
- Окончательная пересборка повторно установлена поверх тестовой: сохранены 40 XP, один бой и настройки звука. Пакет проверяется настоящим `um publish check`, ZIP — CRC; SHA256 создаётся автоматически при упаковке.
- После финального повтора баланс остался 40 XP / 1 бой; временный emulator-5554 остановлен через `emu kill`. Чужие процессы и общий ADB server не останавливались.

## 2026-10-08 · среда и выбранный путь

- Пользователь попросил продолжить собственное Android-приложение с помощью universal-modder. Выбран открытый исходный Godot-проект с прямым экспортом, без модификации установленных сторонних игр.
- Прочитаны `mod-any-game`, `game-automation` и Godot engine playbook из установленного universal-modder 0.2.0.
- Реальные команды `um kb search Godot`, `um kb search habit` выполнены в локальной базе плагина; совпадений нет.
- Python CLI установлен в отдельную среду `.tools/um-env` (universal-modder 0.2.0, Pillow, numpy, PyYAML).
- Официальный GitHub API подтвердил актуальный релиз 4.x: Godot 4.7.2-stable, опубликован 2026-08-18. Editor и templates должны проходить SHA-512 проверку перед распаковкой.
- Нынешние SDK: Java 17; Android SDK platform-tools и build-tools 36.0.0 уже присутствуют. Пользовательские SDK, реестр, saves и настройки редактора не изменяются. Portable Godot настроен через `_sc_`.
- Существующий AVD QuietJoyQA запущен без окна, с `-read-only -no-snapshot-save`, отдельный процесс PID 28108. ADB emulator-5554 загрузился (`sys.boot_completed=1`). Это временная сессия, изменения приложений не сохраняются обратно в AVD.
- Крупные загрузки GitHub целиком зависали без прогресса. Перешли на bounded HTTP byte ranges с повтором и общей SHA-512 проверкой.
- Шрифты Noto Sans и Cormorant загружены из Google Fonts, лицензии OFL сохранены рядом.

## Проверка

- Windows editor скачан, официальная SHA-512 совпала; версия бинарника `4.7.2.stable.official.ed1daf0bf`.
- Первый `--headless --editor --quit` импорт проекта завершился с кодом 0; кириллические шрифты и icon.svg импортированы.
- Portable editor подтвердил локальные пути Android SDK / JDK и создал локальный debug keystore.
- Пакет Android: `org.ashenoath.app`; выход: `artifacts/ashen-oath-debug.apk`.
- `um win ps` выполнен без событий мыши/клавиатуры. Существующий FFmpeg 7.1.1 не имеет gfxcapture; скачан отдельный FFmpeg в `.tools/ffmpeg`, проверенный по SHA-256 GitHub release asset.
- Реальные `um win launch` и `um win shot` выполнены для автоматической QA-сцены. `artifacts/um-native-window.png` и уменьшенная копия показали настоящее окно 432×900 с героем, противником и русским интерфейсом; screenshot просмотрен. Ввод мыши и клавиатуры не отправлялся.
- В portable editor отключён `export/android/shutdown_adb_on_exit`: исходник Godot подтвердил, что значение по умолчанию останавливает общий ADB server после импорта. Это устраняет временный статус offline при последовательной проверке APK.
- Templates скачаны полностью и прошли SHA-512; Android debug/release и Windows templates установлены.
- APK экспортирован и проверен apksigner (v2/v3), minSDK 24, targetSDK 36, ARM64 + x86_64. Установлен на read-only AVD Android 13 / API33.
- `install_android.ps1` использует MAIN/LAUNCHER intent: в Godot4.7 доступная launcher activity — `GodotAppLauncher`, прямой вызов внутренней `GodotApp` запрещён Android.
- Старый emulator32.1.12 по умолчанию отключает GLESDynamicVersion: обе попытки с SwiftShader и host давали только GLES2. Флаг процесса `-feature GLESDynamicVersion` включил GLES3.1; исходные SDK/AVD ini не редактировались. Текущий emulator launcher PID35024, ADB emulator-5554.
- Реальные ADB касания подтвердили создание привычки, начисление20XP, подготовку, победу в первой охоте (+20XP), переход в журнал и сохранение40XP/2events/1battle после force-stop/reopen.
- Android chronicle обнаружил ожидание рендера без завершения в статичном журнале; передано агентам UI/scene, окончательный пакет ожидает исправления.
- Android replay не изменил40XP/4resources/2events/1battle. Airplane mode=1, Wi-Fi=0 и последующий force-stop/reopen сохранили данные.
- Android SAF экспорт JSON прошёл: файл в Download прочитан через ADB и распарсен, данные совпали. Все действия происходят в временном read-only профиле эмулятора.
- Scene исправил chronicle: bounded force_draw без бесконечного frame_post_draw, с восстановлением low_processor_usage. Окончательная Android пересборка выполняется для проверки PNG.

## Финальный проверенный пакет

- Android PNG-хроника исправлена и подтверждена: два последовательных открытия показали карточку; настоящий SAF save записал PNG432×768, файл получен из эмулятора и просмотрен (`artifacts/android-chronicle-export.png`).
- HOME во время replay и возврат на финальном APK завершили сцену без повторной награды:40XP/4resources/2events/1battle. Все финальные действия прошли в авиарежиме.
- Финальный APK58 754 936байт, SHA-256 `43e8201d1f66d7975d2d6f1177a49750a38cfe8fa756df5fdc72449507e22ad8`; minSDK24/targetSDK36, ARM64+x86_64, подписьv2/v3 подтверждены повторно.
- Финальный logcat по PID приложения содержит только shadercache warning с успешной перекомпиляцией; crash/script error отсутствует.
- Read-only emulator-5554 завершён после проверки, данные временной сессии не сохраняются в исходный AVD. Общий ADB server не останавливается.
- README и verification согласованы:111core /22UI /14world. Проверка и упаковка исходников выполняются `python tools/check_package.py --archive`; SDK/бинарники/ключи/логи/профили исключены.


## 0.3.0 — 8 октября 2026

CC0-анатомия героя, сканированные PBR-материалы, настоящая растительность, перспективная камера, MSAA, обновлённые огонь и освещение. Источники и лицензии сохранены. Исправлено затухание кольца удара в Compatibility через alpha материала.

## 0.3.1 — 8 октября 2026

Повышено разрешение 3D-буфера без изменения UI. Добавлены отдельное движение пол пальто, колебание плаща и полный сброс позы в reduced motion. Замахи мягче, плечевой протез менее шарообразный, складки ткани спокойнее. 27 UI и 24 проверки сцены успешны.

## 0.4.0 — 8 октября 2026

Sintel derivative (CC BY 3.0), новый 19-bone rig со скиннингом и idle/strike/hit. Оружие следует за костями, mixer останавливается в невидимой сцене, reduced motion замораживает pose. Полноценный реализм AAA не достигнут; найден реалистичный asset-кандидат, который требует согласования доступа через аккаунт.


## 0.4.1
User-owned RFA Unity package safely extracted without executing scripts; Blender FBX conversion, 125-bone action retarget and axis correction, 2k/1k PBR maps. Raw licensed resources excluded from Git and distribution ZIP. A Verdant Trail full CC0 environment downloaded, vendor SHA1 and ZIP CRC verified; scene not yet included in APK.


## 0.5.1 forest revision
Pine impostor: native Godot render, 512x1024 RGBA, transparent background, fixed-Y billboard with bottom at terrain height. Alpha scissor with alpha-to-coverage; original CC0 tree mesh. Nearby scan rock resources preserve high geometry with averaged geometric normals. Scene uses a textured trail on undulating terrain, MultiMesh grass, curated cliffs and unified daylight/fire. Normal 3D oversampling raised from 1.25 to 1.6; high remains 2.0 and UI logical dimensions remain unchanged.


## 0.6.0 — cartoon revision
The active world uses original procedural trees, bushes, terrain and camp geometry with flat colors and banded diffuse lighting. Sintel (Angela Guenette / Blender Foundation, CC BY 3.0) retains its original attribution and custom 19-bone rig with idle, strike and hit clips. No generated bitmap assets were added. World-space procedural trail has no texture, alpha or sprite pivot. Normal/high presets use 30/42 trees; economy hides the 3D viewport. The private Maiden, Verdant Trail and photographic foliage are not used or included in the Android APK. Legacy open asset files remain in the source archive with their existing credits.


## 0.7.0 — pixel arcade direction
Original imagegen-generated forest camp and original Iara/creature art, inspired by the pixel-art arcade visual language of the supplied Scott Pilgrim references. No reference-game sprites, characters, logos or screenshots ship in the app. Environment PNG: 384x256, 48 colors. Actor PNG: 576x256, 4 columns by 2 rows, 144x128 cells; top row idle/attack/hurt/victory, bottom row husk/bellkeeper/root heart/fire. Characters face right; enemies are flipped at draw time. Pivot: bottom-center, fixed source baseline. Nearest filtering and a fixed 384-pixel viewport preserve the pixel grid. Master images preserved separately, excluded from APK. tools/prepare_pixel_assets.ps1 aligns the variable raw regions on equal canvases, then UM sprite pixelate converts the atlas. Combat consumes committed battle logs without changing progression. Background layers are baked into the environment image; no depth camera or 3D model is used.

Actor colors: 96 for the full eight-cell atlas, preserving whites in eyes and sword. RGBA transparency is preserved from the generated source; nearest sampling avoids soft resampling. Palette generation, sheet alignment and actual in-game visual proof are included in tools and artifacts.


## 0.7.1 — RuStore release preparation
Added offline privacy/support screen with user-approved contact, Godot MIT and Noto OFL text to package. Full-background 512px icon matching the launcher design. Release template exported without debug signing, ZIP aligned for 16KB native library pages, signed with a separately stored RSA3072 key (APK v2/v3). No secrets distributed. Four real 9:16 application screenshots, store description, privacy HTML and upload/migration instructions prepared. Android 13 install/launch and 163 test assertions passed; headless audio test has two resource-shutdown warnings. Actual publication and privacy-page hosting are not performed.


## 0.7.2 — store artwork
Original imagegen Iara and amber lantern icon: opaque square, 256x256/96-color grid, nearest scale to 512x512. Four real app captures per device with original marketing frames, phone 1080x1920 and portrait tablet 1200x1920. Masters are excluded from the APK. Reproduction tools: render_store_icon.gd, capture_store_app.gd, render_store_frames.gd, render_store_preview.gd.
