"""Generate the Russian landing from the English source; no build dependencies."""
from pathlib import Path

root = Path(__file__).resolve().parents[1] / 'docs'
text = (root / 'index.html').read_text(encoding='utf-8')
translations = {
'Ashen Oath — Your to-do list has a boss fight.':'Пепельный обет — у списка дел теперь есть босс.',
'Turn real-world habits into pixel-world victories. A free offline habit RPG for Android. No ads or purchases. Game interface in Russian.':'Превращай реальные привычки в победы пиксельного героя. Бесплатная офлайн RPG для Android без рекламы и покупок.',
'Small real-world steps. Pixel-world victories. A free offline Android RPG.':'Маленькие реальные шаги. Победы пиксельного героя. Бесплатная офлайн RPG для Android.',
'Link copied. Send it to your party.':'Ссылка скопирована. Отправь её своей команде.',
'Copy this address to share:':'Скопируй адрес и поделись приключением:',
'Skip to content':'Перейти к содержимому','Main navigation':'Основная навигация',
'ASHEN OATH':'ПЕПЕЛЬНЫЙ ОБЕТ','How it works':'Как это работает','Screenshots':'Скриншоты','FAQ':'Вопросы',
'A LITTLE RPG FOR YOUR REAL LIFE':'МАЛЕНЬКАЯ RPG ДЛЯ ТВОЕЙ РЕАЛЬНОЙ ЖИЗНИ',
'Your to-do list<br>has a <span>boss fight.</span>':'У списка дел<br>теперь есть <span>босс.</span>',
'Take a walk. Read a few pages. Come back stronger. Your everyday actions power Iara’s next adventure.':'Прогуляйся. Прочитай пару страниц. Вернись сильнее. Твои обычные дела готовят Иару к следующему приключению.',
'Download for Android':'Скачать для Android','Try a tiny quest':'Попробовать мини-квест',
'Free to play':'Бесплатно','Fully offline':'Полностью офлайн','No ads or purchases':'Без рекламы и покупок',
'Android 7.0+ · ARM64 / x86_64 · Game interface: Russian':'Android 7.0+ · ARM64 / x86_64 · Игра на русском',
'Iara faces a forest creature in the pixel camp':'Иара и лесное существо в пиксельном лагере',
'CHAPTER 01 / THE BORDERLANDS':'ГЛАВА 01 / СТОРОЖЕВАЯ МЕЖА','YOUR NEXT SIDE QUEST':'ТВОЙ СЛЕДУЮЩИЙ КВЕСТ',
'One real-world action':'Одно реальное действие','Progress you can see.':'Прогресс, который видно.',
'Paths to grow':'Пути развития','Creatures to face':'Существа в лесу','Accounts needed':'Аккаунтов нужно','Ads to interrupt':'Рекламных пауз',
'ORDINARY DAYS. EXTRAORDINARY LOOT.':'ОБЫЧНЫЕ ДНИ. НЕОБЫЧНЫЕ НАГРАДЫ.',
'A small step for you.<br>A level-up for her.':'Маленький шаг для тебя.<br>Новый уровень для неё.',
'Your minimum counts. Plan a tiny action, mark it done, and take that preparation into the forest. Leave room for rest days, too.':'Твой минимум считается. Запланируй небольшое дело, отметь выполнение и возьми подготовку с собой в лес. Дням отдыха тоже есть место.',
'Tap a quest to try the idea. This is a browser preview, not your game save.':'Нажми на дело и попробуй идею. Это пример в браузере, а не сохранение игры.',
'TODAY’S SIDE QUESTS':'КВЕСТЫ НА СЕГОДНЯ','DAY 01':'ДЕНЬ 01',
'Walk for 10 minutes':'Прогуляться 10 минут','Read 5 pages':'Прочитать 5 страниц','Tidy one small space':'Навести небольшой порядок',
'Strength':'Сила','Knowledge':'Знание','Craft':'Ремесло','PREPARATION':'ПОДГОТОВКА','Preparation':'Подготовка',
'Interactive preview only. No data is stored or sent.':'Только интерактивный пример. Данные не сохраняются и не отправляются.',
'Make it small':'Начни с малого','Make it yours':'Составь свой план','Make it an adventure':'Добавь приключение',
'Choose an action you can do even on a difficult day.':'Выбери дело, которое получится сделать даже в сложный день.',
'Set your schedule. Mark your own progress. Take a rest when you need one.':'Настрой расписание. Отмечай свой прогресс. Планируй отдых.',
'Earn XP, equip your hero, pick a tactic and face the forest.':'Получай опыт, меняй снаряжение, выбирай тактику и встречай существ леса.',
'ACTUAL SCREENS. ACTUAL LITTLE VICTORIES.':'НАСТОЯЩИЕ ЭКРАНЫ. МАЛЕНЬКИЕ ПОБЕДЫ.',
'Meet your other life.':'Знакомься со своей другой жизнью.',
'Screens from the Android app. The game currently speaks Russian.':'Кадры Android-приложения. Текущий интерфейс игры — на русском.',
'YOUR DAILY QUESTS':'ЕЖЕДНЕВНЫЕ КВЕСТЫ','YOUR HERO':'ТВОЯ ГЕРОИНЯ','YOUR NEXT CHALLENGE':'СЛЕДУЮЩИЙ ВЫЗОВ',
'Build your rhythm':'Найди свой ритм','See yourself grow':'Наблюдай за ростом','Prepare. Then strike.':'Подготовься. И в бой.',
'Daily quests':'Ежедневные квесты','Your hero':'Твоя героиня','Battle':'Бой',
'Habit planner in the Android game':'Планировщик привычек в Android-игре','Iara and her equipment in the Android game':'Иара и её снаряжение в Android-игре','A forest battle in the Android game':'Бой с лесным существом в Android-игре',
'Your habits belong to you.':'Твои привычки принадлежат тебе.',
'No account. No ad trackers. Your progress stays on your device, with JSON export when you want a backup.':'Без аккаунта и рекламных трекеров. Прогресс остаётся на устройстве. Сохрани JSON, когда захочешь сделать резервную копию.',
'Read the privacy policy':'Политика конфиденциальности',
'BEFORE YOU ENTER THE FOREST':'ПРЕЖДЕ ЧЕМ ВОЙТИ В ЛЕС','A few things<br>worth knowing.':'Что стоит знать<br>перед первым квестом.',
'Is it really free?':'Это действительно бесплатно?','Yes. This build has no ads, subscriptions or in-app purchases.':'Да. В этой версии нет рекламы, подписок и встроенных покупок.',
'Can I play in English?':'На каком языке игра?',
'This website is bilingual. The current Android game interface is Russian. An English game translation is not included in version 0.7.2.':'Сайт доступен на русском и английском. Текущий интерфейс Android-игры — на русском. Английского перевода самой игры в версии 0.7.2 пока нет.',
'Is this a big, endless RPG?':'Это большая бесконечная RPG?',
'It is a small first chapter: three creatures, progression, equipment and a habit planner. No multiplayer, cloud sync or reminders yet.':'Это небольшая первая глава: три существа, развитие героя, снаряжение и планировщик привычек. Мультиплеера, облачной синхронизации и напоминаний пока нет.',
'What happens to my progress?':'Где хранится мой прогресс?',
'It is saved locally. Export your JSON from the Journal before uninstalling or changing from an old debug build to a release build. Deleting the app without a backup removes local progress.':'На устройстве. Перед удалением приложения или переходом со старой debug-сборки на release экспортируй JSON через «Журнал». Без резервной копии удаление приложения приведёт к потере локального прогресса.',
'How do I install it?':'Как установить игру?',
'Download the APK from our GitHub release, open it on a compatible Android device and allow installation from that source when Android asks. You need Android 7.0+ and a 64-bit ARM or x86 device.':'Скачай APK из нашего релиза GitHub, открой его на совместимом Android-устройстве и разреши установку из этого источника, если Android попросит. Нужны Android 7.0+ и 64-битное ARM- или x86-устройство.',
'YOUR NEXT CHAPTER STARTS SMALL':'ТВОЯ НОВАЯ ГЛАВА НАЧИНАЕТСЯ С МАЛОГО',
'One small quest.<br>See where it takes you.':'Один маленький квест.<br>А дальше — посмотрим.',
'Start with ten minutes. Invite a friend to start with you.':'Начни с десяти минут. Позови друга начать вместе.',
'Share the adventure':'Поделиться приключением','An independent little adventure.':'Независимая игра и маленькое приключение.',
'Star on GitHub':'Поддержать звездой на GitHub','Source code':'Исходный код','Privacy':'Конфиденциальность','Support':'Поддержка','Close screenshot':'Закрыть скриншот'
}
for source,target in sorted(translations.items(), key=lambda x:-len(x[0])):
    text=text.replace(source,target)
text=text.replace('<html lang="en">','<html lang="ru">')
text=text.replace('href="ru/" lang="ru">Русский','href="../" lang="en">English')
for resource in ['site-assets/','site.css','site.js','rustore/']:
    text=text.replace('href="'+resource,'href="../'+resource).replace('src="'+resource,'src="../'+resource).replace('data-image="'+resource,'data-image="../'+resource)
text=text.replace('rel="canonical" href="https://edrystarz.github.io/ashen-oath/"','rel="canonical" href="https://edrystarz.github.io/ashen-oath/ru/"')
text=text.replace('property="og:url" content="https://edrystarz.github.io/ashen-oath/"','property="og:url" content="https://edrystarz.github.io/ashen-oath/ru/"')
(root/'ru').mkdir(exist_ok=True)
(root/'ru/index.html').write_text(text,encoding='utf-8')
(root/'robots.txt').write_text('User-agent: *\nAllow: /\nSitemap: https://edrystarz.github.io/ashen-oath/sitemap.xml\n',encoding='utf-8')
(root/'sitemap.xml').write_text('<?xml version="1.0" encoding="UTF-8"?><urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"><url><loc>https://edrystarz.github.io/ashen-oath/</loc></url><url><loc>https://edrystarz.github.io/ashen-oath/ru/</loc></url></urlset>',encoding='utf-8')
print('Built Russian landing, sitemap and robots.txt')
