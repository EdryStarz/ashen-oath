# Локальная сборка

Проект использует Godot **4.7.2-stable**, GDScript и renderer Compatibility. Официальный релиз 4.x выбран по GitHub API 8 октября 2026. Все локальные инструменты находятся в игнорируемом каталоге `.tools`.

## Запуск и экспорт

На Windows нужны Python 3.10+, JDK 17, Android SDK с platform-tools и build-tools. Пути можно передать `-AndroidSdk` и `-JavaSdk`.

```powershell
powershell -ExecutionPolicy Bypass -File tools/setup.ps1 -Download
powershell -ExecutionPolicy Bypass -File tools/run.ps1
powershell -ExecutionPolicy Bypass -File tools/build.ps1
powershell -ExecutionPolicy Bypass -File tools/install_android.ps1 -Serial emulator-5554
```

`tools/download_godot.py` загружает официальный Windows editor и export templates, проверяет SHA-512 по файлу релиза и извлекает Android и Windows templates. Архив templates весит около 1.28 GB. `_sc_` рядом с Godot изолирует настройки редактора и templates в `.tools/godot/editor_data`.

APK `artifacts/ashen-oath-debug.apk` содержит arm64-v8a для современных телефонов и x86_64 для эмулятора. Это debug-сборка с локальным ключом, не релиз Google Play. Для публикации понадобится собственный release key и AAB; публикация не выполнялась.

Windows export:

```powershell
powershell -ExecutionPolicy Bypass -File tools/build.ps1 -Platform 'Windows Desktop'
```

## Universal Modder

Использован установленный плагин [universal-modder](https://github.com/rehan-remade/universal-modder) 0.2.0: read-only поиск в knowledge base, подход «вертикальный срез → запущенная игра → screenshot/log», локальная проверка пакета перед передачей. Исходный проект принадлежит пользователю, поэтому загрузчик модов и извлечение чужих игровых ресурсов не нужны.

CLI установлен только в `.tools/um-env`; `tools/setup.ps1 -InstallModder` позволяет повторить установку из публичного репозитория. Запуск: `.tools/um-env/Scripts/python.exe -m um --help`. Поиск `um kb search Godot` и `um kb search habit` не нашёл готовых заметок в локальной базе версии 0.2.0. Платная генерация fal и публичная отправка заметок не использовались.

`python tools/check_package.py` копирует только распространяемые исходники и assets в новый staging-каталог под `.tools`, запускает настоящий `um publish check` и сохраняет результат в `artifacts/modder-package-check.log`. APK, SDK, Python environment, Godot editor и keystore туда не попадают.

С флагом `--archive` после чистого результата создаётся `artifacts/ashen-oath-source.zip`. В архиве есть исходники, тесты, инструменты сборки, документация, font licenses и `THIRD_PARTY_NOTICES.md`; локальные профили и evidence не включаются.

Для захвата окна через `um win shot` предусмотрен `python tools/download_capture.py`: отдельный FFmpeg с gfxcapture, проверенный по SHA-256 release asset из BtbN/FFmpeg-Builds. Путь `.tools/ffmpeg/ffmpeg.exe` передаётся в `UM_FFMPEG_WIN`. Захват не требует передачи клавиатуры/мыши приложению.

## Шрифты и источники

- Noto Sans Variable: [google/fonts/ofl/notosans](https://github.com/google/fonts/tree/main/ofl/notosans), лицензия `assets/fonts/NotoSans-OFL.txt`.
- Cormorant Variable: [google/fonts/ofl/cormorant](https://github.com/google/fonts/tree/main/ofl/cormorant), лицензия `assets/fonts/Cormorant-OFL.txt`.
- [Godot 4.7.2 release](https://github.com/godotengine/godot-builds/releases/tag/4.7.2-stable).
- [Официальное руководство Android export](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html).

Фактические результаты сборки и проверки записываются в `MODLOG.md`.

Для старого Android Emulator32.1.12 во время этой проверки понадобились параметры `-gpu host -feature GLESDynamicVersion`: без них он объявлял только GLES2. Приложению нужен GLES3. Использовались `-read-only -no-snapshot -no-window -no-audio`, чтобы не сохранять тестовые изменения в AVD. SDK и его ini не редактировались. Подробные результаты Android и SHA-256 окончательного APK находятся в `docs/VERIFICATION.md`.


