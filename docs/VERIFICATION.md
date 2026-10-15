# Фактическая проверка — 8 октября 2026

## Выполнено

| Проверка | Результат |
|---|---|
| Импорт/запуск Godot4.7.2 | Успешно, без ошибок парсера |
| `tests/core_tests.gd` |111 passed, 0 failed |
| `tests/ui_tests.gd -- --ui-tests` |25 passed, 0 failed |
| `tools/verify_world.gd` |21 passed, 0 failed |
| `tests/audio_tests.gd` |12 passed, 0 failed |
| `tools/financial_model.py` |25assertions passed |
| `tools/check_contrast.py` |Все5основных пар≥4.5:1 |
| Настоящий OpenGL-рендер |Сцены и UI получены на NVIDIA RTX3050 Laptop |
| Universal Modder |`um kb search`, `um win launch`, `um win shot` действительно выполнены |
| Карточка хроники |PNG 432×768 из настоящей сцены; headless guard; после рендера нет оставшихся viewport |

Ядро проверяет двойную отметку, отмену/повтор, лимиты, минимальную версию, редактирование без пересчёта истории, дневную границу, перевод часов, поездку/DST, расписания, паузу/отдых, предметы, тактику, подготовку, единственность боевой награды, всю цепочку с тремя привычками, перезапуск, повреждённый импорт, восстановление backup и откат при ошибке записи.

UI-тесты управляют настоящими Godot-контролами и сигналами в изолированном профиле: невалидная форма, создание, изменение/переназначение ветки, недельная цель, минимум, двойной вызов, отмена/повтор, экипировка, охота, плохой/хороший импорт, настройки, экономичный режим, отдых и отсутствие названий привычек в публичной хронике. Они не эмулируют аппаратные касания Android.

Представление3D: переход на другую вкладку останавливает анимацию, старый coroutine не выдаёт повторное завершение, повторная остановка безопасна, уменьшение движения поддерживается, видимость экипировки соответствует выбранному предмету. Наград в коде сцены нет.

Скриншоты `artifacts/01-camp.png`, `02-hero.png`, `03-hunt.png`, `04-journal.png` сняты самой работающей программой; `um-native-window.png` — захват окна через Windows.Graphics.Capture Universal Modder. Они показывают тестовый профиль. Концепт-арт и предварительно отрендеренное видео не использовались как доказательство работы.

## Версия 0.2.0 — звук и отклик боя

Добавлены семь собственных WAV: лагерь, охота, замах, удар, резонанс, награда и победа. Синтез воспроизводится `python tools/generate_audio.py`; PCM16 mono 22050 Hz. Проверены ненулевой RMS, запас до клиппинга, импорт всех семи файлов, пул воспроизведения, отключение, громкость, пауза и совместимость прежних сохранений. Аппаратное звучание на физическом телефоне и субъективный звуковой баланс не оценивались; эмулятор работает с `-no-audio`.

Отображение урона использует сохранённые значения `hero_damage` и `enemy_damage`; на третьем ударе героя уровня 3+ показан «Резонанс». Уменьшение движения отключает числа и кольца. На выходе из боя временные узлы и tween очищаются. Регрессии проверяют очистку, паузу и прежнюю единственность завершения. `artifacts/combat-resonance.png` — настоящий OpenGL-рендер явно заданного тестового журнала, а не пользовательского прогресса. `artifacts/um-combat-02.png` — окно этой сцены, захваченное Universal Modder.

На Android 13 / API 33 установлен APK 0.2.0/code 2. Реальными ADB-касаниями добавлен пример плана, отмечено первое дело и проведена первая охота. Сохранение содержит 40 XP, один бой и четыре ресурса. В настоящем окне настроек отключён звук и выставлены 35%; после force-stop и запуска сохранены `sound_enabled=false`, `sound_volume=0.35` и весь прогресс. Доказательства: `android-02-sound-settings.png`, `android-02-settings-scroll.png`, `android-02-state.json`. Logcat не показал ошибок GDScript; предупреждение shader cache вызвало перекомпиляцию. Минимальный SDK 24, целевой SDK 36, обе архитектуры прежние; APK имеет debug-подпись v2/v3. Актуальные суммы итогового APK и ZIP находятся в `artifacts/SHA256SUMS.txt`.

## Android 0.1.0 — предыдущая проверка полного цикла

APK успешно экспортирован Godot 4.7.2 и установлен через ADB на Android 13 / API 33, x86_64 AVD QuietJoyQA. Эмулятор запущен без окна в read-only сессии, без сохранения snapshot; касания и ввод отправлялись только ему. После исправления конфигурации запуска используется host GPU и OpenGL ES 3.1.

Фактически выполнены аппаратные события ADB: «Создать привычку», ввод `Walk 10 minutes`, сохранение, «Выполнено», переход к охоте, начало боя и переход к журналу. JSON внутри приложения подтвердил 20 XP за дело и одну подготовку; победа над Пустотником добавила ещё 20 XP, контракт `husk` и ровно одну запись боя. После `am force-stop` и повторного запуска сохранились 40 XP, два события и один бой. Скриншоты находятся в `artifacts/android-01-first-launch.png`, `android-04-habit-created.png`, `android-05-hunt.png`, `android-06-battle.png`, `android-07-journal.png`.

Повтор просмотра победы сохранил ровно 40 XP, 4 ресурса, два события и один бой: повторной награды нет. В read-only эмуляторе включён авиарежим и отключён Wi-Fi; повторный запуск загрузил те же данные без сети. Через настоящий Android Storage Access Framework сохранён JSON в Download, затем файл прочитан и разобран: 40 XP и один бой совпали с состоянием приложения. Экспорт проверен через системный диалог, не только по вызову внутренней функции.

`aapt dump badging` подтвердил пакет `org.ashenoath.app`, version 0.1.0/code 1, min SDK 24, target/compile SDK 36, архитектуры `arm64-v8a` и `x86_64`. `apksigner verify --verbose --print-certs` подтвердил debug-подпись APK, схемы v2 и v3. Самостоятельная проверка ARM64 на физическом телефоне не проводилась.

Диагностика среды: два первых запуска эмулятора были ограничены OpenGL ES 2.0 и завершались EGL_BAD_CONFIG. Причина подтверждена в SDK `advancedFeatures.ini`: GLESDynamicVersion отключён. Исправление задано только флагом процесса `-feature GLESDynamicVersion`, пользовательские настройки SDK не редактировались. На холодных запусках Godot предупреждал о непрочитанном shader cache и успешно перекомпилировал его; краха приложения не было. Финальный logcat отфильтрован по PID приложения и сохранён в `artifacts/android-final-logcat.log`.

На первом Android испытании найдено зависание PNG-хроники на ожидании кадра в статичном журнале. Исправление проверено на окончательном APK: два последовательных открытия показали настоящую карточку с героем, а сохранение через Android SAF создало корректный PNG 432×768. Файл получен из эмулятора, декодирован и просмотрен: `artifacts/android-chronicle-export.png`. Названия личных привычек в карточке отсутствуют. Скриншоты preview: `android-12-chronicle-fixed.png`, `android-14-chronicle-repeat.png`.

На окончательном APK проверены HOME во время повторного просмотра боя и возврат в приложение: сцена завершила повтор, сохранились 40 XP, 4 ресурса, два события, один бой. Повторной награды и сбоя не было; `artifacts/android-15-final-resumed.png`. Проверки выполнены в авиарежиме. После снятия evidence временный read-only эмулятор остановлен; общий ADB server и другие AVD не останавливались.

Для предыдущей версии 0.1.0 проверенный APK имел 58 754 936 байт и SHA-256 `43e8201d1f66d7975d2d6f1177a49750a38cfe8fa756df5fdc72449507e22ad8`. Текущий APK заменён версией 0.2.0; его сумма указана выше через SHA256SUMS. Все сборки пока отладочные.

## Не выполнено

Физический телефон, устойчивые30FPS/P95/P99, расход батареи, термальный троттлинг, достоверный cold-start benchmark, TalkBack, все OEM-границы экрана, магазинная валидация release AAB/16KB страниц, реальные пользователи и платежи. Список продуктовых гипотез не является проведённым исследованием. Искусственные даты в тестах не означают месячного использования человеком.

## Графический срез 0.3.0

После замены графики повторены 111 проверок ядра, 25 UI, 21 сцены и 12 звука (169 успешных). UI запускается с `-- --ui-tests`, чтобы изолировать сохранение. Настоящие OpenGL-кадры обновлены; исходный герой сохранён в `artifacts/hero-before-realism.png`. Сканы источников прошли проверку MD5. Проверки не подтверждают фотореализм AAA или FPS на физическом телефоне.

Android 0.3.0 установлен в отдельный readonly QuietJoyQA (API 33 / OpenGL ES 3.1). Просмотрены лагерь, герой и Пустотник; поворот героя и запуск боя выполнены касаниями ADB. Одна тестовая отметка и победа дали 40 XP, 1 бой, 4 ресурса. Принудительное закрытие и запуск через launcher сохранили значения. Снимки: `android-realism-hero.png`, `android-realism-battle.png`. Подпись APK v2/v3 проверена apksigner. Размер APK 111681961 байт. В звуковом headless-тесте все 12 assertions успешны, но при завершении процесса есть предупреждение о 4 ObjectDB / 2 resources; это не скрывается как чистый лог. Android-лог содержит предупреждение о перекомпиляции shader cache, ошибок скриптов не найдено.

Для 0.3.0 реально выполнены `um win launch` и `um win shot`: `artifacts/realistic-universal-modder.png`. Universal Modder проверил 159 распространяемых файлов: 0 failures, 0 warnings.

## Продолжение: 0.3.1

Повторены 27 UI и 24 проверки сцены, все успешны. Дополнительно проверены реальное увеличение буфера при high quality, сохранение логического размера UI, движение ткани и сброс reduced motion. APK 0.3.1 (code 4) установлен и запущен на readonly Android API33; поворот героя работает, high_quality включён и сохранён через форму, кадр просмотрен: `artifacts/android-0.3.1-high.png`. Проверена подпись APK. Ядро и звук не менялись; их последние результаты относятся к 0.3.0, повторный прогон не заявляется.


## Скелетный герой 0.4.0

Повторены 111 проверок ядра, 27 UI и 27 сцены: 165 успешных, 0 failures. Проверены Skeleton3D с 19 костями, idle/strike/hit, пауза при скрытии сцены, reduced motion и сохранение ориентации оружия при смене вкладки. UI headless при завершении сообщает 5 ObjectDB / 2 resources; успешные assertions не объявляются чистым завершением без предупреждений. Звуковой тест в этом проходе не повторялся.

APK 0.4.0/code 5 экспортирован и проверен apksigner. На отдельном readonly Android API33 установлен, запущен и просмотрен новый герой: `artifacts/android-0.4.0-hero.png`. Настоящими касаниями добавлен пример плана, отмечено чтение и завершена охота. Сохранение подтвердило 40 XP, 1 бой и 4 ресурса; после force-stop и запуска через launcher значения совпали. Доказательства: `android-0.4.0-battle.png`, `android-0.4.0-state.json`, `android-0.4.0-restarted-state.json`. В logcat после перезапуска не найдено SCRIPT ERROR, Parse Error или FATAL EXCEPTION. Только собственный временный эмулятор остановлен.

Исходный архив Sintel не содержит готового рига: скелет, веса и три клипа созданы локально воспроизводимым `tools/build_skinned_hero.py`. Лицензия CC BY 3.0, авторы и изменения записаны в provenance и THIRD_PARTY_NOTICES. Текущий персонаж стилизован; проверка не подтверждает качество The Witcher 3 или производительность на физическом телефоне.

Для дальнейшей замены рассмотрена бесплатная Maiden Assassin от RetroStyleGames на CGTrader. Нажатие Free Download открыло форму входа: `artifacts/cgtrader-login-required.jpg`. Файлы не получены, вход не выполнен. По исходному брифу действия в аккаунтах требуют отдельного согласования. Модель не включена в проект и исходный архив; её Royalty Free лицензия также ограничивает распространение исходных ресурсов.


## 0.4.1 — licensed hero and environment download

27 world and 27 UI assertions repeated successfully with the 125-bone Maiden Assassin. The UI process retains the known 5 ObjectDB / 2 resources shutdown warning. Core/audio code unchanged; no new run claimed. Godot real OpenGL render inspected (`world_hero.png`); first failed FBX geometry/animation conversions corrected before packaging. APK exported, debug signatures v2/v3 verified.

A Verdant Trail original archive (1,918,654,862 bytes) downloaded and extracted. Vendor SHA1 matched and all ZIP CRCs passed. Blender 4.5.9 opened the scene with autoexec disabled: 173 objects, 163 mesh objects, camera camera_28mm_animated, zero missing external image files. It is not yet optimized or used in the APK.

An already running QuietJoyQA emulator did not provide the required OpenGL context (EGL_BAD_CONFIG); APK installation there does not count as graphics verification. A separate AshenMaidenQA read-only API33 AVD was created with host GPU/GLESDynamicVersion and the package installed and launched successfully. Physical Android performance remains unverified.

The new hero was visibly rendered on AshenMaidenQA Android API33 (`artifacts/android-0.4.1-hero.png`). Post-launch PID log did not contain SCRIPT ERROR, Parse Error or FATAL EXCEPTION. This does not certify FPS or thermals on physical phones.


## 0.5.0 mobile location
30 world assertions and 27 UI assertions passed. UI requires -- --ui-tests for save isolation; an initial invocation without that flag failed one presentation assertion and was rerun correctly. The correctly isolated UI run has no ERROR/WARNING entries; older shutdown warnings are documented above. Core/audio unchanged, no fresh run claimed. Real desktop OpenGL render inspected. Android APK signature v2/v3 verified. Host GPU emulator initially reported GL_OUT_OF_MEMORY (0x505) and exited; this is not counted as an Android graphics pass. All shared foliage/character texture imports additionally switched to GPU compression with mipmaps. Physical-phone FPS/thermals not measured.

Android cold-boot investigation: disk-full export produced empty imported font/audio and invalid texture entries despite export/signature success. This APK was rejected by runtime inspection and rebuilt after freeing disk space. build.ps1 now rejects empty imported resource entries. Emulators were restarted only for the owned AshenMaidenQA AVD; QuietJoyQA untouched. Original downloaded archive and owned QA data/snapshot backups preserved under F:/Downloads.

Final 0.5.0 APK: 237,555,523 bytes, SHA256 70981c1509a8bd00dbbb08e82d6c8e1eba5f7948012c0759a9790d211e0f77b8. ZIP CRC passed; zero empty imported resources; imported font binary headers valid; signature verified. Installed on cold-boot AshenMaidenQA API33 with host GLES. Both default and high quality viewed on Android (android-0.5-hero.png / android-0.5-high.png); high_quality=true confirmed in saved JSON. Final PID log has no SCRIPT ERROR, Parse Error, FATAL EXCEPTION, corrupt resource or Failed loading entries. Owned emulator stopped, user emulator untouched. Previously reported 60MB APK was invalid and has been replaced; it is not a package-size optimization result.


## 0.5.1 — forest composition
33 world assertions and 27 isolated UI assertions passed after terrain/forest changes. Real desktop OpenGL camp/hero/battle renders inspected. Nearby scan rocks are preserved in detailed .res meshes with averaged normals, foreground pines remain 3D, 48 distant cards use native transparent renders, 220 grass instances are batched. Ordinary oversampling 1.6 and foliage alpha-to-coverage verified in real rendering. Core/audio unchanged; no new runs claimed.
An intermediate export was rejected by the empty-resource guard when the owned AVD RAM file exhausted C:. Owned AshenMaidenQA moved to F:/Downloads/AshenOathQA-avd and its own registration updated; other AVDs untouched. build.ps1 additionally requires 1 GB of free export space. Rebuilt APK CRC and imported-resource non-empty checks passed and signature verified. Physical-phone FPS/thermals remain unmeasured.

Final APK 0.5.1/code 8: 238,891,440 bytes, SHA256 095a87a0fd7d0c1483aa49284f2d7a17beaf6c8783b1aa99d6f43542af13ae9b. Installed and inspected on owned cold-boot Android API33 AVD. Default forest composition: android-0.5.1-final.png. High quality enabled and applied through real settings UI; saved JSON confirms high_quality=true; android-0.5.1-high.png inspected. Final PID log contains no SCRIPT ERROR, Parse Error, FATAL EXCEPTION, corrupt resource or Failed loading entries; cold shader-cache recompilation warning is present. Owned emulator stopped. Source package lint: 345 files, zero failures/warnings.


## 0.6.0 cartoon verification
World lifecycle: 33 passed, 0 failed (`artifacts/cartoon-world-tests.log`). Actual UI controls: 27 passed, 0 failed (`artifacts/cartoon-ui-tests.log`). Native GPU renders of camp, hero, battle and high preset saved to artifacts/world_*.png. Android debug APK exported as version 0.6.0/code 9, signature verified, ZIP CRC clean, no empty imported resources. Size: 92,118,851 bytes. Hardware-phone FPS has not been measured. Android emulator cold-boot verification is recorded separately below when available.

Android QA: version 0.6.0 installed successfully on isolated AshenMaidenQA (Android 13 / emulator-5556). Launcher returned Status: ok. The camp rendered its cartoon geometry; captured Android evidence is in artifacts/android-cartoon*.png. PID 3228 logcat had no SCRIPT ERROR, Parse Error, FATAL EXCEPTION, corrupt or Failed loading messages. Emulator timing is not a hardware-phone FPS measurement.


## 0.7.0 pixel presentation
13/13 actual pixel-world lifecycle tests passed (tests/pixel_world_tests.gd), including cancellation, stale coroutine suppression, background pausing, reduced motion, committed turn replay and hidden scene suspension. Actual form/signal UI tests: 27/27 passed. Native GPU hero and battle renders saved to artifacts/pixel_*.png. APK version 0.7.0/code 10, size 59,139,209 bytes; ZIP CRC clean and no empty imported assets. Signature checked with Android apksigner. Physical-device FPS has not been measured.

Final Android QA: 0.7.0 installed and launched successfully on AshenMaidenQA / Android 13 (emulator-5556). The native app renders the pixel environment and animated actor. Launcher Status: ok; PID 3123 logcat had no SCRIPT ERROR, Parse Error, FATAL EXCEPTION, corrupt or Failed loading entries. Evidence: artifacts/android-pixel-hero.png. Final APK size: 59139209 bytes.


## RuStore release 0.7.1
See docs/rustore/verification.md and artifacts/rustore/release-manifest.json for final release checks. Signature and package reports are in artifacts/rustore. Release key is outside the workspace and source ZIP.
