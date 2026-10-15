# Проверки релиза 0.7.1

Подписанная release APK установлена и запущена на Android 13 в изолированном AshenMaidenQA (emulator-5556), launcher Status: ok. Процесс 5531: нет SCRIPT ERROR, Parse Error, FATAL EXCEPTION, corrupt или Failed loading в журнале первого запуска.

Подпись RSA 3072, APK v2/v3, сертификат CN=Embertrail Studio. CRC архива APK корректна; импортированные ресурсы не пустые. Политика privacy_ru.txt входит в APK. android:debuggable не установлен; android:isGame=true, категория game; INTERNET и другие разрешения отсутствуют; allowBackup=false. ARM64 / x86_64 библиотеки имеют ELF LOAD alignment 16384 и прошли zipalign -P 16.

Тесты: игровая логика 111/111; интерфейс 27/27; пиксельная сцена 13/13; звук 12/12. Аудиотест в headless-режиме выводит предупреждение о двух ресурсах при завершении; тестовые утверждения прошли, аварии Android не обнаружены.

Четыре скриншота сняты с актуального нативного приложения, 540x960 (9:16), без системных панелей; каждый меньше 3 МБ. Иконка 512x512, непрозрачный фон. Данные демонстрационного сохранения изолированы от пользовательского прогресса.

Тестирование FPS на физических телефонах не проводилось. Верификация аккаунта, доступность публичной ссылки на политику, анкеты RuStore и решение модерации остаются внешними этапами.


## 0.7.2 — icon and store artwork
New original Iara/lantern portrait icon, imagegen source converted to a 256-pixel/96-color grid and nearest scaled to 512. Full opaque background. Actual app captures: phone 1080x1920 and tablet 1280x2048, using tools/capture_store_app.gd on fresh isolated saves. Four finished phone frames 1080x1920 and four tablet frames 1200x1920. CRC, dimensions and store size limits validated. The release was re-exported and signed with the same key; signature, alignment, APK CRC and resource lengths verified. Android runtime verification belongs to 0.7.1; no gameplay logic changed in this asset update.
