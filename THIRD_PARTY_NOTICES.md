# Источники и лицензии

Проверено8октября2026. Извлечённых материалов чужих игр нет. Генеративные облачные сервисы для ассетов не вызывались.

| Материал/компонент | Происхождение | Условия | Использование |
|---|---|---|---|
| Анатомия героя и часть Пустотника | MakeHuman hm08, адаптированное тело | CC0-1.0; программа MakeHuman не включена | OBJ |
| Растительность | Poly Haven: pine_sapling_small, fern_02, grass_medium_01 | CC0-1.0 | glTF |
| Одежда, экипировка, лагерь и формы монстров |Авторский код проекта |Исходники передаются пользователю |Runtime meshes |
| PBR color/normal/roughness | Poly Haven: forest_ground_04, rock_boulder_dry, brown_leather, denim_fabric, bark_brown_02, rusty_metal_02 | CC0-1.0 | 1k карты |
| Дополнительные материалы | Процедурный FastNoiseLite, настройки проекта | Код Godot и собственные настройки | Runtime PBR |
| Анимации |Собственные Tween/pivot-движения |Никакого motion capture из чужой игры |Idle, атака, отдача, исход |
| Пламя |Собственный `assets/shaders/ember.gdshader` |Исходный код проекта |Визуальный эффект |
| Иконка |Собственный `assets/icon.svg` |Исходный код проекта |Знак резонатора |
| Звуки лагеря и боя |Собственный синтез в `tools/generate_audio.py` |Исходный код проекта, без внешних семплов |7 WAV, PCM16 mono 22050 Hz |
| Музыкальная партитура и озвучка |Отсутствуют |Не применимо |В прототипе нет |
| Noto Sans |[Google Fonts](https://github.com/google/fonts/tree/main/ofl/notosans) |SIL OFL, текст `assets/fonts/NotoSans-OFL.txt` |Локальный интерфейс, кириллица/латиница |
| Cormorant |[Google Fonts](https://github.com/google/fonts/tree/main/ofl/cormorant) |SIL OFL, текст `assets/fonts/Cormorant-OFL.txt` |Заголовки |
| Godot4.7.2 |[Релиз](https://github.com/godotengine/godot-builds/releases/tag/4.7.2-stable) |[MIT и сторонние компоненты](https://godotengine.org/license/) |Движок приложения |
| Universal Modder0.2.0 |[Репозиторий](https://github.com/rehan-remade/universal-modder) |Лицензия репозитория; инструмент разработки, не встроен в APK |KB, запуск, screenshot, lint |
| UI UX Pro Max |[Репозиторий](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill) |MIT; рекомендации, база не встроена в APK |UI/UX |

Перед покупкой или добавлением моделей: записать автора, точный URL, версию, дату загрузки, лицензию и ограничения на распространение. Не считать «бесплатно скачать» лицензией на коммерческое использование. Риг, текстуры, анимация, музыка и голос требуют отдельного происхождения.

## Godot Engine — MIT

Copyright (c) 2014-present Godot Engine contributors (see AUTHORS.md).
Copyright (c) 2007-2014 Juan Linietsky, Ariel Manzur.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

Полный список зависимостей движка и их уведомлений: [Godot COPYRIGHT.txt](https://github.com/godotengine/godot/blob/4.7.2-stable/COPYRIGHT.txt). В приложении есть пункт «Лицензии и версия» со ссылкой на страницу лицензии движка. Для релиза сохранить актуальные уведомления используемого бинарного шаблона.

Точные источники, хеши и pinned commit: `assets/provenance/realistic-assets.json`. [Poly Haven CC0](https://polyhaven.com/license). [MakeHuman: лицензия экспортированных ассетов](https://static.makehumancommunity.org/makehuman/faq/are_makehuman_files_free.html). Лицензия исходного анатомического ассета сохранена в `assets/provenance/MakeHuman-CC0.txt`.

## Герой 0.4.0 — Sintel derivative, CC BY 3.0

Sintel: модель Angela Guenette, Blender Foundation / Durian team (2010). Исходник: [официальный архив](https://download.blender.org/durian/sprint/sintel_model.blend.zip). Разрешение и исключения логотипов: [Copyright and Sharing](https://durian.blender.org/sharing/). Лицензия: [CC BY 3.0 Unported](https://creativecommons.org/licenses/by/3.0/). Изменены одежда, волосы, керамическая рука и PBR-материалы; добавлены новый скелет из 19 костей, skin weights и три клипа. Это производная работа, не полностью авторская модель и не официальный продукт Blender. Атрибуция также включена в экран лицензий приложения. Исходная MakeHuman-анатомия осталась у Пустотника.


## Maiden Assassin — private licensed character

Author: RetroStyleGames. Source: https://www.cgtrader.com/free-3d-models/character/woman/unity-female-warrior-assassin
License: CGTrader Royalty Free (no AI), https://www.cgtrader.com/pages/terms-and-conditions
The user supplied RFA_v5.6.unitypackage. Only meshes, texture images and animation are converted; bundled Unity scripts and plugins are not executed or shipped. The licensed raw/derived model and textures in assets/models/private_maiden are excluded from source archives and Git. The source project falls back to CC BY Sintel; owners may regenerate their private asset with tools/import_maiden.py. Model use in the game does not grant permission to redistribute its standalone source assets. See assets/provenance/maiden-assassin.json for hashes.


## A Verdant Trail — Poly Haven, CC0
Source: https://blog.polyhaven.com/verdant-trail/
License: https://polyhaven.com/license
Derived mobile topology, simplified PBR materials, resized textures and flattened staging area. Hashes: assets/provenance/verdant-trail.json and verdant-mobile.json.

0.5.1: pine_impostor.png is a native Godot rendering of the CC0 Poly Haven pine_sapling_small mesh. near_boulder resources derive from the CC0 Verdant Trail scene with averaged normals. See assets/provenance/forest-composition.json.


## 0.6.0 — cartoon revision
The active world uses original procedural trees, bushes, terrain and camp geometry with flat colors and banded diffuse lighting. Sintel (Angela Guenette / Blender Foundation, CC BY 3.0) retains its original attribution and custom 19-bone rig with idle, strike and hit clips. No generated bitmap assets were added. World-space procedural trail has no texture, alpha or sprite pivot. Normal/high presets use 30/42 trees; economy hides the 3D viewport. The private Maiden, Verdant Trail and photographic foliage are not used or included in the Android APK. Legacy open asset files remain in the source archive with their existing credits.


## 0.7.0 — pixel arcade direction
Original imagegen-generated forest camp and original Iara/creature art, inspired by the pixel-art arcade visual language of the supplied Scott Pilgrim references. No reference-game sprites, characters, logos or screenshots ship in the app. Environment PNG: 384x256, 48 colors. Actor PNG: 576x256, 4 columns by 2 rows, 144x128 cells; top row idle/attack/hurt/victory, bottom row husk/bellkeeper/root heart/fire. Characters face right; enemies are flipped at draw time. Pivot: bottom-center, fixed source baseline. Nearest filtering and a fixed 384-pixel viewport preserve the pixel grid. Master images preserved separately, excluded from APK. tools/prepare_pixel_assets.ps1 aligns the variable raw regions on equal canvases, then UM sprite pixelate converts the atlas. Combat consumes committed battle logs without changing progression. Background layers are baked into the environment image; no depth camera or 3D model is used.


## 0.7.2 — store artwork
Original imagegen Iara and amber lantern icon: opaque square, 256x256/96-color grid, nearest scale to 512x512. Four real app captures per device with original marketing frames, phone 1080x1920 and portrait tablet 1200x1920. Masters are excluded from the APK. Reproduction tools: render_store_icon.gd, capture_store_app.gd, render_store_frames.gd, render_store_preview.gd.
