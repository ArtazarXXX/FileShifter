[🇬🇧 English](ROADMAP.md) | [🇷🇺 Русский](ROADMAP.ru.md)

# FileShifter — Smart Contextual Overlay for macOS

> Lightning-fast file conversion, Apple Vision AI processing, and quick actions in macOS via modifier gestures (`Shift`, `Ctrl`, `Cmd`, `Option`).

---

## 🧭 Implementation Status (Progress Tracker)

- [x] **Phase 1: Photos & Images (MVP)**
  - [x] Architecture (Swift 6.2 / AppKit MenuBar + Global Event Monitor)
  - [x] Finder file selection bridge (`FinderBridge.swift`)
  - [x] Futuristic Liquid Glass radial wheel menu (`RadialMenuView.swift`)
  - [x] `Shift + Flick` gesture for instant format switching (`WebP`, `PNG`, `JPG`, `PDF`)
  - [x] `Control + Flick` gesture for AI Magic actions (`ImageProcessor.swift`):
    - [x] Background Removal (Apple Vision `VNGenerateForegroundInstanceMaskRequest`)
    - [x] Lossless & Web Compression (Web Optimize)
    - [x] Text Recognition (OCR directly to `NSPasteboard` clipboard)
    - [x] Proportional Scaling (-50%, -25%, +25%, +50%, +100%)
    - [x] Rotation (+90° CW)
    - [x] Circular Avatar Creation with Alpha Transparency (PNG)
  - [x] Haptic feedback & floating completion HUD toast (`ToastFeedbackView.swift`)
  - [x] Automated native `.app` bundle builder (`Scripts/build_app.sh`) with stable ad-hoc codesign

- [x] **Phase 2: Video & Audio**
  - [x] Contextual Adaptation: wheel dynamically switches when a video file is highlighted (`.mov`, `.mp4`, `.mkv`, `.webm`...)
  - [x] Video conversion via `Shift + Flick`:
    - [x] `MP4` (Apple Silicon hardware-accelerated `h264_videotoolbox`)
    - [x] `WebM` (VP9 + Opus web codec)
    - [x] `GIF` (High-definition two-pass palette generation)
    - [x] `MP3` (Instant 320 kbps audio track extraction)
    - [x] `MOV` (Apple ProRes / QuickTime)
    - [x] `Movie Remux` (Lossless remux for Mac with subtitle preservation)
  - [x] Magic actions via `Control + Flick` (<25MB compression, Lossless Mute, 5s GIF, 15s GIF, Rotate 90°, Video HUD specs)
  - [x] Playback speed via `Option + Flick` (0.5x, 0.75x, 1.25x, 1.5x, 1.75x, 2.0x, 2.25x, 2.5x with audio pitch correction and image scaling)
  - [x] Smart Vision Video Crop via `Command + Flick` (Auto-Reframe 9:16 Vision vs 9:16 Gaussian Blur, 1:1 Auto/Blur, 16:9, 4:5)

- [x] **Phase 3: Documents, PDFs & Data**
  - [x] Conversion via `Shift + Flick`:
    - [x] **PDF**: PNG (all pages rendered to `_pages/` folder), JPG Cover, Plain text `.txt`, Markdown `.md`
    - [x] **Data (CSV, JSON, YAML, Plist)**: CSV $\leftrightarrow$ JSON, JSON $\leftrightarrow$ YAML, CSV $\rightarrow$ Markdown Table, Plist
    - [x] **Documents (Markdown, DOCX, HTML, TXT)**: Markdown $\rightarrow$ Vector PDF, Markdown $\rightarrow$ Semantic HTML, DOCX $\rightarrow$ PDF (CoreText), DOCX $\rightarrow$ TXT
  - [x] Magic actions via `Control + Flick`:
    - [x] **PDF**: Smart Compression (<5MB), Apple Vision OCR to clipboard, Extract all images, Page splitting (`_split/`), Rotate +90°, HUD Info Card (DPI, page count, file size, security)
    - [x] **Data (JSON, YAML, CSV)**: Prettify (2-space indent, sorted keys), Minify, Copy to clipboard, CSV $\rightarrow$ MD Table to clipboard, Syntax validation & HUD
    - [x] **Documents & Text**: Word count & Reading time HUD, Deduplicate & clean empty lines, UPPERCASE, lowercase, Copy clean text
  - [x] Fast utilities via `Option + Flick`:
    - [x] **PDF**: Rotate +90° CW, Rotate -90° CCW, Flip 180°, Extract page 1, Remove cover page, Clean ZIP without `.DS_Store` and `__MACOSX`
    - [x] **Data & Code**: Clean ZIP archiver, Sort lines A-Z, Deduplicate lines, Number lines, Timestamped backup
  - [x] Advanced manipulation via `Command + Flick`:
    - [x] **PDF**: Smart white margin crop (`cropBox`), Normalize to A4, Translucent "COPY" stamp (45°), Translucent "DRAFT" stamp, Batch folder merge (`_merged.pdf`)
    - [x] **Data & Code**: Head 10 lines, Head 100 lines, Random 10-line sample, Base64 Encode, Base64 Decode

- [x] **Phase 4: System Integration & Design System**
  - [x] Full native macOS Dark Theme adaptation (WCAG AAA typography, adaptive Liquid Glass materials)
  - [x] Pixel-perfect hit-testing alignment (`currentWheelCenter`, 85pt deadzone, 205pt outer clamp)
  - [x] Smart Accessibility (TCC) permission handling with stable designated requirement (`identifier "com.artem.FileShifter"`)
  - [x] Haptic feedback & native macOS sound integration

- [ ] **Phase 5: Future Roadmap (v0.2+)**
  - [ ] Launch at Login (`LaunchAtLogin`)
  - [ ] Graphical Preferences panel (custom hotkeys, default target folders, quality presets)
  - [ ] User extensible action plugins (custom Shell / Python action scripts)

---

## 🎮 UX & Trigger Philosophy

* **Concept**: Radial Wheel menu with a **Hold & Flick** interaction model:
  * Hold modifier key $\rightarrow$ a futuristic Liquid Glass circular wheel instantly spawns centered at your cursor.
  * Flick mouse toward desired action sector (gesture takes ~0.1–0.2s).
  * Release modifier key $\rightarrow$ action executes instantly, wheel smoothly dissolves.

| Trigger | Wheel Mode | Action Sectors |
| :--- | :--- | :--- |
| **Hold `⇧ Shift` + Flick** | 🔄 **Format Conversion** | **Photos**: `WebP`, `AVIF`, `PNG`, `JPG`, `PDF`<br>**Video**: 🍿 `Movie Remux`, `MP4 (H.264)`, `WebM`, `GIF`, `MP3 (320k)`, `MOV`<br>**PDF**: `PNG Pages`, `JPG Cover`, `Extract TXT`, `Markdown`<br>**Data**: `JSON`, `CSV`, `YAML`, `Markdown Table`, `Plist`<br>**Documents**: `Vector PDF`, `HTML`, `Markdown`, `Plain TXT` |
| **Hold `⌃ Control` + Flick** | 🪄 **AI Magic & Info** | **Photos**: Remove Background, Compress, OCR Text, Wipe EXIF, Base64, HUD Info, Avatar, Rotate +90°<br>**Video**: Compress <25MB, Mute Audio, 5s GIF, 15s GIF, Rotate +90°, HUD Info<br>**PDF**: Optimize (<5MB), OCR to Clipboard, Extract All Images, Split Pages, HUD Info<br>**Data**: Prettify, Minify, Copy to Clipboard, Validate & Schema<br>**Text**: Word Count / Reading Time HUD, Deduplicate, UPPERCASE, lowercase |
| **Hold `⌥ Option` + Flick** | ⚡️ **Speed & Utilities** | **Video**: `0.5x`, `0.75x`, `1.25x`, `1.5x`, `1.75x`, `2.0x`, `2.25x`, `2.5x`<br>**Photos**: Scale `50%`, `75%`, `125%`, `150%`, `175%`, `200%`, `225%`, `250%`<br>**PDF**: `+90° CW`, `-90° CCW`, `180°`, `Extract Page 1`, `Remove Page 1`, `Clean ZIP`<br>**Data & Text**: `Clean ZIP`, `Sort A-Z`, `Remove Duplicates`, `Number Lines`, `Timestamp Backup` |
| **Hold `⌘ Command` + Flick** | 📐 **Vision Crop & Advanced** | **Photos**: Vision Saliency Crop 1:1, 16:9, 9:16, 4:3, 4:5, 3:2<br>**Video**: Auto-Reframe 9:16, 9:16 Blur, 1:1 Auto/Blur, 16:9, 4:5<br>**PDF**: Crop Margins, Normalize to A4, "COPY" Stamp, "DRAFT" Stamp, Merge Folder PDFs<br>**Data & Text**: Top 10 Lines, Top 100 Lines, Sample 10 Lines, Base64 Encode, Base64 Decode |

---

## 💾 File Safety & Output Strategy
* **Zero-Destruction Principle**: Original user files are **never overwritten or altered**.
* **Output Location**: Generated outputs are saved in the same directory with descriptive extensions or suffixes:
  * `photo.heic` $\rightarrow$ `photo.webp` / `photo.avif`
  * `photo.jpg` $\rightarrow$ `photo_nobg.png` (background removed)
  * `photo.png` $\rightarrow$ `photo_compressed.png` (or `.jpg` for oversized PNGs)
  * `photo.png` $\rightarrow$ `photo_avatar.png` (circular mask with transparency)
  * For OCR actions, extracted text is copied straight to system clipboard (`NSPasteboard`).

## 🔔 User Feedback
* **Haptic & Audio**: Native macOS tactile feedback (`NSHapticFeedbackManager`) and audio pops (`NSSound`).
* **Visual Status**: Floating HUD toast pill for 0.7s at the cursor with smooth spring animations.

---

## 🛠 Tech Stack & Architecture
* **Language & Platform**: Swift 6.2 / macOS 14+ (Sonoma, Sequoia, Apple Silicon native)
* **Form Factor**: Menu Bar utility (`NSStatusItem`):
  * Toggle active event monitoring
  * Quick access to documentation & quit
* **UI HUD**: Borderless translucent floating panel (`NSPanel` with `.floating` level, `.nonactivatingPanel` and SwiftUI Radial Wheel)
* **Background Interception**: `NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged)` for double-tap modifier detection and cursor tracking
* **File Bridge**: AppleScript (`tell application "Finder" to get selection`) for rapid active file resolution
* **Processing Engines**:
  * Background Removal: Apple Vision Framework (`VNGenerateForegroundInstanceMaskRequest`)
  * OCR: Apple Vision Framework (`VNRecognizeTextRequest`)
  * Image Processing: ImageIO, CoreGraphics, `sips`
  * Video Processing: AVFoundation, hardware-accelerated `videotoolbox`, bundled ffmpeg
