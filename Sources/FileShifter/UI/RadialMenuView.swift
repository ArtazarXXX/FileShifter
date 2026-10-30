import SwiftUI

public enum WheelMode: Sendable {
    case convert
    case magic
    case crop
    case speed
}

public struct SectorItem: Identifiable, Equatable {
    public let id: Int
    public let title: String
    public let subtitle: String?
    public let shortLabel: String?
    public let icon: String
    public let color: Color
    public let action: FileAction
    
    public init(
        id: Int,
        title: String,
        subtitle: String? = nil,
        shortLabel: String? = nil,
        icon: String,
        color: Color,
        action: FileAction
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.shortLabel = shortLabel
        self.icon = icon
        self.color = color
        self.action = action
    }
}

@MainActor
public final class RadialMenuState: ObservableObject {
    @Published public var mode: WheelMode
    @Published public var category: FileCategory
    @Published public var selectedIndex: Int?
    @Published public var fileName: String
    
    public init(
        mode: WheelMode = .convert,
        category: FileCategory = .image,
        selectedIndex: Int? = nil,
        fileName: String = ""
    ) {
        self.mode = mode
        self.category = category
        self.selectedIndex = selectedIndex
        self.fileName = fileName
    }
    
    public func update(mode: WheelMode, category: FileCategory, selectedIndex: Int?, fileName: String) {
        if self.mode != mode { self.mode = mode }
        if self.category != category { self.category = category }
        if self.selectedIndex != selectedIndex { self.selectedIndex = selectedIndex }
        if self.fileName != fileName { self.fileName = fileName }
    }
}

public struct RadialMenuView: View {
    @ObservedObject public var state: RadialMenuState
    
    public var mode: WheelMode { state.mode }
    public var category: FileCategory { state.category }
    public var selectedIndex: Int? { state.selectedIndex }
    public var fileName: String { state.fileName }
    
    public init(state: RadialMenuState) {
        self.state = state
    }
    
    public init(mode: WheelMode, category: FileCategory, selectedIndex: Int?, fileName: String) {
        self.state = RadialMenuState(mode: mode, category: category, selectedIndex: selectedIndex, fileName: fileName)
    }
    
    public var sectors: [SectorItem] {
        Self.getSectors(mode: mode, category: category, fileName: fileName)
    }
    
    public static func getSectors(mode: WheelMode, category: FileCategory, fileName: String) -> [SectorItem] {
        let ext = URL(fileURLWithPath: fileName).pathExtension.lowercased()
        
        switch mode {
        case .convert:
            switch category {
            case .video:
                return [
                    SectorItem(id: 0, title: "Movie Remux", subtitle: "Для Mac без пережатия", shortLabel: "Remux", icon: "popcorn.fill", color: .red, action: .convertVideo(.movieRemux)),
                    SectorItem(id: 1, title: "Convert to MP4", subtitle: "Универсальное H.264", shortLabel: "MP4", icon: "film", color: .blue, action: .convertVideo(.mp4)),
                    SectorItem(id: 2, title: "Convert to WebM", subtitle: "Для сайтов и веба", shortLabel: "WebM", icon: "globe", color: .purple, action: .convertVideo(.webm)),
                    SectorItem(id: 3, title: "Convert to GIF", subtitle: "Высокое качество", shortLabel: "GIF", icon: "play.rectangle.on.rectangle", color: .orange, action: .convertVideo(.gif)),
                    SectorItem(id: 4, title: "Extract MP3", subtitle: "Аудиодорожка 320k", shortLabel: "MP3", icon: "music.note", color: .green, action: .convertVideo(.mp3)),
                    SectorItem(id: 5, title: "Apple ProRes MOV", subtitle: "Монтажный кодек", shortLabel: "MOV", icon: "applelogo", color: .indigo, action: .convertVideo(.mov))
                ]
            case .image:
                return [
                    SectorItem(id: 0, title: "Convert to WebP", subtitle: "Для сайтов и Telegram", shortLabel: "WebP", icon: "photo.stack", color: .cyan, action: .convertImage(.webp)),
                    SectorItem(id: 1, title: "Convert to AVIF", subtitle: "Ультра сжатие", shortLabel: "AVIF", icon: "sparkles", color: .green, action: .convertImage(.avif)),
                    SectorItem(id: 2, title: "Convert to PNG", subtitle: "С прозрачным фоном", shortLabel: "PNG", icon: "square.2.layers.3d", color: .indigo, action: .convertImage(.png)),
                    SectorItem(id: 3, title: "Convert to JPG", subtitle: "Стандартное фото", shortLabel: "JPG", icon: "photo", color: .orange, action: .convertImage(.jpg)),
                    SectorItem(id: 4, title: "Convert to PDF", subtitle: "Документ с фото", shortLabel: "PDF", icon: "doc.richtext", color: .red, action: .convertImage(.pdf))
                ]
            case .pdf:
                return [
                    SectorItem(id: 0, title: "Export Pages to PNG", subtitle: "Все страницы в папку", shortLabel: "PNG", icon: "photo.stack", color: .indigo, action: .convertPDF(.pngPages)),
                    SectorItem(id: 1, title: "Extract Cover JPG", subtitle: "Титульная страница JPG", shortLabel: "Cover", icon: "photo", color: .orange, action: .convertPDF(.jpgCover)),
                    SectorItem(id: 2, title: "Extract Text (.txt)", subtitle: "Извлечь весь текст", shortLabel: "TXT", icon: "doc.plaintext", color: .green, action: .convertPDF(.txt)),
                    SectorItem(id: 3, title: "Convert to Markdown", subtitle: "Структурированный MD", shortLabel: "MD", icon: "doc.text", color: .cyan, action: .convertPDF(.markdown))
                ]
            case .data:
                if ext == "csv" {
                    return [
                        SectorItem(id: 0, title: "Convert to JSON", subtitle: "Массив объектов", shortLabel: "JSON", icon: "curlybraces", color: .yellow, action: .convertData(.json)),
                        SectorItem(id: 1, title: "Convert to YAML", subtitle: "Формат YAML", shortLabel: "YAML", icon: "doc.badge.gearshape", color: .orange, action: .convertData(.yaml)),
                        SectorItem(id: 2, title: "Markdown Table", subtitle: "Таблица в Markdown", shortLabel: "MD", icon: "tablecells.badge.ellipsis", color: .blue, action: .convertData(.markdownTable)),
                        SectorItem(id: 3, title: "Apple Plist", subtitle: "Формат Apple Plist", shortLabel: "Plist", icon: "applelogo", color: .indigo, action: .convertData(.plist))
                    ]
                } else if ext == "yaml" || ext == "yml" {
                    return [
                        SectorItem(id: 0, title: "Convert to JSON", subtitle: "Формат JSON", shortLabel: "JSON", icon: "curlybraces", color: .yellow, action: .convertData(.json)),
                        SectorItem(id: 1, title: "Convert to CSV", subtitle: "Табличные данные", shortLabel: "CSV", icon: "tablecells", color: .green, action: .convertData(.csv)),
                        SectorItem(id: 2, title: "Apple Plist", subtitle: "Формат Apple Plist", shortLabel: "Plist", icon: "applelogo", color: .indigo, action: .convertData(.plist)),
                        SectorItem(id: 3, title: "Markdown Table", subtitle: "Таблица в Markdown", shortLabel: "MD", icon: "tablecells.badge.ellipsis", color: .blue, action: .convertData(.markdownTable))
                    ]
                } else {
                    return [
                        SectorItem(id: 0, title: "Convert to YAML", subtitle: "Формат YAML", shortLabel: "YAML", icon: "doc.badge.gearshape", color: .orange, action: .convertData(.yaml)),
                        SectorItem(id: 1, title: "Convert to CSV", subtitle: "Табличные данные", shortLabel: "CSV", icon: "tablecells", color: .green, action: .convertData(.csv)),
                        SectorItem(id: 2, title: "Apple Plist", subtitle: "Формат Apple Plist", shortLabel: "Plist", icon: "applelogo", color: .indigo, action: .convertData(.plist)),
                        SectorItem(id: 3, title: "Markdown Table", subtitle: "Таблица в Markdown", shortLabel: "MD", icon: "tablecells.badge.ellipsis", color: .blue, action: .convertData(.markdownTable))
                    ]
                }
            case .document:
                if ext == "md" || ext == "markdown" {
                    return [
                        SectorItem(id: 0, title: "Export to PDF", subtitle: "Оформленный PDF", shortLabel: "PDF", icon: "doc.richtext", color: .red, action: .convertDocument(.pdf)),
                        SectorItem(id: 1, title: "Export to HTML", subtitle: "Веб-страница", shortLabel: "HTML", icon: "globe", color: .orange, action: .convertDocument(.html)),
                        SectorItem(id: 2, title: "Export to Word", subtitle: "Документ DOCX", shortLabel: "DOCX", icon: "doc.fill", color: .blue, action: .convertDocument(.docx)),
                        SectorItem(id: 3, title: "Plain Text (.txt)", subtitle: "Без разметки", shortLabel: "TXT", icon: "doc.plaintext", color: .green, action: .convertDocument(.txt))
                    ]
                } else if ext == "html" || ext == "htm" {
                    return [
                        SectorItem(id: 0, title: "Export to PDF", subtitle: "Рендер страницы", shortLabel: "PDF", icon: "doc.richtext", color: .red, action: .convertDocument(.pdf)),
                        SectorItem(id: 1, title: "Convert to Markdown", subtitle: "Текст с разметкой", shortLabel: "MD", icon: "doc.text", color: .cyan, action: .convertDocument(.markdown)),
                        SectorItem(id: 2, title: "Plain Text (.txt)", subtitle: "Только текст", shortLabel: "TXT", icon: "doc.plaintext", color: .green, action: .convertDocument(.txt)),
                        SectorItem(id: 3, title: "Export to Word", subtitle: "Документ DOCX", shortLabel: "DOCX", icon: "doc.fill", color: .blue, action: .convertDocument(.docx))
                    ]
                } else {
                    return [
                        SectorItem(id: 0, title: "Export to PDF", subtitle: "Векторный PDF", shortLabel: "PDF", icon: "doc.richtext", color: .red, action: .convertDocument(.pdf)),
                        SectorItem(id: 1, title: "Convert to Markdown", subtitle: "Текст с разметкой", shortLabel: "MD", icon: "doc.text", color: .blue, action: .convertDocument(.markdown)),
                        SectorItem(id: 2, title: "Export to HTML", subtitle: "Веб-страница", shortLabel: "HTML", icon: "globe", color: .orange, action: .convertDocument(.html)),
                        SectorItem(id: 3, title: "Plain Text (.txt)", subtitle: "Чистый текст", shortLabel: "TXT", icon: "doc.plaintext", color: .green, action: .convertDocument(.txt))
                    ]
                }
            case .other:
                return []
            }
            
        case .magic:
            switch category {
            case .video:
                return [
                    SectorItem(id: 0, title: "Compress <25 MB", subtitle: "Для Telegram / Discord", icon: "arrow.down.right.and.arrow.up.left", color: .teal, action: .magicVideo(.compressTelegram)),
                    SectorItem(id: 1, title: "Mute Audio", subtitle: "Удалить звук из видео", icon: "speaker.slash.fill", color: .pink, action: .magicVideo(.mute)),
                    SectorItem(id: 2, title: "5s Quick GIF", subtitle: "Быстрый мем (первые 5 сек)", icon: "play.rectangle.on.rectangle", color: .orange, action: .magicVideo(.gif5sec)),
                    SectorItem(id: 3, title: "15s Preview GIF", subtitle: "Превью-ролик 15 сек", icon: "video.fill", color: .yellow, action: .magicVideo(.gif15sec)),
                    SectorItem(id: 4, title: "Rotate +90°", subtitle: "Поворот по часовой", icon: "rotate.right", color: .purple, action: .magicVideo(.rotate90)),
                    SectorItem(id: 5, title: "Video HUD Info", subtitle: "Битрейт, кодек, FPS", icon: "info.circle", color: .cyan, action: .magicVideo(.videoInfo))
                ]
            case .image:
                return [
                    SectorItem(id: 0, title: "Remove Background", subtitle: "Вырезка объекта (Vision)", icon: "wand.and.stars", color: .pink, action: .magicImage(.removeBackground)),
                    SectorItem(id: 1, title: "Smart Compress", subtitle: "Оптимизация размера", icon: "arrow.down.right.and.arrow.up.left", color: .teal, action: .magicImage(.compress)),
                    SectorItem(id: 2, title: "OCR to Clipboard", subtitle: "Распознать текст в буфер", icon: "doc.text.viewfinder", color: .orange, action: .magicImage(.ocr)),
                    SectorItem(id: 3, title: "Wipe EXIF Data", subtitle: "Очистка GPS и приватности", icon: "lock.shield", color: .green, action: .magicImage(.cleanMetadata)),
                    SectorItem(id: 4, title: "Copy Base64", subtitle: "Data URL для фронтенда", icon: "curlybraces", color: .indigo, action: .magicImage(.copyBase64)),
                    SectorItem(id: 5, title: "Image HUD Info", subtitle: "Разрешение, профиль, вес", icon: "info.circle", color: .cyan, action: .magicImage(.imageInfo)),
                    SectorItem(id: 6, title: "Face Crop Avatar", subtitle: "Умный фокус на лице", icon: "person.crop.circle", color: .mint, action: .magicImage(.avatar)),
                    SectorItem(id: 7, title: "Rotate +90°", subtitle: "Поворот по часовой", icon: "rotate.right", color: .purple, action: .magicImage(.rotate90))
                ]
            case .pdf:
                return [
                    SectorItem(id: 0, title: "Compress PDF <5 MB", subtitle: "Умное сжатие документа", icon: "arrow.down.right.and.arrow.up.left", color: .teal, action: .magicPDF(.compress)),
                    SectorItem(id: 1, title: "OCR Scan to Clipboard", subtitle: "Распознать скан в буфер", icon: "doc.text.viewfinder", color: .orange, action: .magicPDF(.ocrClipboard)),
                    SectorItem(id: 2, title: "Extract All Images", subtitle: "Извлечь все иллюстрации", icon: "photo.stack", color: .indigo, action: .magicPDF(.extractImages)),
                    SectorItem(id: 3, title: "Split into Pages", subtitle: "Разрезать по страницам", icon: "scissors", color: .pink, action: .magicPDF(.splitPages)),
                    SectorItem(id: 4, title: "Rotate All +90°", subtitle: "Повернуть все страницы", icon: "rotate.right", color: .purple, action: .magicPDF(.rotate90)),
                    SectorItem(id: 5, title: "PDF Details & Stats", subtitle: "Свойства и метаданные", icon: "info.circle", color: .cyan, action: .magicPDF(.pdfInfo))
                ]
            case .data:
                return [
                    SectorItem(id: 0, title: "Prettify Code", subtitle: "Форматировать с отступами", icon: "sparkles", color: .yellow, action: .magicData(.prettify)),
                    SectorItem(id: 1, title: "Minify Code", subtitle: "Сжать в одну строку", icon: "arrow.right.to.line.compact", color: .orange, action: .magicData(.minify)),
                    SectorItem(id: 2, title: "Copy to Clipboard", subtitle: "Скопировать всё в буфер", icon: "doc.on.clipboard", color: .green, action: .magicData(.copyToClipboard)),
                    SectorItem(id: 3, title: "Copy MD Table", subtitle: "Таблица Markdown в буфер", icon: "tablecells", color: .blue, action: .magicData(.csvToMarkdownTableClipboard)),
                    SectorItem(id: 4, title: "Validate & Inspect", subtitle: "Проверить синтаксис", icon: "info.circle", color: .cyan, action: .magicData(.validateInfo))
                ]
            case .document:
                return [
                    SectorItem(id: 0, title: "Word Count & Stats", subtitle: "Статистика слов и времени", icon: "info.circle", color: .cyan, action: .magicDoc(.wordCountInfo)),
                    SectorItem(id: 1, title: "Deduplicate & Clean", subtitle: "Очистка дублей и пробелов", icon: "wand.and.stars", color: .teal, action: .magicDoc(.cleanText)),
                    SectorItem(id: 2, title: "Copy Clean Text", subtitle: "Скопировать чистый текст", icon: "doc.on.clipboard", color: .green, action: .magicDoc(.copyCleanText)),
                    SectorItem(id: 3, title: "UPPERCASE", subtitle: "ВСЕ ЗАГЛАВНЫЕ БУКВЫ", icon: "textformat.size.larger", color: .purple, action: .magicDoc(.uppercase)),
                    SectorItem(id: 4, title: "lowercase", subtitle: "все строчные буквы", icon: "textformat.size.smaller", color: .pink, action: .magicDoc(.lowercase))
                ]
            case .other:
                return []
            }
            
        case .crop:
            switch category {
            case .video:
                return [
                    SectorItem(id: 0, title: "Reels / Shorts (9:16)", subtitle: "Авто-фокус на объекте", shortLabel: "9:16", icon: "rectangle.portrait", color: .pink, action: .cropVideo(.storyAuto)),
                    SectorItem(id: 1, title: "Story with Blur (9:16)", subtitle: "С размытыми полями", shortLabel: "9:16*", icon: "sparkles.tv", color: .purple, action: .cropVideo(.storyBlur)),
                    SectorItem(id: 2, title: "Square Post (1:1)", subtitle: "Квадратный авто-фокус", shortLabel: "1:1", icon: "square", color: .teal, action: .cropVideo(.squareAuto)),
                    SectorItem(id: 3, title: "Square with Blur (1:1)", subtitle: "Квадрат с размытием", shortLabel: "1:1*", icon: "square.fill", color: .indigo, action: .cropVideo(.squareBlur)),
                    SectorItem(id: 4, title: "Widescreen (16:9)", subtitle: "Широкоформатный кроп", shortLabel: "16:9", icon: "rectangle.ratio.16.to.9", color: .blue, action: .cropVideo(.widescreen)),
                    SectorItem(id: 5, title: "Instagram Feed (4:5)", subtitle: "Портретный пост ленты", shortLabel: "4:5", icon: "rectangle.portrait.fill", color: .orange, action: .cropVideo(.portrait))
                ]
            case .image:
                return [
                    SectorItem(id: 0, title: "Square (1:1)", subtitle: "Квадратное кадрирование", shortLabel: "1:1", icon: "square", color: .purple, action: .cropImage(.square)),
                    SectorItem(id: 1, title: "Widescreen (16:9)", subtitle: "Широкий формат", shortLabel: "16:9", icon: "rectangle.ratio.16.to.9", color: .blue, action: .cropImage(.widescreen)),
                    SectorItem(id: 2, title: "Stories / Reels (9:16)", subtitle: "Вертикальный формат", shortLabel: "9:16", icon: "rectangle.portrait", color: .pink, action: .cropImage(.story)),
                    SectorItem(id: 3, title: "Classic Photo (4:3)", subtitle: "Классическое фото", shortLabel: "4:3", icon: "rectangle.ratio.4.to.3", color: .orange, action: .cropImage(.classic)),
                    SectorItem(id: 4, title: "Instagram Post (4:5)", subtitle: "Портрет для соцсетей", shortLabel: "4:5", icon: "rectangle.portrait.fill", color: .indigo, action: .cropImage(.portrait)),
                    SectorItem(id: 5, title: "35mm Film (3:2)", subtitle: "Плёночный кадр", shortLabel: "3:2", icon: "film", color: .teal, action: .cropImage(.film))
                ]
            case .pdf:
                return [
                    SectorItem(id: 0, title: "Trim White Margins", subtitle: "Обрезать лишние поля", icon: "crop", color: .pink, action: .commandPDF(.trimMargins)),
                    SectorItem(id: 1, title: "Normalize to A4", subtitle: "Привести к формату А4", shortLabel: "A4", icon: "rectangle.portrait", color: .blue, action: .commandPDF(.standardizeA4)),
                    SectorItem(id: 2, title: "Stamp: COPY", subtitle: "Штамп: КОПИЯ", icon: "stamp", color: .red, action: .commandPDF(.stampCopy)),
                    SectorItem(id: 3, title: "Stamp: DRAFT", subtitle: "Штамп: ЧЕРНОВИК", icon: "pencil.and.outline", color: .orange, action: .commandPDF(.stampDraft)),
                    SectorItem(id: 4, title: "Merge Folder PDFs", subtitle: "Объединить все PDF в один", icon: "plus.rectangle.on.rectangle", color: .indigo, action: .commandPDF(.mergeFolderPDFs))
                ]
            case .data, .document:
                return [
                    SectorItem(id: 0, title: "Head: Top 10 Lines", subtitle: "Первые 10 строк", icon: "arrow.up.to.line.compact", color: .teal, action: .commandData(.head10)),
                    SectorItem(id: 1, title: "Head: Top 100 Lines", subtitle: "Первые 100 строк", icon: "arrow.down.to.line.compact", color: .cyan, action: .commandData(.head100)),
                    SectorItem(id: 2, title: "Sample: 10 Lines", subtitle: "Случайная выборка", icon: "dice", color: .purple, action: .commandData(.sample10)),
                    SectorItem(id: 3, title: "Base64 Encode File", subtitle: "Закодировать в Base64", icon: "lock.fill", color: .orange, action: .commandData(.base64Encode)),
                    SectorItem(id: 4, title: "Base64 Decode File", subtitle: "Декодировать из Base64", icon: "lock.open.fill", color: .green, action: .commandData(.base64Decode))
                ]
            case .other:
                return []
            }
            
        case .speed:
            switch category {
            case .video:
                return [
                    SectorItem(id: 0, title: "Slow-Mo (0.5x)", subtitle: "Замедление в 2 раза", shortLabel: "0.5x", icon: "tortoise.fill", color: .teal, action: .videoSpeed(0.5)),
                    SectorItem(id: 1, title: "Smooth Slow (0.75x)", subtitle: "Замедление на 25%", shortLabel: "0.75x", icon: "backward.fill", color: .cyan, action: .videoSpeed(0.75)),
                    SectorItem(id: 2, title: "Slight Speedup (1.25x)", subtitle: "Ускорение на 25%", shortLabel: "1.25x", icon: "forward.fill", color: .green, action: .videoSpeed(1.25)),
                    SectorItem(id: 3, title: "Lecture Speed (1.5x)", subtitle: "Оптимально для лекций", shortLabel: "1.5x", icon: "bolt.fill", color: .yellow, action: .videoSpeed(1.5)),
                    SectorItem(id: 4, title: "Fast Pace (1.75x)", subtitle: "Быстрый просмотр", shortLabel: "1.75x", icon: "hare.fill", color: .orange, action: .videoSpeed(1.75)),
                    SectorItem(id: 5, title: "Double Speed (2.0x)", subtitle: "Ускорение в 2 раза", shortLabel: "2.0x", icon: "gauge.with.dots.needle.100percent", color: .pink, action: .videoSpeed(2.0)),
                    SectorItem(id: 6, title: "Ultra Fast (2.25x)", subtitle: "Сверхбыстрый темп", shortLabel: "2.25x", icon: "flame.fill", color: .purple, action: .videoSpeed(2.25)),
                    SectorItem(id: 7, title: "Timelapse (2.5x)", subtitle: "Таймлапс эффект", shortLabel: "2.5x", icon: "sparkles", color: .indigo, action: .videoSpeed(2.5))
                ]
            case .image:
                return [
                    SectorItem(id: 0, title: "Resize to 50%", subtitle: "Уменьшить вдвое (0.5x)", shortLabel: "50%", icon: "arrow.down.right.and.arrow.up.left", color: .teal, action: .imageScale(0.5)),
                    SectorItem(id: 1, title: "Resize to 75%", subtitle: "Уменьшить на 25%", shortLabel: "75%", icon: "arrow.down.right.and.arrow.up.left", color: .cyan, action: .imageScale(0.75)),
                    SectorItem(id: 2, title: "Upscale to 125%", subtitle: "Увеличить на 25%", shortLabel: "125%", icon: "arrow.up.left.and.arrow.down.right", color: .green, action: .imageScale(1.25)),
                    SectorItem(id: 3, title: "Upscale to 150%", subtitle: "Увеличить в 1.5 раза", shortLabel: "150%", icon: "arrow.up.left.and.arrow.down.right", color: .yellow, action: .imageScale(1.5)),
                    SectorItem(id: 4, title: "Upscale to 175%", subtitle: "Увеличить на 75%", shortLabel: "175%", icon: "arrow.up.left.and.arrow.down.right", color: .orange, action: .imageScale(1.75)),
                    SectorItem(id: 5, title: "Upscale 2x (200%)", subtitle: "Увеличить вдвое (2x)", shortLabel: "200%", icon: "arrow.up.left.and.arrow.down.right", color: .pink, action: .imageScale(2.0)),
                    SectorItem(id: 6, title: "Upscale to 225%", subtitle: "Увеличить в 2.25 раза", shortLabel: "225%", icon: "arrow.up.left.and.arrow.down.right", color: .purple, action: .imageScale(2.25)),
                    SectorItem(id: 7, title: "Upscale 2.5x (250%)", subtitle: "Увеличить в 2.5 раза", shortLabel: "250%", icon: "sparkles", color: .indigo, action: .imageScale(2.5))
                ]
            case .pdf:
                return [
                    SectorItem(id: 0, title: "Rotate +90° Right", subtitle: "По часовой стрелке", icon: "rotate.right", color: .blue, action: .optionPDF(.rotateCW)),
                    SectorItem(id: 1, title: "Rotate -90° Left", subtitle: "Против часовой", icon: "rotate.left", color: .indigo, action: .optionPDF(.rotateCCW)),
                    SectorItem(id: 2, title: "Flip 180° Upside Down", subtitle: "Перевернуть на 180°", icon: "arrow.triangle.2.circlepath", color: .purple, action: .optionPDF(.rotate180)),
                    SectorItem(id: 3, title: "Extract Cover Page", subtitle: "Только титульная страница", icon: "doc", color: .orange, action: .optionPDF(.extractFirstPage)),
                    SectorItem(id: 4, title: "Remove Cover Page", subtitle: "Удалить первую страницу", icon: "minus.rectangle", color: .pink, action: .optionPDF(.removeFirstPage)),
                    SectorItem(id: 5, title: "Clean ZIP Archive", subtitle: "Архив без .DS_Store", icon: "archivebox.fill", color: .green, action: .optionPDF(.cleanZip))
                ]
            case .data, .document:
                return [
                    SectorItem(id: 0, title: "Clean ZIP Archive", subtitle: "Архив без .DS_Store", icon: "archivebox.fill", color: .green, action: .optionData(.cleanZip)),
                    SectorItem(id: 1, title: "Sort Lines (A → Z)", subtitle: "Сортировка по алфавиту", icon: "arrow.up.and.down.text.horizontal", color: .blue, action: .optionData(.sortAZ)),
                    SectorItem(id: 2, title: "Deduplicate Lines", subtitle: "Удалить повторы строк", icon: "line.3.horizontal.decrease.circle", color: .orange, action: .optionData(.deduplicate)),
                    SectorItem(id: 3, title: "Number Lines (1, 2...)", subtitle: "Пронумеровать строки", icon: "list.number", color: .purple, action: .optionData(.numberLines)),
                    SectorItem(id: 4, title: "Timestamp Backup", subtitle: "Резервная копия с датой", icon: "clock.arrow.circlepath", color: .teal, action: .optionData(.backupTimestamp))
                ]
            case .other:
                return []
            }
        }
    }
    
    public static let wheelRadius: CGFloat = 175.0
    public static let innerRadius: CGFloat = 85.0
    public static let buttonRadius: CGFloat = 135.0
    
    public var body: some View {
        ZStack {
            // Светлый Liquid Glass с высокой матовой прозрачностью и мягкой тенью
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: Self.wheelRadius * 2 + 58, height: Self.wheelRadius * 2 + 58)
                .shadow(color: .black.opacity(0.18), radius: 18, x: 0, y: 0)
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.8), .white.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
            
            // Секторы колеса: строго центрированы на радиусе buttonRadius
            ForEach(Array(sectors.enumerated()), id: \.element.id) { index, sector in
                let count = sectors.count
                let angleStep = 360.0 / Double(count)
                let midAngle = Double(index) * angleStep - 90.0
                let isSelected = selectedIndex == index
                
                SectorButton(
                    sector: sector,
                    angle: midAngle,
                    radius: Self.buttonRadius,
                    isSelected: isSelected
                )
            }
            
            // Центральная ступица: просторная зона отмены в покое / динамический двуязычный HUD при наведении
            Circle()
                .fill(.regularMaterial)
                .frame(width: Self.innerRadius * 2, height: Self.innerRadius * 2)
                .overlay(
                    Circle()
                        .stroke(activeHubStroke, lineWidth: selectedIndex != nil ? 1.8 : 1)
                )
                .shadow(color: activeHubShadow, radius: selectedIndex != nil ? 12 : 3)
                .overlay(
                    Group {
                        if let index = selectedIndex, index < sectors.count {
                            let item = sectors[index]
                            VStack(spacing: 4) {
                                Image(systemName: item.icon)
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundStyle(item.color)
                                
                                Text(item.title)
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundStyle(Color(white: 0.12))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.85)
                                
                                if let sub = item.subtitle {
                                    Text(sub)
                                        .font(.system(size: 10.5, weight: .medium, design: .rounded))
                                        .foregroundStyle(Color(white: 0.42))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.85)
                                }
                            }
                            .padding(.horizontal, 14)
                        } else {
                            VStack(spacing: 4) {
                                Image(systemName: centerIconName)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundStyle(centerColor)
                                
                                Text(fileName)
                                    .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                    .frame(maxWidth: 124)
                                    .foregroundStyle(Color(white: 0.2))
                                
                                Text("Dismiss • Отмена")
                                    .font(.system(size: 9, weight: .medium, design: .rounded))
                                    .foregroundStyle(Color(white: 0.5))
                            }
                            .padding(.horizontal, 14)
                        }
                    }
                    .animation(.spring(response: 0.16, dampingFraction: 0.7), value: selectedIndex)
                )
        }
        .frame(width: 440, height: 440)
    }
    
    private var activeHubStroke: Color {
        if let index = selectedIndex, index < sectors.count {
            return sectors[index].color.opacity(0.85)
        }
        return .white.opacity(0.4)
    }
    
    private var activeHubShadow: Color {
        if let index = selectedIndex, index < sectors.count {
            return sectors[index].color.opacity(0.35)
        }
        return .black.opacity(0.06)
    }
    
    private var centerIconName: String {
        if category == .video && mode == .convert {
            return "film.stack"
        }
        switch mode {
        case .convert: return "arrow.triangle.2.circlepath"
        case .magic: return "sparkles"
        case .crop: return "crop"
        case .speed: return category == .video ? "gauge.with.dots.needle.100percent" : "arrow.up.left.and.arrow.down.right"
        }
    }
    
    private var centerColor: Color {
        if category == .video && mode == .convert {
            return .blue
        }
        switch mode {
        case .convert: return .cyan
        case .magic: return .pink
        case .crop: return .purple
        case .speed: return .orange
        }
    }
}

private struct SectorButton: View {
    let sector: SectorItem
    let angle: Double
    let radius: CGFloat
    let isSelected: Bool
    
    var body: some View {
        let rad = angle * .pi / 180.0
        let x = radius * cos(rad)
        let y = radius * sin(rad)
        
        ZStack {
            // Кнопка-сектор: круглая форма Liquid Glass с анимацией при выборе
            Circle()
                .fill(isSelected ? sector.color : Color.white.opacity(0.65))
                .frame(width: 44, height: 44)
                .overlay(
                    Circle()
                        .stroke(isSelected ? .white : sector.color.opacity(0.4), lineWidth: isSelected ? 2 : 1)
                )
                .shadow(color: isSelected ? sector.color.opacity(0.55) : .black.opacity(0.08), radius: isSelected ? 8 : 3)
            
            // Если есть короткий лейбл (например, "WebP", "9:16", "0.5x") — отображаем его, иначе системную иконку
            if let short = sector.shortLabel {
                Text(short)
                    .font(.system(size: short.count > 3 ? 11 : 13, weight: .bold, design: .rounded))
                    .foregroundStyle(isSelected ? .white : sector.color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            } else {
                Image(systemName: sector.icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(isSelected ? .white : sector.color)
            }
        }
        .frame(width: 44, height: 44)
        .scaleEffect(isSelected ? 1.15 : 1.0)
        .animation(.spring(response: 0.18, dampingFraction: 0.65), value: isSelected)
        .offset(x: x, y: y)
    }
}
