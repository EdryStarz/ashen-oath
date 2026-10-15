# Визуальный вертикальный срез

## Что действительно создано

`scripts/world.gd` строит настоящую интерактивную 3D-сцену в Godot: геометрия, камера, освещение, материалы и процедурное движение выполняются движком. Это не концепт-арт, не видео и не плоское изображение персонажа. На экране героя доступен поворот. На экране охоты проигрываются движения по уже вычисленному журналу боя; художественная сцена не принимает решения о победе и не начисляет награды.

Версия 0.3.0 использует адаптированную CC0-анатомию MakeHuman, шесть PBR-наборов и три вида растительности Poly Haven; одежда, экипировка, руины и существа дополнены авторской геометрией. Плавная геометрия, композиция и контраст света задают направление, но качество анатомии, ткани, волос и анимации **не соответствует** финальному коммерческому персонажу или The Witcher 3. Мобильная производительность до измерения на целевом устройстве также не подтверждена.

## Самостоятельный образ

Иара — бывшая смотрительница погребальных маяков. Она потеряла левую руку, пытаясь вынести из затопленного маяка имена погибших. Керамический протез с бронзовыми сочленениями улавливает остаточный резонанс старых клятв. Способности происходят от этой работы с памятью, а не от школы мутантов. Внешние отличия: капюшон над короткими тёмными волосами с одной небольшой косой, гладкая керамическая маска с бронзовым швом, светлая керамическая рука, асимметричные полы угольного пальто и длинная раздвоенная резонансная вилка. Белых волос, волчьего медальона, пары мечей за спиной и узнаваемой символики чужой вселенной нет.

Рабочий референс настроения — The Witcher 3: Wild Hunt, обновление 4.x: холодный рассеянный свет, тёплый очаг, влажный лес, изношенные органические материалы и отчётливый силуэт персонажа. Референс задаёт художественные качества, а не утверждение о равном качестве рендера.

## Изменения, которые видно

| Состояние | Изменение 3D |
|---|---|
| Начало | Потёртая стальная вилка, лёгкое пальто, простая стоянка |
| `ash_hook` | Бронзовый изогнутый крюк, стальное ответвление и светящаяся вставка |
| `oath_mantle` | Дополнительно появляется плащ с бронзовой застёжкой |
| `ember_lantern` | Фонарь с локальным светом на поясе |
| Подготовка | До трёх различимых керамических/бронзовых фляг на поясе |
| Уровень 2 | В лагере появляется стойка для снаряжения |
| Уровень 4 | Собран памятный каменный знак с резонансным огнём |

Три противника различаются объёмом и силуэтом: Пустотник — сутулое тело, костяная маска и раздвоенные отростки; Звонарь топи — патинированный колокол на корневых конечностях; Корень-пожиратель — широкий древесный узел с шестью опорами, короной корней и янтарным сердцем.

## Происхождение материалов

| Ресурс | Источник | Сторонние права |
|---|---|---|
| Анатомическая основа героя | MakeHuman hm08, только `body` без helpers; адаптирована и разделена | CC0, лицензия в assets/provenance/MakeHuman-CC0.txt |
| Сосна, папоротник, трава; грунт, камень, кожа, ткань, кора, металл | Poly Haven, 1k; точные URL и хеши в assets/provenance/realistic-assets.json | CC0 |
| Одежда, маска, протез, экипировка, руины, очаг и формы существ | Авторская геометрия проекта | Исходники передаются пользователю |
| Албедо и микрорельеф поверхностей | `FastNoiseLite` / `NoiseTexture2D` Godot; параметры и цвета в исходниках | Библиотеки распространяются в составе движка; см. лицензии Godot |
| Материалы | `StandardMaterial3D`, metallic/roughness, выбранная палитра | Авторские параметры |
| Пламя | Авторский пространственный shader `assets/shaders/ember.gdshader` | Нет внешнего изображения или видео |
| Дыхание, замах, удар, отдача и падение врага | Процедурное движение узлов и `Tween` | Motion capture и сторонние клипы не используются |
| Атмосфера лагеря и боя, замах, удар, награда, резонанс, победа | Собственный детерминированный синтез `tools/generate_audio.py`, 7 WAV | Нет чужих записей или семплов |
| Музыкальная партитура и озвучка | В этом срезе отсутствуют | Звуковые ассеты не заимствованы |

Применены рекомендации установленного universal-modder `asset-pipeline`: сначала определить формат движка, сохранить воспроизводимость исходников, проверять материалы и ориентацию в реальном рендере. Здесь целевой формат — Godot Mesh/ArrayMesh и ShaderMaterial, а не набор спрайтов. Платные fal-сервисы не вызывались, ассеты из установленных сторонних игр не извлекались. Инструмент не создаёт автоматически финальную анимацию или модель промышленного качества.

## Качество и доступность

В режиме экономии сцена отключается контроллером приложения; в базовом профиле используется MSAA 2×, в повышенном — 4× и увеличенная дальность теней. Недорогой туман по глубине остаётся в обоих 3D-профилях для разделения планов. В уменьшенном движении отключаются покачивание, изменение огня и анимация ударов; результат боя остаётся рассчитанным тем же способом и представляется сразу. Тряски камеры нет. Переход к списку привычек прерывает показ боя без вмешательства в сохранённый результат.

Для следующего художественного этапа нужен один законченный герой с анатомией, ретопологией, UV, тканевыми и кожными PBR-картами, rig и согласованным набором клипов; затем три модели противников. Сначала улучшать этот небольшой набор и освещение, не расширяя мир. Перед заменой каждого временного ассета сохранять источник, лицензию, разрешённые платформы и доказательство покупки/авторства. Оценивать не только количество полигонов, но и draw calls, прозрачность, количество костей, texture memory и время кадра на физическом Android-устройстве.

## Выполненные проверки сцены

Проверено 8 октября 2026 в Godot 4.7.2:

- `--headless --path . --check-only --script scripts/world.gd` — парсер без ошибок.
- `--headless --path . --script tools/verify_world.gd` — 21 проверка, ноль ошибок: отмена и очистка эффектов, единичный сигнал завершения, защита от старого асинхронного цикла, уменьшение движения, экипировка, анимация и приостановка в фоне.
- `--path . --script tools/render_world.gd -- --mode=camp` (также `hero`, `battle`) — реальные OpenGL-кадры на Windows / NVIDIA RTX 3050 Laptop GPU: `artifacts/world_camp.png`, `world_hero.png`, `world_battle.png`. Кадры просмотрены, чрезмерная яркость и масштаб шумовой текстуры скорректированы. Это отдельная проверка сцены с максимальным снаряжением; она не изображает реальное пользовательское сохранение.

Эти проверки не являются измерением FPS, энергопотребления или памяти на телефоне. Снимки всего приложения и отдельные Android-проверки описаны в общем отчёте проекта.

## Карточка хроники

`scripts/chronicle_card.gd` строит вертикальную карточку 432×768 из текущего состояния, переданного контроллером: уровень, надетый предмет, подготовка, число отметок, число завершённых контрактов и дата. Портрет — новый реальный кадр того же `CampWorld` в отдельном 3D SubViewport 432×400. В картинку не передаются названия привычек. Карточка не меняет прогресс и не публикуется автоматически; пользователь сам сохраняет или передаёт её дальше.

Это снимок **текущего героя**, а не вымышленное сравнение «первый день / месяц спустя». Автоматическое видео месячной истории и достоверное сравнение прошлых моделей ещё не реализованы: для них потребуются сохранённые снимки состояния, явное согласие на экспорт и отдельный видеоконвейер.

`tools/render_chronicle.gd` использует обозначенную тестовую фикстуру (уровень 4, 23 отметки, 3 контракта), не читает пользовательское сохранение и записывает `artifacts/chronicle-fixture.png`. Этот файл нельзя представлять как достижения реального пользователя. При headless-рендере метод сразу возвращает `null`, не создавая viewport. После обычного рендера оба временных viewport освобождаются.

## Подготовка CC0-ассетов в 0.3.0

`tools/prepare_realistic_assets.py` скачивает исходные PBR-карты и glTF, сверяет MD5 поставщика, записывает SHA256 и источник. OBJ-тело разделяется на части с сохранением UV, руки приводятся к опущенной позе; пальцы заменены закрытой перчаткой. MakeHuman-программа и её AGPL-код не включены. Процедурная анимация осталась: полноценного skeletal rig и motion capture пока нет. Меши леса общие для экземпляров, карты ограничены 1k, тени растительности отключены. Реальная скорость на телефоне ещё требует замера.

## 0.3.1: резкость и движение одежды

3D-буфер показывается через TextureRect: в базовом профиле 1.25× логического размера, в повышенном 2×, ширина ограничена 1080 пикселями. Масштаб интерфейса и координаты жестов сохраняются. Полы пальто имеют раздельные узлы и слабое движение; плащ реагирует на idle. Уменьшенное движение сбрасывает позу дыхания и ткани, останавливает колебания. Замахи руки уменьшены. Это процедурное движение; полноценный skeletal rig не заявляется. Повышенное разрешение увеличивает GPU-нагрузку.

## 0.4.0: скелетный герой

Вместо составной модели используются меши Sintel с детализированными перчатками, обувью, лицом и застёжками. Исходная архивная версия не содержит rig: `tools/build_skinned_hero.py` создаёт 19 костей, skin weights, три клипа и GLB. Команда: Blender 4.5.9 `--background --disable-autoexec .tools/art-source/sintel/sintel_model.blend --python tools/build_skinned_hero.py`. Для воспроизведения скачать архив по URL в assets/provenance/sintel-derived.json, проверить SHA256 и распаковать в указанную папку. Камера смотрит вдоль -Z; GLB в метрах Y-up, источник Blender Z-up. Оружие через BoneAttachment3D следует за рукой, а AnimationPlayer выключается в невидимой сцене. Расчёт боя не зависит от клипов.

Лицо, кожа и волосы этого бесплатного источника остаются стилизованными. 0.4.0 не достигает качества Witcher 3; это рабочая замена архитектуры персонажа и анимации. Более реалистичный кандидат: Maiden Assassin от RetroStyle Games, 37140 треугольников, 26 PBR-карт 4k, 16 клипов по странице автора. На CGTrader заявлен бесплатный download, но операция через аккаунт требует отдельного согласования по исходному пользовательскому брифу; файл не получен и его пригодность для Godot ещё не подтверждена. На сайте автора доступ через Discord требует участия в сообществе, поэтому этот путь не выполнялся.


## 0.4.1: Maiden Assassin and downloaded environment

The user provided RFA_v5.6.unitypackage. The local hero now uses RetroStyleGames' original 125-bone rig and three retargeted source clips (idle, attack, taking damage). The converter fixes FBX geometry/bind axes and different animation bind poses before GLB export. Head maps use 2048px and other maps 1024px; no claim of Witcher 3 quality or physical-phone performance. The licensed private model is omitted from source archives, which retain the Sintel fallback. No Unity scripts from the package execute.

A Verdant Trail (Poly Haven) downloaded from https://dl.polyhaven.org/file/ph-assets/Scenes/verdant_trail.zip: 1,918,654,862 bytes, vendor SHA1 999c7bcb199a445c057cacdc27cbc7d5d3107976 matched, ZIP CRC passed. Original scene extracted under .tools/art-source/locations/verdant_trail; CC0. This is a coherent environment built from real scanned rocks and vegetation. The full scene is not yet integrated in the mobile game; optimization, mesh budgets and lighting remain necessary. Provenance: assets/provenance/verdant-trail.json.


## Android environment 0.5.0
A Verdant Trail integrated: default low 169,881 triangles; optional high 481,163; selected source 4,782,317. Textures max 1024px, ETC2 Android GPU compression with mipmaps, foliage alpha cutout, shorter shadow and visibility distances. Procedural scatter and render-only source effects omitted. Original 1.9GB archive excluded. Physical-phone FPS and thermals not measured.


## 0.5.1 — forest composition
Open clearing instead of camera inside cliff scans. Textured undulating floor with a dirt trail; grass batched into a MultiMesh. Five nearby 3D pines and 48 distant native-rendered transparent pine cards. Near rocks retain detailed meshes with smoothed normals. Balanced daylight/fire and revised camera framing. Canvas tent gains folds, seams, back wall, ropes and stakes. This is a visual composition revision, not an AAA photorealism or physical-phone FPS claim.


## 0.6.0 — cartoon revision
The active world uses original procedural trees, bushes, terrain and camp geometry with flat colors and banded diffuse lighting. Sintel (Angela Guenette / Blender Foundation, CC BY 3.0) retains its original attribution and custom 19-bone rig with idle, strike and hit clips. No generated bitmap assets were added. World-space procedural trail has no texture, alpha or sprite pivot. Normal/high presets use 30/42 trees; economy hides the 3D viewport. The private Maiden, Verdant Trail and photographic foliage are not used or included in the Android APK. Legacy open asset files remain in the source archive with their existing credits.


## 0.7.0 — pixel arcade direction
Original imagegen-generated forest camp and original Iara/creature art, inspired by the pixel-art arcade visual language of the supplied Scott Pilgrim references. No reference-game sprites, characters, logos or screenshots ship in the app. Environment PNG: 384x256, 48 colors. Actor PNG: 576x256, 4 columns by 2 rows, 144x128 cells; top row idle/attack/hurt/victory, bottom row husk/bellkeeper/root heart/fire. Characters face right; enemies are flipped at draw time. Pivot: bottom-center, fixed source baseline. Nearest filtering and a fixed 384-pixel viewport preserve the pixel grid. Master images preserved separately, excluded from APK. tools/prepare_pixel_assets.ps1 aligns the variable raw regions on equal canvases, then UM sprite pixelate converts the atlas. Combat consumes committed battle logs without changing progression. Background layers are baked into the environment image; no depth camera or 3D model is used.


## 0.7.2 — store artwork
Original imagegen Iara and amber lantern icon: opaque square, 256x256/96-color grid, nearest scale to 512x512. Four real app captures per device with original marketing frames, phone 1080x1920 and portrait tablet 1200x1920. Masters are excluded from the APK. Reproduction tools: render_store_icon.gd, capture_store_app.gd, render_store_frames.gd, render_store_preview.gd.
