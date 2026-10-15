extends SceneTree
## Website-only localization preview. Does not change the shipped APK or user data.
var app: Node
var untranslated: Dictionary = {}
var expressions: Array = []
const WORDS := {
 "ГЛАВА I · ГЛУХАЯ МЕЖА":"CHAPTER I · THE SILENT BORDER", "ХРАНИТЕЛЬНИЦА МЕЖИ":"KEEPER OF THE BORDERLANDS",
 "ПЕПЕЛЬНЫЙ ОБЕТ":"ASHEN OATH", "Настройки":"Settings",
 "Дела укрепляют обет":"Small steps strengthen your oath",
 "Небольшой шаг в жизни — подготовка к следующей охоте.":"A small step in life prepares you for the next hunt.",
 "Начни с одного реального дела. Герой уже ждёт в лагере.":"Start with one small action. Your hero is waiting at camp.",
 "Пример плана готов. Измени его под свою жизнь.":"Your starter plan is ready. Make it your own.",
 "Офлайн • только твои действия дают опыт":"Offline • real actions earn your XP",
 "Исход сохранён. Идёт бой…":"Outcome saved. The battle is playing…",
 "Победа сохранена. Путь дальше открыт.":"Victory saved. A new path is open.",
 "Прогресс сохранён на случай прерывания.":"Your progress is saved if you leave.",
 "Каждый удар показан из сохранённого расчёта. Можно перейти к результату или вернуться к своим делам.":"Every hit replays the saved outcome. Skip to the result or return to your day.",
 "Идёт охота":"Hunt in progress", "Перейти к результату":"Skip to the result",
 "Выбери подготовку и тактику":"Choose your preparation and tactic",
 "Хранительница межи":"KEEPER OF THE BORDERLANDS", "Сторожевая межа":"The Borderlands",
 "Глава I · Глухая межа":"CHAPTER I · THE SILENT BORDER",
 "Пройтись 10 минут":"Walk for 10 minutes", "Прочитать 5 страниц":"Read 5 pages", "Навести порядок":"Tidy one small space",
 "Выйти на 2 минуты":"Step outside for 2 minutes", "Прочитать абзац":"Read one paragraph", "Убрать одну вещь":"Put one thing away",
 "Каждый день":"Every day", "Отменить отметку":"Undo completion", "Выполнено":"Completed",
 "Откроется с выполненными делами и контрактами.":"Unlock through real actions and contracts.",
 "Проведи по герою, чтобы рассмотреть снаряжение. Осмотри лицо, керамический протез и фактуру экипировки.":"Swipe the hero to inspect her equipment.",
 "На 3-м уровне откроется Резонанс — усиление каждого третьего удара.":"At level 3, unlock Resonance: extra damage on every third hit.",
 "Бывшая настройщица погребальных колоколов. Керамическая рука слышит отголоски чудовищ.":"A former tuner of funeral bells. Her ceramic arm hears the echoes of creatures.",
 "Пепельный крюк":"Ash Hook", "Дорожный клинок":"Worn Blade", "Мантия обета":"Oath Mantle", "Жаровой фонарь":"Ember Lantern",
 "Приёмы обета":"Oath abilities", "Снаряжение":"Equipment", "Надето":"Equipped", "Надеть":"Equip",
 "Снаряжение изменено и сохранено.":"Equipment changed and saved.",
 "Пустотник":"The Husk", "Звонарь топи":"The Bellkeeper", "Корень-пожиратель":"The Root Heart",
 "+ Привычка":"+ Habit", "День отдыха":"Rest day", "К контрактам":"View contracts",
 "Уровень":"Level", "опыта":"XP", "выполнено действий:":"actions completed:",
 "УРОВЕНЬ":"LEVEL", "АТАКА":"ATTACK", "ЗАЩИТА":"DEFENSE", "Здоровье":"Health",
 "Атака":"Attack", "защита":"defense", "здоровье":"health", "Подготовка:":"Preparation:",
 "Сила":"Strength", "сила":"strength", "Знание":"Knowledge", "знание":"knowledge", "Ремесло":"Craft", "ремесло":"craft",
 "Лагерь":"Camp", "Привычки":"Habits", "Герой":"Hero", "Охота":"Hunt", "Журнал":"Journal",
 "ИАРА":"IARA", "Иара":"Iara", "ХОД":"TURN", "ВРАГ":"ENEMY"
}
func _initialize() -> void: call_deferred("run")
func run() -> void:
 if not "--store-capture" in OS.get_cmdline_user_args():
  push_error("Use -- --store-capture to protect user data")
  quit(2)
  return
 root.size = Vector2i(1080,1920)
 for phrase in WORDS: expressions.append(phrase)
 expressions.sort_custom(func(a,b): return a.length() > b.length())
 app = load("res://main.tscn").instantiate()
 root.add_child(app)
 process_frame.connect(localize)
 await create_timer(2.0).timeout
 app._starter_plan()
 for habit in app.game.habits_today(): app.game.complete_habit(str(habit.id))
 if "ash_hook" in app.game.data.inventory: app.game.equip("ash_hook")
 app._render_page()
 await capture("screen-habits-en")
 app._navigate("hero")
 await create_timer(.5).timeout
 await capture("screen-hero-en")
 app._navigate("hunt")
 app._start_hunt()
 await create_timer(4.0).timeout
 await capture("screen-battle-en")
 var file := FileAccess.open("res://artifacts/english-preview-untranslated.json",FileAccess.WRITE)
 file.store_string(JSON.stringify(untranslated, "  "))
 print("ENGLISH_PREVIEW_DONE untranslated=",untranslated.size())
 quit()
func localize() -> void:
 if is_instance_valid(app): translate_node(app)
func translate_node(node: Node) -> void:
 if node is Label or node is Button or node is RichTextLabel:
  var original := str(node.get("text"))
  var translated := original
  for phrase in expressions: translated = translated.replace(phrase,WORDS[phrase])
  if translated != original: node.set("text",translated)
 for child in node.get_children(): translate_node(child)
func collect_remaining(node: Node) -> void:
 if node is Label or node is Button or node is RichTextLabel:
  var value := str(node.get("text"))
  for character in value:
   if character.unicode_at(0) >= 0x400 and character.unicode_at(0) <= 0x4ff:
    untranslated[value] = true
    break
 for child in node.get_children(): collect_remaining(child)
func capture(name: String) -> void:
 await process_frame
 localize()
 await process_frame
 localize()
 await RenderingServer.frame_post_draw
 collect_remaining(app)
 var error := root.get_texture().get_image().save_png("res://docs/site-assets/"+name+".png")
 print("ENGLISH_CAPTURE ",name," error=",error)
