# Website / Витрина

Published from main:/docs via GitHub Pages, with .nojekyll.
English: https://edrystarz.github.io/ashen-oath/
Russian: https://edrystarz.github.io/ashen-oath/ru/
Public app privacy policy: https://edrystarz.github.io/ashen-oath/rustore/privacy-policy.html

English source: index.html. Russian translation generator: tools/build_landing.py. Run after editing English copy and verify the translation map. Shared CSS/JS: site.css and site.js. All fonts and art are self-hosted; no third-party analytics or app-save collection. Mini-quests are explicitly marked as an unsaved browser preview. Current Android game language is Russian.

Social image: site-assets/social-card.png (1200x630), generated with tools/render_social_card.gd. Original app sprites and screens used; no fake users, reviews, downloads, metrics or promised outcomes.

Browser verification: English and Russian at 375, 390, 768, 1024, 1440px; no horizontal overflow. XP toggles 0→60→40; screenshot dialog opens and Escape closes it; share fallback shows confirmation; reduced-motion CSS disables animation. Browser JS errors: zero. No claim of guaranteed virality is made.

To update the Android download, change the pinned release asset links in index.html and README.md, regenerate Russian, and verify both languages. The game APK and signing key are unaffected by website changes.


## Screenshot localization
The English gallery uses screen-*-en.png, captured by tools/capture_english_preview.gd with a website-only English UI text catalog. These are explicitly labeled localization previews: the downloadable 0.7.2 APK remains Russian. Russian pages retain the original Russian screen-*.png files. The capture tool uses a unique --store-capture save and does not alter shipped game code or user saves. Rebuild both languages after editing gallery markup.
