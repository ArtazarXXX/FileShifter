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
    public let icon: String
    public let color: Color
    public let action: FileAction
    
    public init(id: Int, title: String, subtitle: String? = nil, icon: String, color: Color, action: FileAction) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
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
                    SectorItem(id: 0, title: "Фильм", subtitle: "Для Mac Remux", icon: "popcorn.fill", color: .red, action: .convertVideo(.movieRemux)),
                    SectorItem(id: 1, title: "MP4", subtitle: "H.264", icon: "film", color: .blue, action: .convertVideo(.mp4)),
                    SectorItem(id: 2, title: "WebM", subtitle: "Для веба", icon: "globe", color: .purple, action: .convertVideo(.webm)),
                    SectorItem(id: 3, title: "GIF", subtitle: "Анимация", icon: "play.rectangle.on.rectangle", color: .orange, action: .convertVideo(.gif)),
                    SectorItem(id: 4, title: "MP3", subtitle: "Звук 320k", icon: "music.note", color: .green, action: .convertVideo(.mp3)),
                    SectorItem(id: 5, title: "MOV", subtitle: "Apple", icon: "applelogo", color: .indigo, action: .convertVideo(.mov))
                ]
            case .image:
                return [
                    SectorItem(id: 0, title: "WebP", subtitle: "Для веба", icon: "photo.stack", color: .cyan, action: .convertImage(.webp)),
                    SectorItem(id: 1, title: "AVIF", subtitle: "Ультра сжатие", icon: "sparkles", color: .green, action: .convertImage(.avif)),
                    SectorItem(id: 2, title: "PNG", subtitle: "С альфой", icon: "square.2.layers.3d", color: .indigo, action: .convertImage(.png)),
                    SectorItem(id: 3, title: "JPG", subtitle: "Фото", icon: "photo", color: .orange, action: .convertImage(.jpg)),
                    SectorItem(id: 4, title: "PDF", subtitle: "Документ", icon: "doc.richtext", color: .red, action: .convertImage(.pdf))
                ]
            case .pdf:
                return [
                    SectorItem(id: 0, title: "PNG (Стр.)", subtitle: "Все страницы", icon: "photo.stack", color: .indigo, action: .convertPDF(.pngPages)),
                    SectorItem(id: 1, title: "Обложка", subtitle: "Первая стр. JPG", icon: "photo", color: .orange, action: .convertPDF(.jpgCover)),
                    SectorItem(id: 2, title: "Текст .txt", subtitle: "Извлечь текст", icon: "doc.plaintext", color: .green, action: .convertPDF(.txt)),
                    SectorItem(id: 3, title: "Markdown", subtitle: "Форматированный", icon: "doc.text", color: .cyan, action: .convertPDF(.markdown))
                ]
            case .data:
                if ext == "csv" {
                    return [
                        SectorItem(id: 0, title: "JSON", subtitle: "Массив объектов", icon: "curlybraces", color: .yellow, action: .convertData(.json)),
                        SectorItem(id: 1, title: "YAML", subtitle: "Формат YAML", icon: "doc.badge.gearshape", color: .orange, action: .convertData(.yaml)),
                        SectorItem(id: 2, title: "MD Таблица", subtitle: "Таблица в MD", icon: "tablecells.badge.ellipsis", color: .blue, action: .convertData(.markdownTable)),
                        SectorItem(id: 3, title: "Plist", subtitle: "Apple Plist", icon: "applelogo", color: .indigo, action: .convertData(.plist))
                    ]
                } else if ext == "yaml" || ext == "yml" {
                    return [
                        SectorItem(id: 0, title: "JSON", subtitle: "Формат JSON", icon: "curlybraces", color: .yellow, action: .convertData(.json)),
                        SectorItem(id: 1, title: "CSV", subtitle: "Табличные данные", icon: "tablecells", color: .green, action: .convertData(.csv)),
                        SectorItem(id: 2, title: "Plist", subtitle: "Apple Plist", icon: "applelogo", color: .indigo, action: .convertData(.plist)),
                        SectorItem(id: 3, title: "MD Таблица", subtitle: "Таблица в MD", icon: "tablecells.badge.ellipsis", color: .blue, action: .convertData(.markdownTable))
                    ]
                } else {
                    return [
                        SectorItem(id: 0, title: "YAML", subtitle: "Формат YAML", icon: "doc.badge.gearshape", color: .orange, action: .convertData(.yaml)),
                        SectorItem(id: 1, title: "CSV", subtitle: "Табличные данные", icon: "tablecells", color: .green, action: .convertData(.csv)),
                        SectorItem(id: 2, title: "Plist", subtitle: "Apple Plist", icon: "applelogo", color: .indigo, action: .convertData(.plist)),
                        SectorItem(id: 3, title: "MD Таблица", subtitle: "Таблица в MD", icon: "tablecells.badge.ellipsis", color: .blue, action: .convertData(.markdownTable))
                    ]
                }
            case .document:
                if ext == "md" || ext == "markdown" {
                    return [
                        SectorItem(id: 0, title: "PDF", subtitle: "Оформленный PDF", icon: "doc.richtext", color: .red, action: .convertDocument(.pdf)),
                        SectorItem(id: 1, title: "HTML", subtitle: "Веб-страница", icon: "globe", color: .orange, action: .convertDocument(.html)),
                        SectorItem(id: 2, title: "DOCX", subtitle: "Документ Word", icon: "doc.fill", color: .blue, action: .convertDocument(.docx)),
                        SectorItem(id: 3, title: "TXT", subtitle: "Без разметки", icon: "doc.plaintext", color: .green, action: .convertDocument(.txt))
                    ]
                } else if ext == "html" || ext == "htm" {
                    return [
                        SectorItem(id: 0, title: "PDF", subtitle: "Рендер PDF", icon: "doc.richtext", color: .red, action: .convertDocument(.pdf)),
                        SectorItem(id: 1, title: "Markdown", subtitle: "В Markdown", icon: "doc.text", color: .cyan, action: .convertDocument(.markdown)),
                        SectorItem(id: 2, title: "TXT", subtitle: "Только текст", icon: "doc.plaintext", color: .green, action: .convertDocument(.txt)),
                        SectorItem(id: 3, title: "DOCX", subtitle: "Документ Word", icon: "doc.fill", color: .blue, action: .convertDocument(.docx))
                    ]
                } else {
                    return [
                        SectorItem(id: 0, title: "PDF", subtitle: "Векторный PDF", icon: "doc.richtext", color: .red, action: .convertDocument(.pdf)),
                        SectorItem(id: 1, title: "Markdown", subtitle: "С разметкой", icon: "doc.text", color: .blue, action: .convertDocument(.markdown)),
                        SectorItem(id: 2, title: "HTML", subtitle: "Веб-страница", icon: "globe", color: .orange, action: .convertDocument(.html)),
                        SectorItem(id: 3, title: "TXT", subtitle: "Чистый текст", icon: "doc.plaintext", color: .green, action: .convertDocument(.txt))
                    ]
                }
            case .other:
                return []
            }
            
        case .magic:
            switch category {
            case .video:
                return [
                    SectorItem(id: 0, title: "Сжать <25МБ", subtitle: "Для Telegram", icon: "arrow.down.right.and.arrow.up.left", color: .teal, action: .magicVideo(.compressTelegram)),
                    SectorItem(id: 1, title: "Без звука", subtitle: "Mute", icon: "speaker.slash.fill", color: .pink, action: .magicVideo(.mute)),
                    SectorItem(id: 2, title: "5 сек GIF", subtitle: "Быстрый мем", icon: "play.rectangle.on.rectangle", color: .orange, action: .magicVideo(.gif5sec)),
                    SectorItem(id: 3, title: "15 сек GIF", subtitle: "Превью", icon: "video.fill", color: .yellow, action: .magicVideo(.gif15sec)),
                    SectorItem(id: 4, title: "Поворот", subtitle: "+90°", icon: "rotate.right", color: .purple, action: .magicVideo(.rotate90)),
                    SectorItem(id: 5, title: "Инфо", subtitle: "Параметры", icon: "info.circle", color: .cyan, action: .magicVideo(.videoInfo))
                ]
            case .image:
                return [
                    SectorItem(id: 0, title: "Удалить фон", subtitle: "Cutout PNG", icon: "wand.and.stars", color: .pink, action: .magicImage(.removeBackground)),
                    SectorItem(id: 1, title: "Сжать", subtitle: "Optimize", icon: "arrow.down.right.and.arrow.up.left", color: .teal, action: .magicImage(.compress)),
                    SectorItem(id: 2, title: "OCR текст", subtitle: "В буфер", icon: "doc.text.viewfinder", color: .orange, action: .magicImage(.ocr)),
                    SectorItem(id: 3, title: "Очистить EXIF", subtitle: "Без GPS", icon: "lock.shield", color: .green, action: .magicImage(.cleanMetadata)),
                    SectorItem(id: 4, title: "Base64", subtitle: "Data URL", icon: "curlybraces", color: .indigo, action: .magicImage(.copyBase64)),
                    SectorItem(id: 5, title: "Инфо", subtitle: "Свойства", icon: "info.circle", color: .cyan, action: .magicImage(.imageInfo)),
                    SectorItem(id: 6, title: "Аватарка", subtitle: "Авто-фокус лица", icon: "person.crop.circle", color: .mint, action: .magicImage(.avatar)),
                    SectorItem(id: 7, title: "Поворот", subtitle: "+90°", icon: "rotate.right", color: .purple, action: .magicImage(.rotate90))
                ]
            case .pdf:
                return [
                    SectorItem(id: 0, title: "Сжать", subtitle: "PDF <5МБ", icon: "arrow.down.right.and.arrow.up.left", color: .teal, action: .magicPDF(.compress)),
                    SectorItem(id: 1, title: "OCR в буфер", subtitle: "Распознать скан", icon: "doc.text.viewfinder", color: .orange, action: .magicPDF(.ocrClipboard)),
                    SectorItem(id: 2, title: "Извлечь фото", subtitle: "Все картинки", icon: "photo.stack", color: .indigo, action: .magicPDF(.extractImages)),
                    SectorItem(id: 3, title: "Разрезать", subtitle: "Постранично", icon: "scissors", color: .pink, action: .magicPDF(.splitPages)),
                    SectorItem(id: 4, title: "Поворот", subtitle: "+90°", icon: "rotate.right", color: .purple, action: .magicPDF(.rotate90)),
                    SectorItem(id: 5, title: "Инфо", subtitle: "Свойства PDF", icon: "info.circle", color: .cyan, action: .magicPDF(.pdfInfo))
                ]
            case .data:
                return [
                    SectorItem(id: 0, title: "Prettify", subtitle: "Форматировать", icon: "sparkles", color: .yellow, action: .magicData(.prettify)),
                    SectorItem(id: 1, title: "Minify", subtitle: "В 1 строку", icon: "arrow.right.to.line.compact", color: .orange, action: .magicData(.minify)),
                    SectorItem(id: 2, title: "В буфер", subtitle: "Копировать код", icon: "doc.on.clipboard", color: .green, action: .magicData(.copyToClipboard)),
                    SectorItem(id: 3, title: "MD Таблица", subtitle: "Таблица в буфер", icon: "tablecells", color: .blue, action: .magicData(.csvToMarkdownTableClipboard)),
                    SectorItem(id: 4, title: "Инфо", subtitle: "Валидация", icon: "info.circle", color: .cyan, action: .magicData(.validateInfo))
                ]
            case .document:
                return [
                    SectorItem(id: 0, title: "Инфо / Слов", subtitle: "Статистика текста", icon: "info.circle", color: .cyan, action: .magicDoc(.wordCountInfo)),
                    SectorItem(id: 1, title: "Очистить", subtitle: "Без дублей строк", icon: "wand.and.stars", color: .teal, action: .magicDoc(.cleanText)),
                    SectorItem(id: 2, title: "В буфер", subtitle: "Чистый текст", icon: "doc.on.clipboard", color: .green, action: .magicDoc(.copyCleanText)),
                    SectorItem(id: 3, title: "UPPERCASE", subtitle: "ВСЕ ЗАГЛАВНЫЕ", icon: "textformat.size.larger", color: .purple, action: .magicDoc(.uppercase)),
                    SectorItem(id: 4, title: "lowercase", subtitle: "все строчные", icon: "textformat.size.smaller", color: .pink, action: .magicDoc(.lowercase))
                ]
            case .other:
                return []
            }
            
        case .crop:
            switch category {
            case .video:
                return [
                    SectorItem(id: 0, title: "9:16 Авто", subtitle: "Reels / Shorts", icon: "rectangle.portrait", color: .pink, action: .cropVideo(.storyAuto)),
                    SectorItem(id: 1, title: "9:16 Поля", subtitle: "С размытием", icon: "sparkles.tv", color: .purple, action: .cropVideo(.storyBlur)),
                    SectorItem(id: 2, title: "1:1 Авто", subtitle: "Квадрат", icon: "square", color: .teal, action: .cropVideo(.squareAuto)),
                    SectorItem(id: 3, title: "1:1 Поля", subtitle: "С размытием", icon: "square.fill", color: .indigo, action: .cropVideo(.squareBlur)),
                    SectorItem(id: 4, title: "16:9", subtitle: "Широкий", icon: "rectangle.ratio.16.to.9", color: .blue, action: .cropVideo(.widescreen)),
                    SectorItem(id: 5, title: "4:5 Инста", subtitle: "Пост ленты", icon: "rectangle.portrait.fill", color: .orange, action: .cropVideo(.portrait))
                ]
            case .image:
                return [
                    SectorItem(id: 0, title: "1:1", subtitle: "Квадрат", icon: "square", color: .purple, action: .cropImage(.square)),
                    SectorItem(id: 1, title: "16:9", subtitle: "Широкий", icon: "rectangle.ratio.16.to.9", color: .blue, action: .cropImage(.widescreen)),
                    SectorItem(id: 2, title: "9:16", subtitle: "Сторис", icon: "rectangle.portrait", color: .pink, action: .cropImage(.story)),
                    SectorItem(id: 3, title: "4:3", subtitle: "Фото", icon: "rectangle.ratio.4.to.3", color: .orange, action: .cropImage(.classic)),
                    SectorItem(id: 4, title: "4:5", subtitle: "Инста", icon: "rectangle.portrait.fill", color: .indigo, action: .cropImage(.portrait)),
                    SectorItem(id: 5, title: "3:2", subtitle: "35mm", icon: "film", color: .teal, action: .cropImage(.film))
                ]
            case .pdf:
                return [
                    SectorItem(id: 0, title: "Кроп полей", subtitle: "Обрезать поля", icon: "crop", color: .pink, action: .commandPDF(.trimMargins)),
                    SectorItem(id: 1, title: "Формат A4", subtitle: "Стандартизировать", icon: "rectangle.portrait", color: .blue, action: .commandPDF(.standardizeA4)),
                    SectorItem(id: 2, title: "Штамп: КОПИЯ", subtitle: "Красный штамп", icon: "stamp", color: .red, action: .commandPDF(.stampCopy)),
                    SectorItem(id: 3, title: "Штамп: DRAFT", subtitle: "Черновик", icon: "pencil.and.outline", color: .orange, action: .commandPDF(.stampDraft)),
                    SectorItem(id: 4, title: "Объединить", subtitle: "Собрать все PDF", icon: "plus.rectangle.on.rectangle", color: .indigo, action: .commandPDF(.mergeFolderPDFs))
                ]
            case .data, .document:
                return [
                    SectorItem(id: 0, title: "Топ-10 строк", subtitle: "Head 10 срез", icon: "arrow.up.to.line.compact", color: .teal, action: .commandData(.head10)),
                    SectorItem(id: 1, title: "Топ-100 строк", subtitle: "Head 100 срез", icon: "arrow.down.to.line.compact", color: .cyan, action: .commandData(.head100)),
                    SectorItem(id: 2, title: "Семпл 10 строк", subtitle: "Случайная выборка", icon: "dice", color: .purple, action: .commandData(.sample10)),
                    SectorItem(id: 3, title: "Base64 Encode", subtitle: "В Base64 файл", icon: "lock.fill", color: .orange, action: .commandData(.base64Encode)),
                    SectorItem(id: 4, title: "Base64 Decode", subtitle: "Из Base64", icon: "lock.open.fill", color: .green, action: .commandData(.base64Decode))
                ]
            case .other:
                return []
            }
            
        case .speed:
            switch category {
            case .video:
                return [
                    SectorItem(id: 0, title: "0.5x", subtitle: "Slow-Mo", icon: "tortoise.fill", color: .teal, action: .videoSpeed(0.5)),
                    SectorItem(id: 1, title: "0.75x", subtitle: "-25%", icon: "backward.fill", color: .cyan, action: .videoSpeed(0.75)),
                    SectorItem(id: 2, title: "1.25x", subtitle: "+25%", icon: "forward.fill", color: .green, action: .videoSpeed(1.25)),
                    SectorItem(id: 3, title: "1.5x", subtitle: "Лекции", icon: "bolt.fill", color: .yellow, action: .videoSpeed(1.5)),
                    SectorItem(id: 4, title: "1.75x", subtitle: "Быстро", icon: "hare.fill", color: .orange, action: .videoSpeed(1.75)),
                    SectorItem(id: 5, title: "2.0x", subtitle: "2x Двойная", icon: "gauge.with.dots.needle.100percent", color: .pink, action: .videoSpeed(2.0)),
                    SectorItem(id: 6, title: "2.25x", subtitle: "Динамика", icon: "flame.fill", color: .purple, action: .videoSpeed(2.25)),
                    SectorItem(id: 7, title: "2.5x", subtitle: "Таймлапс", icon: "sparkles", color: .indigo, action: .videoSpeed(2.5))
                ]
            case .image:
                return [
                    SectorItem(id: 0, title: "50%", subtitle: "0.5x", icon: "arrow.down.right.and.arrow.up.left", color: .teal, action: .imageScale(0.5)),
                    SectorItem(id: 1, title: "75%", subtitle: "0.75x", icon: "arrow.down.right.and.arrow.up.left", color: .cyan, action: .imageScale(0.75)),
                    SectorItem(id: 2, title: "125%", subtitle: "1.25x", icon: "arrow.up.left.and.arrow.down.right", color: .green, action: .imageScale(1.25)),
                    SectorItem(id: 3, title: "150%", subtitle: "1.5x", icon: "arrow.up.left.and.arrow.down.right", color: .yellow, action: .imageScale(1.5)),
                    SectorItem(id: 4, title: "175%", subtitle: "1.75x", icon: "arrow.up.left.and.arrow.down.right", color: .orange, action: .imageScale(1.75)),
                    SectorItem(id: 5, title: "200%", subtitle: "2x", icon: "arrow.up.left.and.arrow.down.right", color: .pink, action: .imageScale(2.0)),
                    SectorItem(id: 6, title: "225%", subtitle: "2.25x", icon: "arrow.up.left.and.arrow.down.right", color: .purple, action: .imageScale(2.25)),
                    SectorItem(id: 7, title: "250%", subtitle: "2.5x", icon: "sparkles", color: .indigo, action: .imageScale(2.5))
                ]
            case .pdf:
                return [
                    SectorItem(id: 0, title: "+90° Вправо", subtitle: "По часовой", icon: "rotate.right", color: .blue, action: .optionPDF(.rotateCW)),
                    SectorItem(id: 1, title: "-90° Влево", subtitle: "Против часовой", icon: "rotate.left", color: .indigo, action: .optionPDF(.rotateCCW)),
                    SectorItem(id: 2, title: "180°", subtitle: "Перевернуть", icon: "arrow.triangle.2.circlepath", color: .purple, action: .optionPDF(.rotate180)),
                    SectorItem(id: 3, title: "Только стр. 1", subtitle: "Титульный лист", icon: "doc", color: .orange, action: .optionPDF(.extractFirstPage)),
                    SectorItem(id: 4, title: "Удалить стр. 1", subtitle: "Без обложки", icon: "minus.rectangle", color: .pink, action: .optionPDF(.removeFirstPage)),
                    SectorItem(id: 5, title: "Чистый ZIP", subtitle: "Без .DS_Store", icon: "archivebox.fill", color: .green, action: .optionPDF(.cleanZip))
                ]
            case .data, .document:
                return [
                    SectorItem(id: 0, title: "Чистый ZIP", subtitle: "Без .DS_Store", icon: "archivebox.fill", color: .green, action: .optionData(.cleanZip)),
                    SectorItem(id: 1, title: "Сортировка A-Z", subtitle: "По алфавиту", icon: "arrow.up.and.down.text.horizontal", color: .blue, action: .optionData(.sortAZ)),
                    SectorItem(id: 2, title: "Удалить дубли", subtitle: "Уникальные строки", icon: "line.3.horizontal.decrease.circle", color: .orange, action: .optionData(.deduplicate)),
                    SectorItem(id: 3, title: "Нумерация", subtitle: "1, 2, 3...", icon: "list.number", color: .purple, action: .optionData(.numberLines)),
                    SectorItem(id: 4, title: "Резервная копия", subtitle: "С датой и временем", icon: "clock.arrow.circlepath", color: .teal, action: .optionData(.backupTimestamp))
                ]
            case .other:
                return []
            }
        }
    }
    
    public static let wheelRadius: CGFloat = 142.0
    public static let innerRadius: CGFloat = 50.0
    public static let buttonRadius: CGFloat = 108.0
    
    public var body: some View {
        ZStack {
            // Светлый Liquid Glass с высокой матовой прозрачностью и симметричной тенью
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
            
            // Секторы колеса: строго привязаны к углу и радиусу
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
            
            // Центральная ступица (зона "ничего не делать" с инфо о файле)
            Circle()
                .fill(.regularMaterial)
                .frame(width: Self.innerRadius * 2, height: Self.innerRadius * 2)
                .overlay(
                    Circle()
                        .stroke(.white.opacity(0.4), lineWidth: 1)
                )
                .overlay(
                    VStack(spacing: 3) {
                        Image(systemName: centerIconName)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(centerColor)
                        
                        Text(fileName)
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .frame(maxWidth: 78)
                            .foregroundStyle(Color(white: 0.2))
                    }
                )
        }
        .frame(width: 440, height: 440)
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
            // Круглая кнопка с иконкой — её центр ВСЕГДА строго в точке (x, y)
            Circle()
                .fill(isSelected ? sector.color : Color.white.opacity(0.55))
                .frame(width: 44, height: 44)
                .overlay(
                    Circle()
                        .stroke(isSelected ? .white : sector.color.opacity(0.4), lineWidth: isSelected ? 2 : 1)
                )
                .shadow(color: isSelected ? sector.color.opacity(0.5) : .black.opacity(0.08), radius: isSelected ? 8 : 3)
            
            Image(systemName: sector.icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(isSelected ? .white : sector.color)
        }
        .frame(width: 44, height: 44)
        .overlay(alignment: .bottom) {
            VStack(spacing: 1.5) {
                Text(sector.title)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(white: 0.12))
                
                if let sub = sector.subtitle {
                    Text(sub)
                        .font(.system(size: 8.5, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(white: 0.38))
                }
            }
            .fixedSize()
            .offset(y: 33)
            .allowsHitTesting(false)
        }
        .scaleEffect(isSelected ? 1.15 : 1.0)
        .animation(.spring(response: 0.18, dampingFraction: 0.65), value: isSelected)
        .offset(x: x, y: y)
    }
}
