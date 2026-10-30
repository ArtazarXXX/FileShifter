# Changelog / История версий

All notable changes to **FileShifter** will be documented in this file.  
Все ключевые изменения в **FileShifter** документируются в этом файле.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [0.0.2] - 2026-10-30

### 🇬🇧 English
#### 🚀 Highlights
* **Dynamic Bilingual Central HUD:** Moving the cursor over any sector now highlights the center hub with the action's accent color, large SF Symbol icon, primary **English action title**, and contextual **Russian translation**.
* **Expanded Center Hub & Improved Deadzone:** Increased center hub radius to `85pt` (diameter `170pt`, +65% circular area) allowing all action descriptions to fit comfortably with generous whitespace.
* **Minimalist Radial Buttons:** Removed cluttered text overlays hanging below sectors. Formats, ratios, and speeds now use crisp typographic badges (e.g. `WebP`, `PNG`, `9:16`, `0.5x`, `A4`), while tools use high-definition SF Symbols.
* **Safe Dismiss Zone:** The center zone explicitly indicates `Dismiss • Отмена` when idle, preventing accidental triggers.

#### 🐛 Bug Fixes
* **SVG Entity Escaping:** Escaped raw `&` ampersands to `&amp;` in `badge-ctrl.svg` and `badge-opt.svg` so GitHub's markdown renderer and Camo CDN display all gesture badges reliably.
* **Radial Hit-Testing Alignment:** Calibrated sector angle calculation and deadzone boundary to perfectly match the enlarged hub geometry.

---

### 🇷🇺 Русский
#### 🚀 Главные улучшения
* **Двуязычный динамический центральный HUD:** При наведении курсора на сектор центральная ступица подсвечивается акцентным цветом действия и отображает крупную иконку SF Symbol, основной **английский заголовок** и поясняющий **русский перевод**.
* **Увеличенная центральная ступица и мертвая зона:** Радиус ступицы увеличен до `85pt` (диаметр `170pt`, +65% площади), благодаря чему даже длинные названия действий отображаются свободно и воздушно без обрезки текста.
* **Лаконичные кнопки секторов:** Убраны громоздкие висящие подписи под иконками. Форматы, соотношения сторон и скорости выводятся стильными шрифтовыми бейджами (`WebP`, `PNG`, `9:16`, `0.5x`, `A4`), а утилиты — четкими нативными SF Symbols.
* **Информативная зона отмены:** В состоянии покоя ступица отображает `Dismiss • Отмена`, защищая от случайных срабатываний.

#### 🐛 Исправления ошибок
* **Экранирование XML сущностей в SVG:** Заменен сырой символ `&` на `&amp;` в файлах `badge-ctrl.svg` и `badge-opt.svg`, что устранило ошибку парсинга и восстановило отображение картинок на GitHub.
* **Калибровка углов наведения:** Точная синхронизация триггерных секторов мыши с новой геометрией центрального круга.

---

## [0.0.1] - 2026-10-29

### 🇬🇧 English
#### 🎉 Initial Public Release
* **Liquid Glass Radial Menu:** Native SwiftUI & AppKit radial interface supporting ProMotion 120 FPS.
* **4 Modifier Gesture Modes:**
  * **⇧ Shift:** Format conversion for Images, Videos, PDFs, Documents, and Data.
  * **⌃ Control:** AI Magic tools (Background Removal, OCR, Compression, EXIF cleaning).
  * **⌘ Command:** Apple Vision Attention-based saliency auto-framing and formatting.
  * **⌥ Option:** Speed modification, scaling, and file cleanup utilities.
* **Local-First & Zero-Cloud:** Powered by Apple Vision, CoreGraphics, AVFoundation, and bundled ffmpeg.

---

### 🇷🇺 Русский
#### 🎉 Первый публичный релиз
* **Радиальное меню в стиле Liquid Glass:** Нативный интерфейс на SwiftUI & AppKit с поддержкой ProMotion до 120 кадров/сек.
* **4 режима жестов через клавиши-модификаторы:**
  * **⇧ Shift:** Мгновенная конвертация форматов (видео, фото, документы, таблицы).
  * **⌃ Control:** Инструменты магии и нейросетей (удаление фона через Apple Vision, OCR, сжатие, очистка EXIF).
  * **⌘ Command:** Умное кадрирование Apple Vision Saliency и форматирование.
  * **⌥ Option:** Управление скоростью видео, масштабирование и утилиты очистки.
* **100% приватность:** Все вычисления производятся локально на Mac без облачных сервисов и интернета.
