import Foundation
import Cocoa
import PDFKit
import CoreText
import Vision

public enum PDFTargetFormat: String, Sendable, CaseIterable {
    case pngPages = "PNG (Страницы)"
    case jpgCover = "Обложка JPG"
    case txt = "Текст TXT"
    case markdown = "Markdown"
}

public enum PDFMagicAction: String, Sendable, CaseIterable {
    case compress = "Сжать <5МБ"
    case ocrClipboard = "OCR в буфер"
    case extractImages = "Извлечь фото"
    case splitPages = "Разрезать"
    case rotate90 = "Поворот +90°"
    case pdfInfo = "Инфо о PDF"
}

public enum DataTargetFormat: String, Sendable, CaseIterable {
    case json = "JSON"
    case yaml = "YAML"
    case csv = "CSV"
    case markdownTable = "MD Таблица"
    case plist = "Plist"
}

public enum DataMagicAction: String, Sendable, CaseIterable {
    case prettify = "Форматировать"
    case minify = "В 1 строку"
    case copyToClipboard = "В буфер обмена"
    case csvToMarkdownTableClipboard = "MD-таблица в буфер"
    case validateInfo = "Валидация и инфо"
}

public enum DocTargetFormat: String, Sendable, CaseIterable {
    case pdf = "PDF"
    case html = "HTML"
    case docx = "DOCX"
    case markdown = "Markdown"
    case txt = "TXT"
}

public enum DocMagicAction: String, Sendable, CaseIterable {
    case wordCountInfo = "Статистика слов"
    case cleanText = "Очистить текст"
    case copyCleanText = "Чистый текст в буфер"
    case uppercase = "UPPERCASE"
    case lowercase = "lowercase"
}

public enum PDFOptionAction: String, Sendable, CaseIterable {
    case rotateCW = "+90° Вправо"
    case rotateCCW = "-90° Влево"
    case rotate180 = "180° Перевернуть"
    case extractFirstPage = "Только стр. 1"
    case removeFirstPage = "Удалить стр. 1"
    case cleanZip = "Чистый ZIP"
}

public enum DataOptionAction: String, Sendable, CaseIterable {
    case cleanZip = "Чистый ZIP"
    case sortAZ = "Сортировка A-Z"
    case deduplicate = "Удалить дубли"
    case numberLines = "Нумерация"
    case backupTimestamp = "Резервная копия"
}

public enum PDFCommandAction: String, Sendable, CaseIterable {
    case trimMargins = "Кроп полей"
    case standardizeA4 = "Формат A4"
    case stampCopy = "Штамп: КОПИЯ"
    case stampDraft = "Штамп: DRAFT"
    case mergeFolderPDFs = "Объединить PDF"
}

public enum DataCommandAction: String, Sendable, CaseIterable {
    case head10 = "Топ-10 строк"
    case head100 = "Топ-100 строк"
    case sample10 = "Семпл 10 строк"
    case base64Encode = "Base64 Encode"
    case base64Decode = "Base64 Decode"
}

public final class DocumentProcessor: @unchecked Sendable {
    public static let shared = DocumentProcessor()
    
    private init() {}
    
    // MARK: - PDF Conversions
    
    /// Конвертация PDF документа
    public func convertPDF(url: URL, to target: PDFTargetFormat) throws -> URL {
        guard let doc = PDFDocument(url: url) else {
            throw NSError(domain: "DocumentProcessor", code: 1, userInfo: [NSLocalizedDescriptionKey: "Не удалось открыть PDF документ"])
        }
        if doc.isLocked {
            throw NSError(domain: "DocumentProcessor", code: 2, userInfo: [NSLocalizedDescriptionKey: "PDF защищен паролем. Снимите защиту перед обработкой."])
        }
        
        let baseName = url.deletingPathExtension().lastPathComponent
        
        switch target {
        case .pngPages:
            let pageCount = doc.pageCount
            guard pageCount > 0 else {
                throw NSError(domain: "DocumentProcessor", code: 2, userInfo: [NSLocalizedDescriptionKey: "PDF документ пуст"])
            }
            
            if pageCount == 1 {
                let outURL = FileUtils.uniqueURL(for: url, suffix: "_page_1", extension: "png")
                try renderPage(doc.page(at: 0)!, toPNG: outURL, scale: 2.0)
                return outURL
            } else {
                let outFolder = FileUtils.uniqueFolderURL(for: url, suffix: "_pages")
                try FileManager.default.createDirectory(at: outFolder, withIntermediateDirectories: true)
                for i in 0..<pageCount {
                    try autoreleasepool {
                        if let page = doc.page(at: i) {
                            let pageNum = String(format: "%02d", i + 1)
                            let pageURL = outFolder.appendingPathComponent("page_\(pageNum).png")
                            try renderPage(page, toPNG: pageURL, scale: 2.0)
                        }
                    }
                }
                return outFolder
            }
            
        case .jpgCover:
            guard let firstPage = doc.page(at: 0) else {
                throw NSError(domain: "DocumentProcessor", code: 3, userInfo: [NSLocalizedDescriptionKey: "Нет страниц в PDF"])
            }
            let outURL = FileUtils.uniqueURL(for: url, suffix: "_cover", extension: "jpg")
            try renderPage(firstPage, toJPG: outURL, scale: 2.0)
            return outURL
            
        case .txt:
            var fullText = doc.string?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if fullText.isEmpty {
                fullText = (try? extractOCRText(from: doc, maxPages: 10)) ?? ""
            }
            if fullText.isEmpty {
                fullText = "В документе не найден текстовый слой. Для оптического распознавания сканов используйте ⌃ Control -> OCR в буфер."
            }
            let outURL = FileUtils.uniqueURL(for: url, extension: "txt")
            try fullText.write(to: outURL, atomically: true, encoding: .utf8)
            return outURL
            
        case .markdown:
            var mdContent = "# \(baseName)\n\n"
            var hasText = false
            for i in 0..<doc.pageCount {
                if let page = doc.page(at: i) {
                    let pageText = page.string?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    if !pageText.isEmpty {
                        hasText = true
                        mdContent += "## Страница \(i + 1)\n\n\(pageText)\n\n---\n\n"
                    }
                }
            }
            if !hasText {
                let ocrText = (try? extractOCRText(from: doc, maxPages: 10)) ?? ""
                if !ocrText.isEmpty {
                    mdContent += "## Распознанный текст (OCR)\n\n\(ocrText)\n"
                } else {
                    mdContent += "В документе не найден текстовый слой.\n"
                }
            }
            let outURL = FileUtils.uniqueURL(for: url, extension: "md")
            try mdContent.write(to: outURL, atomically: true, encoding: .utf8)
            return outURL
        }
    }
    
    private func renderPage(_ page: PDFPage, toPNG outURL: URL, scale: CGFloat = 2.0) throws {
        let bounds = page.bounds(for: .mediaBox)
        let size = NSSize(width: bounds.width * scale, height: bounds.height * scale)
        let img = NSImage(size: size, flipped: false) { rect in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
            ctx.setFillColor(CGColor.white)
            ctx.fill(rect)
            ctx.scaleBy(x: scale, y: scale)
            page.draw(with: .mediaBox, to: ctx)
            return true
        }
        guard let tiffData = img.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiffData),
              let pngData = rep.representation(using: .png, properties: [:]) else {
            throw NSError(domain: "DocumentProcessor", code: 4, userInfo: [NSLocalizedDescriptionKey: "Ошибка рендера PNG страницы"])
        }
        try pngData.write(to: outURL)
    }
    
    private func renderPage(_ page: PDFPage, toJPG outURL: URL, scale: CGFloat = 2.0) throws {
        let bounds = page.bounds(for: .mediaBox)
        let size = NSSize(width: bounds.width * scale, height: bounds.height * scale)
        let img = NSImage(size: size, flipped: false) { rect in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
            ctx.setFillColor(CGColor.white)
            ctx.fill(rect)
            ctx.scaleBy(x: scale, y: scale)
            page.draw(with: .mediaBox, to: ctx)
            return true
        }
        guard let tiffData = img.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiffData),
              let jpgData = rep.representation(using: .jpeg, properties: [.compressionFactor: 0.9]) else {
            throw NSError(domain: "DocumentProcessor", code: 5, userInfo: [NSLocalizedDescriptionKey: "Ошибка экспорта обложки JPG"])
        }
        try jpgData.write(to: outURL)
    }
    
    // MARK: - Data Conversions (JSON, YAML, CSV, Plist)
    
    public func convertData(url: URL, to target: DataTargetFormat) throws -> URL {
        let ext = url.pathExtension.lowercased()
        let rawContent = try Self.readText(from: url)
        
        switch target {
        case .json:
            let outURL = FileUtils.uniqueURL(for: url, extension: "json")
            if ext == "csv" {
                let jsonArray = try parseCSVToJSONArray(csvText: rawContent)
                let data = try JSONSerialization.data(withJSONObject: jsonArray, options: [.prettyPrinted, .sortedKeys])
                try data.write(to: outURL)
            } else if ext == "yaml" || ext == "yml" {
                let obj = try parseYAML(yamlText: rawContent)
                let data = try JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted, .sortedKeys])
                try data.write(to: outURL)
            } else if ext == "plist" {
                let data = try Data(contentsOf: url)
                var format = PropertyListSerialization.PropertyListFormat.xml
                let obj = try PropertyListSerialization.propertyList(from: data, options: [], format: &format)
                let jsonData = try JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted, .sortedKeys])
                try jsonData.write(to: outURL)
            } else {
                // Prettify fallback
                let data = rawContent.data(using: .utf8) ?? Data()
                let obj = try JSONSerialization.jsonObject(with: data, options: [])
                let pretty = try JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted, .sortedKeys])
                try pretty.write(to: outURL)
            }
            return outURL
            
        case .yaml:
            let outURL = FileUtils.uniqueURL(for: url, extension: "yaml")
            let rootObject: Any
            if ext == "json" {
                let data = rawContent.data(using: .utf8) ?? Data()
                rootObject = try JSONSerialization.jsonObject(with: data, options: [])
            } else if ext == "csv" {
                rootObject = try parseCSVToJSONArray(csvText: rawContent)
            } else if ext == "plist" {
                let data = try Data(contentsOf: url)
                var format = PropertyListSerialization.PropertyListFormat.xml
                rootObject = try PropertyListSerialization.propertyList(from: data, options: [], format: &format)
            } else {
                rootObject = rawContent
            }
            let yamlString = serializeToYAML(rootObject)
            try yamlString.write(to: outURL, atomically: true, encoding: .utf8)
            return outURL
            
        case .csv:
            let outURL = FileUtils.uniqueURL(for: url, extension: "csv")
            let rootObject: Any
            if ext == "json" {
                let data = rawContent.data(using: .utf8) ?? Data()
                rootObject = try JSONSerialization.jsonObject(with: data, options: [])
            } else if ext == "yaml" || ext == "yml" {
                rootObject = try parseYAML(yamlText: rawContent)
            } else {
                throw NSError(domain: "DocumentProcessor", code: 7, userInfo: [NSLocalizedDescriptionKey: "Неподдерживаемый формат для CSV"])
            }
            let csvText = try serializeToCSV(rootObject)
            try csvText.write(to: outURL, atomically: true, encoding: .utf8)
            return outURL
            
        case .markdownTable:
            let outURL = FileUtils.uniqueURL(for: url, suffix: "_table", extension: "md")
            let mdTable: String
            if ext == "csv" {
                let rows = parseCSVRows(csvText: rawContent)
                mdTable = formatRowsToMarkdownTable(rows)
            } else {
                let obj: Any
                if ext == "json" {
                    let data = rawContent.data(using: .utf8) ?? Data()
                    obj = try JSONSerialization.jsonObject(with: data, options: [])
                } else {
                    obj = try parseYAML(yamlText: rawContent)
                }
                let rows = try convertObjectToRows(obj)
                mdTable = formatRowsToMarkdownTable(rows)
            }
            try mdTable.write(to: outURL, atomically: true, encoding: .utf8)
            return outURL
            
        case .plist:
            let outURL = FileUtils.uniqueURL(for: url, extension: "plist")
            let rootObject: Any
            if ext == "json" {
                let data = rawContent.data(using: .utf8) ?? Data()
                rootObject = try JSONSerialization.jsonObject(with: data, options: [])
            } else if ext == "yaml" || ext == "yml" {
                rootObject = try parseYAML(yamlText: rawContent)
            } else if ext == "csv" {
                rootObject = try parseCSVToJSONArray(csvText: rawContent)
            } else {
                throw NSError(domain: "DocumentProcessor", code: 8, userInfo: [NSLocalizedDescriptionKey: "Невозможно конвертировать в Plist"])
            }
            let plistData = try PropertyListSerialization.data(fromPropertyList: rootObject, format: .xml, options: 0)
            try plistData.write(to: outURL)
            return outURL
        }
    }
    
    // MARK: - Document Conversions (DOCX, Pages, RTF, MD, HTML, TXT)
    
    public func convertDocument(url: URL, to target: DocTargetFormat) throws -> URL {
        let baseName = url.deletingPathExtension().lastPathComponent
        let ext = url.pathExtension.lowercased()
        
        switch target {
        case .pdf:
            let outURL = FileUtils.uniqueURL(for: url, extension: "pdf")
            if ext == "md" || ext == "markdown" {
                let mdText = try Self.readText(from: url)
                let attrString = markdownToAttributedString(mdText)
                try renderAttributedStringToPDF(attrString, toURL: outURL)
            } else if ext == "html" || ext == "htm" {
                let htmlData = try Data(contentsOf: url)
                let attrString = try NSAttributedString(data: htmlData, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil)
                try renderAttributedStringToPDF(attrString, toURL: outURL)
            } else if ext == "pages" {
                // Проверяем встроенный QuickLook/Preview.pdf внутри пакета .pages
                let embeddedPDF = url.appendingPathComponent("QuickLook/Preview.pdf")
                if FileManager.default.fileExists(atPath: embeddedPDF.path) {
                    try? FileManager.default.removeItem(at: outURL)
                    try FileManager.default.copyItem(at: embeddedPDF, to: outURL)
                    return outURL
                }
                // Fallback через NSAttributedString или QuickLook
                let attrString = try NSAttributedString(url: url, options: [:], documentAttributes: nil)
                try renderAttributedStringToPDF(attrString, toURL: outURL)
            } else {
                // docx, rtf, txt
                // Если это DOCX/DOC и установлен Microsoft Word, используем нативный экспорт с полным сохранением картинок и разметки
                if (ext == "docx" || ext == "doc") {
                    if let _ = try? exportWordViaAppleScript(url: url, toURL: outURL) {
                        return outURL
                    }
                }
                let attrString = try NSAttributedString(url: url, options: [:], documentAttributes: nil)
                try renderAttributedStringToPDF(attrString, toURL: outURL)
            }
            return outURL
            
        case .html:
            let outURL = FileUtils.uniqueURL(for: url, extension: "html")
            if ext == "md" || ext == "markdown" {
                let mdText = try Self.readText(from: url)
                let html = markdownToHTML(mdText, title: baseName)
                try html.write(to: outURL, atomically: true, encoding: .utf8)
            } else if ext == "docx" || ext == "doc" || ext == "rtf" {
                // Используем системный /usr/bin/textutil
                let result = try ProcessRunner.run(executable: "/usr/bin/textutil", arguments: ["-convert", "html", url.path, "-output", outURL.path])
                if !result.isSuccess {
                    throw NSError(domain: "DocumentProcessor", code: 9, userInfo: [NSLocalizedDescriptionKey: "Ошибка textutil при конвертации в HTML: \(result.stderrString)"])
                }
            } else {
                let plainText = try Self.readText(from: url)
                let html = "<html><head><meta charset=\"utf-8\"><title>\(baseName)</title><style>body { font-family: -apple-system, sans-serif; padding: 40px; line-height: 1.6; max-width: 800px; margin: auto; white-space: pre-wrap; }</style></head><body>\(plainText)</body></html>"
                try html.write(to: outURL, atomically: true, encoding: .utf8)
            }
            return outURL
            
        case .docx:
            let outURL = FileUtils.uniqueURL(for: url, extension: "docx")
            let result = try ProcessRunner.run(executable: "/usr/bin/textutil", arguments: ["-convert", "docx", url.path, "-output", outURL.path])
            if !result.isSuccess {
                throw NSError(domain: "DocumentProcessor", code: 10, userInfo: [NSLocalizedDescriptionKey: "Ошибка textutil при экспорте в DOCX: \(result.stderrString)"])
            }
            return outURL
            
        case .markdown:
            let outURL = FileUtils.uniqueURL(for: url, extension: "md")
            if ext == "html" || ext == "htm" {
                let htmlText = try Self.readText(from: url)
                let md = htmlToMarkdown(htmlText)
                try md.write(to: outURL, atomically: true, encoding: .utf8)
            } else if ext == "docx" || ext == "rtf" {
                let attrString = try NSAttributedString(url: url, options: [:], documentAttributes: nil)
                let plain = attrString.string
                try "# \(baseName)\n\n\(plain)".write(to: outURL, atomically: true, encoding: .utf8)
            } else {
                let text = try Self.readText(from: url)
                try text.write(to: outURL, atomically: true, encoding: .utf8)
            }
            return outURL
            
        case .txt:
            let outURL = FileUtils.uniqueURL(for: url, extension: "txt")
            if ext == "docx" || ext == "rtf" || ext == "html" {
                let attrString = try NSAttributedString(url: url, options: [:], documentAttributes: nil)
                try attrString.string.write(to: outURL, atomically: true, encoding: .utf8)
            } else {
                let text = try String(contentsOf: url, encoding: .utf8)
                try text.write(to: outURL, atomically: true, encoding: .utf8)
            }
            return outURL
        }
    }
    
    // MARK: - CoreText PDF Rendering Engine
    
    private func renderAttributedStringToPDF(_ attrString: NSAttributedString, toURL: URL) throws {
        // Стандартный A4: 595.2 x 841.8 pt
        var pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8)
        let marginX: CGFloat = 50.0
        let marginY: CGFloat = 54.0
        let textRect = CGRect(
            x: marginX,
            y: marginY,
            width: pageRect.width - marginX * 2,
            height: pageRect.height - marginY * 2
        )
        
        let pdfData = NSMutableData()
        guard let consumer = CGDataConsumer(data: pdfData as CFMutableData),
              let context = CGContext(consumer: consumer, mediaBox: &pageRect, nil) else {
            throw NSError(domain: "DocumentProcessor", code: 11, userInfo: [NSLocalizedDescriptionKey: "Ошибка создания PDF-контекста"])
        }
        
        let framesetter = CTFramesetterCreateWithAttributedString(attrString as CFAttributedString)
        var currentIndex = 0
        let totalLength = attrString.length
        
        while currentIndex < totalLength {
            context.beginPage(mediaBox: &pageRect)
            
            // В CoreText начало координат в левом нижнем углу
            let path = CGPath(rect: textRect, transform: nil)
            let frame = CTFramesetterCreateFrame(framesetter, CFRange(location: currentIndex, length: 0), path, nil)
            
            context.saveGState()
            CTFrameDraw(frame, context)
            context.restoreGState()
            
            let frameRange = CTFrameGetVisibleStringRange(frame)
            if frameRange.length == 0 {
                context.endPage()
                break
            }
            currentIndex += frameRange.length
            context.endPage()
        }
        
        context.closePDF()
        try pdfData.write(to: toURL)
    }
    
    private func exportWordViaAppleScript(url: URL, toURL: URL) throws {
        // Вызываем Word только если он уже запущен пользователем, чтобы не блокировать процесс холодным стартом
        guard let wordApp = NSRunningApplication.runningApplications(withBundleIdentifier: "com.microsoft.Word").first,
              !wordApp.isTerminated else {
            throw NSError(domain: "DocumentProcessor", code: 404, userInfo: [NSLocalizedDescriptionKey: "Word не запущен"])
        }
        
        let scriptSource = """
        with timeout of 3 seconds
            tell application "Microsoft Word"
                set prevAlerts to display alerts
                set display alerts to none
                try
                    set doc to open file name "\(url.path)" without dialogs
                    save as doc file name "\(toURL.path)" file format format PDF
                    close doc saving no
                    set display alerts to prevAlerts
                    return "OK"
                on error errMsg
                    set display alerts to prevAlerts
                    error errMsg
                end try
            end tell
        end timeout
        """
        
        var error: NSDictionary?
        guard let script = NSAppleScript(source: scriptSource) else {
            throw NSError(domain: "DocumentProcessor", code: 1, userInfo: [NSLocalizedDescriptionKey: "Ошибка создания скрипта Word"])
        }
        _ = script.executeAndReturnError(&error)
        if let err = error {
            throw NSError(domain: "DocumentProcessor", code: 2, userInfo: [NSLocalizedDescriptionKey: "Word AppleScript error: \(err)"])
        }
        guard FileManager.default.fileExists(atPath: toURL.path) else {
            throw NSError(domain: "DocumentProcessor", code: 3, userInfo: [NSLocalizedDescriptionKey: "Word не создал PDF-файл"])
        }
    }
    
    // MARK: - CSV Engine
    
    public static func readText(from url: URL) throws -> String {
        if let utf8 = try? String(contentsOf: url, encoding: .utf8) {
            return utf8
        }
        let cp1251Encoding = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.windowsCyrillic.rawValue)))
        if let win1251 = try? String(contentsOf: url, encoding: cp1251Encoding) {
            return win1251
        }
        if let latin1 = try? String(contentsOf: url, encoding: .isoLatin1) {
            return latin1
        }
        return try String(contentsOf: url)
    }
    
    public func detectCSVDelimiter(csvText: String) -> Character {
        let sample = csvText.components(separatedBy: .newlines).prefix(5).joined(separator: "\n")
        var commaCount = 0
        var semicolonCount = 0
        var tabCount = 0
        var inQuotes = false
        
        for ch in sample {
            if ch == "\"" {
                inQuotes.toggle()
            } else if !inQuotes {
                if ch == "," { commaCount += 1 }
                else if ch == ";" { semicolonCount += 1 }
                else if ch == "\t" { tabCount += 1 }
            }
        }
        
        if semicolonCount > commaCount && semicolonCount >= tabCount {
            return ";"
        } else if tabCount > commaCount && tabCount > semicolonCount {
            return "\t"
        } else {
            return ","
        }
    }
    
    public func parseCSVRows(csvText: String) -> [[String]] {
        let delimiter = detectCSVDelimiter(csvText: csvText)
        var rows: [[String]] = []
        var currentRow: [String] = []
        var currentField = ""
        var insideQuotes = false
        
        let characters = Array(csvText)
        var i = 0
        while i < characters.count {
            let char = characters[i]
            
            if char == "\"" {
                if insideQuotes && i + 1 < characters.count && characters[i + 1] == "\"" {
                    currentField.append("\"")
                    i += 1
                } else {
                    insideQuotes.toggle()
                }
            } else if char == delimiter && !insideQuotes {
                currentRow.append(currentField.trimmingCharacters(in: .whitespaces))
                currentField = ""
            } else if (char == "\n" || char == "\r") && !insideQuotes {
                if char == "\r" && i + 1 < characters.count && characters[i + 1] == "\n" {
                    i += 1
                }
                currentRow.append(currentField.trimmingCharacters(in: .whitespaces))
                if !currentRow.allSatisfy({ $0.isEmpty }) {
                    rows.append(currentRow)
                }
                currentRow = []
                currentField = ""
            } else {
                currentField.append(char)
            }
            i += 1
        }
        
        if !currentField.isEmpty || !currentRow.isEmpty {
            currentRow.append(currentField.trimmingCharacters(in: .whitespaces))
            if !currentRow.allSatisfy({ $0.isEmpty }) {
                rows.append(currentRow)
            }
        }
        
        return rows
    }
    
    public func parseCSVToJSONArray(csvText: String) throws -> [[String: Any]] {
        let rows = parseCSVRows(csvText: csvText)
        guard rows.count >= 2 else {
            if rows.count == 1 {
                return [[:]]
            }
            throw NSError(domain: "DocumentProcessor", code: 12, userInfo: [NSLocalizedDescriptionKey: "CSV пуст или не содержит данных"])
        }
        
        let headers = rows[0]
        var result: [[String: Any]] = []
        
        for rowIndex in 1..<rows.count {
            let row = rows[rowIndex]
            var dict: [String: Any] = [:]
            for (colIndex, header) in headers.enumerated() {
                let value = colIndex < row.count ? row[colIndex] : ""
                // Приводим числа и булевы значения
                if let intVal = Int(value) {
                    dict[header] = intVal
                } else if let doubleVal = Double(value), value.contains(".") {
                    dict[header] = doubleVal
                } else if value.lowercased() == "true" {
                    dict[header] = true
                } else if value.lowercased() == "false" {
                    dict[header] = false
                } else {
                    dict[header] = value
                }
            }
            result.append(dict)
        }
        
        return result
    }
    
    public func serializeToCSV(_ object: Any) throws -> String {
        let array: [[String: Any]]
        if let directArray = object as? [[String: Any]] {
            array = directArray
        } else if let dict = object as? [String: Any] {
            // Ищем первый вложенный массив
            if let firstArray = dict.values.first(where: { $0 is [[String: Any]] }) as? [[String: Any]] {
                array = firstArray
            } else {
                array = [dict]
            }
        } else {
            throw NSError(domain: "DocumentProcessor", code: 13, userInfo: [NSLocalizedDescriptionKey: "Объект невозможно преобразовать в CSV-таблицу"])
        }
        
        guard let first = array.first else { return "" }
        let headers = Array(first.keys).sorted()
        
        var lines: [String] = []
        lines.append(headers.map { escapeCSVField($0) }.joined(separator: ","))
        
        for item in array {
            let row = headers.map { key -> String in
                if let val = item[key] {
                    return escapeCSVField("\(val)")
                }
                return ""
            }
            lines.append(row.joined(separator: ","))
        }
        
        return lines.joined(separator: "\n")
    }
    
    private func escapeCSVField(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return field
    }
    
    public func formatRowsToMarkdownTable(_ rows: [[String]]) -> String {
        guard let headers = rows.first, !headers.isEmpty else { return "" }
        
        var lines: [String] = []
        lines.append("| " + headers.joined(separator: " | ") + " |")
        lines.append("| " + headers.map { _ in ":---" }.joined(separator: " | ") + " |")
        
        for row in rows.dropFirst() {
            var padded = row
            while padded.count < headers.count {
                padded.append("")
            }
            lines.append("| " + padded.prefix(headers.count).joined(separator: " | ") + " |")
        }
        
        return lines.joined(separator: "\n")
    }
    
    private func convertObjectToRows(_ object: Any) throws -> [[String]] {
        if let array = object as? [[String: Any]], let first = array.first {
            let headers = Array(first.keys).sorted()
            var rows: [[String]] = [headers]
            for item in array {
                let row = headers.map { "\($0): \(item[$0] ?? "")" }
                rows.append(row)
            }
            return rows
        } else if let dict = object as? [String: Any] {
            var rows: [[String]] = [["Ключ", "Значение"]]
            for (key, val) in dict.sorted(by: { $0.key < $1.key }) {
                rows.append([key, "\(val)"])
            }
            return rows
        }
        return [["Значение"], ["\(object)"]]
    }
    
    // MARK: - YAML Serializer & Simple Parser
    
    public func serializeToYAML(_ object: Any, indentLevel: Int = 0) -> String {
        let indent = String(repeating: "  ", count: indentLevel)
        
        if let dict = object as? [String: Any] {
            if dict.isEmpty { return "{}\n" }
            var result = ""
            for (key, value) in dict.sorted(by: { $0.key < $1.key }) {
                if let childDict = value as? [String: Any] {
                    result += "\(indent)\(key):\n\(serializeToYAML(childDict, indentLevel: indentLevel + 1))"
                } else if let childArray = value as? [Any] {
                    result += "\(indent)\(key):\n\(serializeToYAML(childArray, indentLevel: indentLevel + 1))"
                } else {
                    let formattedVal = formatYAMLValue(value)
                    result += "\(indent)\(key): \(formattedVal)\n"
                }
            }
            return result
        } else if let array = object as? [Any] {
            if array.isEmpty { return "[]\n" }
            var result = ""
            for item in array {
                if let childDict = item as? [String: Any] {
                    result += "\(indent)- \n\(serializeToYAML(childDict, indentLevel: indentLevel + 1))"
                } else if let childArray = item as? [Any] {
                    result += "\(indent)- \n\(serializeToYAML(childArray, indentLevel: indentLevel + 1))"
                } else {
                    let formattedVal = formatYAMLValue(item)
                    result += "\(indent)- \(formattedVal)\n"
                }
            }
            return result
        } else {
            return "\(indent)\(formatYAMLValue(object))\n"
        }
    }
    
    private func formatYAMLValue(_ val: Any) -> String {
        if let boolVal = val as? Bool {
            return boolVal ? "true" : "false"
        } else if let num = val as? NSNumber {
            return "\(num)"
        } else if let str = val as? String {
            if str.contains(":") || str.contains("#") || str.contains("\n") || str.contains("\"") || str.hasPrefix("-") {
                let escaped = str.replacingOccurrences(of: "\"", with: "\\\"")
                return "\"\(escaped)\""
            }
            return str
        }
        return "\(val)"
    }
    
    public func parseYAML(yamlText: String) throws -> [String: Any] {
        // Парсим построчно стандартные YAML key-value пары
        var dict: [String: Any] = [:]
        let lines = yamlText.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }
            
            if let colonIdx = trimmed.firstIndex(of: ":") {
                let key = String(trimmed[..<colonIdx]).trimmingCharacters(in: .whitespaces)
                var valueStr = String(trimmed[trimmed.index(after: colonIdx)...]).trimmingCharacters(in: .whitespaces)
                
                if (valueStr.hasPrefix("\"") && valueStr.hasSuffix("\"")) || (valueStr.hasPrefix("'") && valueStr.hasSuffix("'")) {
                    valueStr.removeFirst()
                    valueStr.removeLast()
                }
                
                if let intVal = Int(valueStr) {
                    dict[key] = intVal
                } else if let doubleVal = Double(valueStr), valueStr.contains(".") {
                    dict[key] = doubleVal
                } else if valueStr.lowercased() == "true" {
                    dict[key] = true
                } else if valueStr.lowercased() == "false" {
                    dict[key] = false
                } else if !valueStr.isEmpty {
                    dict[key] = valueStr
                }
            }
        }
        
        return dict
    }
    
    // MARK: - Markdown & HTML Helpers
    
    private func markdownToAttributedString(_ md: String) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let lines = md.components(separatedBy: .newlines)
        
        let normalFont = NSFont.systemFont(ofSize: 13)
        let h1Font = NSFont.boldSystemFont(ofSize: 22)
        let h2Font = NSFont.boldSystemFont(ofSize: 17)
        let h3Font = NSFont.boldSystemFont(ofSize: 15)
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("# ") {
                let text = String(trimmed.dropFirst(2)) + "\n\n"
                result.append(NSAttributedString(string: text, attributes: [.font: h1Font, .foregroundColor: NSColor.labelColor]))
            } else if trimmed.hasPrefix("## ") {
                let text = String(trimmed.dropFirst(3)) + "\n\n"
                result.append(NSAttributedString(string: text, attributes: [.font: h2Font, .foregroundColor: NSColor.labelColor]))
            } else if trimmed.hasPrefix("### ") {
                let text = String(trimmed.dropFirst(4)) + "\n\n"
                result.append(NSAttributedString(string: text, attributes: [.font: h3Font, .foregroundColor: NSColor.labelColor]))
            } else if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
                let text = "  •  " + String(trimmed.dropFirst(2)) + "\n"
                result.append(NSAttributedString(string: text, attributes: [.font: normalFont, .foregroundColor: NSColor.labelColor]))
            } else if trimmed.isEmpty {
                result.append(NSAttributedString(string: "\n", attributes: [.font: normalFont]))
            } else {
                result.append(NSAttributedString(string: line + "\n", attributes: [.font: normalFont, .foregroundColor: NSColor.labelColor]))
            }
        }
        
        return result
    }
    
    private func markdownToHTML(_ md: String, title: String) -> String {
        var body = ""
        let lines = md.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("# ") {
                body += "<h1>\(escapeHTML(String(trimmed.dropFirst(2))))</h1>\n"
            } else if trimmed.hasPrefix("## ") {
                body += "<h2>\(escapeHTML(String(trimmed.dropFirst(3))))</h2>\n"
            } else if trimmed.hasPrefix("### ") {
                body += "<h3>\(escapeHTML(String(trimmed.dropFirst(4))))</h3>\n"
            } else if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
                body += "<li>\(escapeHTML(String(trimmed.dropFirst(2))))</li>\n"
            } else if trimmed.isEmpty {
                body += "<br/>\n"
            } else {
                body += "<p>\(escapeHTML(line))</p>\n"
            }
        }
        
        return """
        <!DOCTYPE html>
        <html lang="ru">
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>\(title)</title>
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
                    line-height: 1.6;
                    color: #24292e;
                    background: #ffffff;
                    max-width: 780px;
                    margin: 40px auto;
                    padding: 0 24px;
                }
                h1, h2, h3 { font-weight: 600; color: #111; margin-top: 1.5em; margin-bottom: 0.5em; }
                h1 { font-size: 2em; border-bottom: 1px solid #eaecef; padding-bottom: 0.3em; }
                h2 { font-size: 1.5em; border-bottom: 1px solid #eaecef; padding-bottom: 0.3em; }
                p { margin: 0.8em 0; }
                li { margin-left: 20px; }
            </style>
        </head>
        <body>
        \(body)
        </body>
        </html>
        """
    }
    
    private func htmlToMarkdown(_ html: String) -> String {
        var text = html
        text = text.replacingOccurrences(of: "<h1[^>]*>(.*?)</h1>", with: "# $1\n\n", options: .regularExpression)
        text = text.replacingOccurrences(of: "<h2[^>]*>(.*?)</h2>", with: "## $1\n\n", options: .regularExpression)
        text = text.replacingOccurrences(of: "<h3[^>]*>(.*?)</h3>", with: "### $1\n\n", options: .regularExpression)
        text = text.replacingOccurrences(of: "<p[^>]*>(.*?)</p>", with: "$1\n\n", options: .regularExpression)
        text = text.replacingOccurrences(of: "<li[^>]*>(.*?)</li>", with: "- $1\n", options: .regularExpression)
        text = text.replacingOccurrences(of: "<br/?>", with: "\n", options: .regularExpression)
        text = text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func escapeHTML(_ str: String) -> String {
        return str
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }
    
    // MARK: - OCR Helper
    
    private func extractOCRText(from doc: PDFDocument, maxPages: Int = 10) throws -> String {
        var fullText = ""
        let limit = min(doc.pageCount, maxPages)
        for i in 0..<limit {
            guard let page = doc.page(at: i) else { continue }
            let bounds = page.bounds(for: .mediaBox)
            let scale: CGFloat = 2.0
            let size = NSSize(width: bounds.width * scale, height: bounds.height * scale)
            let img = NSImage(size: size, flipped: false) { rect in
                guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
                ctx.setFillColor(CGColor.white)
                ctx.fill(rect)
                ctx.scaleBy(x: scale, y: scale)
                page.draw(with: .mediaBox, to: ctx)
                return true
            }
            if let cgImg = img.cgImage(forProposedRect: nil, context: nil, hints: nil) {
                let request = VNRecognizeTextRequest()
                request.recognitionLevel = .accurate
                request.recognitionLanguages = ["ru-RU", "en-US"]
                let handler = VNImageRequestHandler(cgImage: cgImg, options: [:])
                try handler.perform([request])
                if let results = request.results {
                    let pageText = results.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
                    if !pageText.isEmpty {
                        fullText += pageText + "\n\n"
                    }
                }
            }
        }
        return fullText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - PDF Magic Actions
    
    public func executePDFMagicAction(_ action: PDFMagicAction, on url: URL) async throws -> (URL?, DocumentMetadata?) {
        guard let doc = PDFDocument(url: url) else {
            throw NSError(domain: "DocumentProcessor", code: 20, userInfo: [NSLocalizedDescriptionKey: "Не удалось открыть PDF документ"])
        }
        if doc.isLocked {
            throw NSError(domain: "DocumentProcessor", code: 21, userInfo: [NSLocalizedDescriptionKey: "PDF защищен паролем. Снимите защиту перед обработкой."])
        }
        
        switch action {
        case .compress:
            let outURL = FileUtils.uniqueURL(for: url, suffix: "_compressed", extension: "pdf")
            let newDoc = PDFDocument()
            for i in 0..<doc.pageCount {
                guard let page = doc.page(at: i) else { continue }
                let bounds = page.bounds(for: .mediaBox)
                let scale: CGFloat = 1.6
                let size = NSSize(width: bounds.width * scale, height: bounds.height * scale)
                let img = NSImage(size: size, flipped: false) { rect in
                    guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
                    ctx.setFillColor(CGColor.white)
                    ctx.fill(rect)
                    ctx.scaleBy(x: scale, y: scale)
                    page.draw(with: .mediaBox, to: ctx)
                    return true
                }
                guard let tiff = img.tiffRepresentation,
                      let rep = NSBitmapImageRep(data: tiff),
                      let jpegData = rep.representation(using: .jpeg, properties: [.compressionFactor: 0.65]),
                      let compressedImg = NSImage(data: jpegData),
                      let compressedPage = PDFPage(image: compressedImg) else {
                    continue
                }
                newDoc.insert(compressedPage, at: newDoc.pageCount)
            }
            newDoc.write(to: outURL)
            return (outURL, nil)
            
        case .ocrClipboard:
            var fullText = (try? extractOCRText(from: doc, maxPages: 15)) ?? ""
            if fullText.isEmpty {
                fullText = doc.string ?? ""
            }
            let textToCopy = fullText
            await MainActor.run {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(textToCopy, forType: .string)
            }
            return (nil, nil)
            
        case .extractImages:
            let outFolder = FileUtils.uniqueFolderURL(for: url, suffix: "_images")
            try FileManager.default.createDirectory(at: outFolder, withIntermediateDirectories: true)
            var extractedCount = 0
            for i in 0..<doc.pageCount {
                guard let page = doc.page(at: i) else { continue }
                let bounds = page.bounds(for: .mediaBox)
                let scale: CGFloat = 2.0
                let size = NSSize(width: bounds.width * scale, height: bounds.height * scale)
                let img = NSImage(size: size, flipped: false) { rect in
                    guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
                    ctx.setFillColor(CGColor.white)
                    ctx.fill(rect)
                    ctx.scaleBy(x: scale, y: scale)
                    page.draw(with: .mediaBox, to: ctx)
                    return true
                }
                if let tiff = img.tiffRepresentation,
                   let rep = NSBitmapImageRep(data: tiff),
                   let png = rep.representation(using: .png, properties: [:]) {
                    extractedCount += 1
                    let imgURL = outFolder.appendingPathComponent("image_\(String(format: "%02d", extractedCount)).png")
                    try png.write(to: imgURL)
                }
            }
            return (outFolder, nil)
            
        case .splitPages:
            let outFolder = FileUtils.uniqueFolderURL(for: url, suffix: "_split")
            try FileManager.default.createDirectory(at: outFolder, withIntermediateDirectories: true)
            for i in 0..<doc.pageCount {
                guard let page = doc.page(at: i) else { continue }
                let singlePageDoc = PDFDocument()
                singlePageDoc.insert(page, at: 0)
                let pageURL = outFolder.appendingPathComponent("page_\(String(format: "%02d", i + 1)).pdf")
                singlePageDoc.write(to: pageURL)
            }
            return (outFolder, nil)
            
        case .rotate90:
            let outURL = FileUtils.uniqueURL(for: url, suffix: "_rotated", extension: "pdf")
            let copyDoc = PDFDocument(url: url) ?? doc
            for i in 0..<copyDoc.pageCount {
                if let page = copyDoc.page(at: i) {
                    page.rotation = (page.rotation + 90) % 360
                }
            }
            copyDoc.write(to: outURL)
            return (outURL, nil)
            
        case .pdfInfo:
            let attrs = try FileManager.default.attributesOfItem(atPath: url.path)
            let sizeBytes = attrs[.size] as? Int64 ?? 0
            let sizeMB = Double(sizeBytes) / (1024 * 1024)
            let sizeStr = sizeMB >= 1.0 ? String(format: "%.1f MB", sizeMB) : "\(sizeBytes / 1024) KB"
            
            let hasText = !(doc.string?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
            let isEncrypted = doc.isEncrypted
            
            var note = ""
            if let firstPage = doc.page(at: 0) {
                let bounds = firstPage.bounds(for: .mediaBox)
                let w = Int(bounds.width)
                let h = Int(bounds.height)
                note = "Размер страницы: \(w) × \(h) pt"
            }
            
            let words = hasText ? doc.string?.components(separatedBy: .whitespacesAndNewlines).filter({ !$0.isEmpty }).count : nil
            let meta = DocumentMetadata(
                fileName: url.lastPathComponent,
                fileSizeString: sizeStr,
                formatName: "PDF Документ",
                icon: "doc.richtext.fill",
                pageCount: doc.pageCount,
                wordCount: words,
                charCount: doc.string?.count,
                linesCount: nil,
                readingTimeMinutes: nil,
                isEncrypted: isEncrypted,
                hasTextLayer: hasText,
                syntaxValid: nil,
                note: note
            )
            return (nil, meta)
        }
    }
    
    // MARK: - Data Magic Actions
    
    public func executeDataMagicAction(_ action: DataMagicAction, on url: URL) throws -> (URL?, DocumentMetadata?) {
        let ext = url.pathExtension.lowercased()
        let rawContent = try Self.readText(from: url)
        
        switch action {
        case .prettify:
            let outURL = FileUtils.uniqueURL(for: url, suffix: "_pretty", extension: ext)
            if ext == "json" {
                let data = rawContent.data(using: .utf8) ?? Data()
                let obj = try JSONSerialization.jsonObject(with: data, options: [])
                let prettyData = try JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted, .sortedKeys])
                try prettyData.write(to: outURL)
            } else if ext == "yaml" || ext == "yml" {
                let obj = try parseYAML(yamlText: rawContent)
                let yamlStr = serializeToYAML(obj)
                try yamlStr.write(to: outURL, atomically: true, encoding: .utf8)
            } else if ext == "csv" {
                let rows = parseCSVRows(csvText: rawContent)
                let md = formatRowsToMarkdownTable(rows)
                try md.write(to: outURL, atomically: true, encoding: .utf8)
            } else {
                try rawContent.write(to: outURL, atomically: true, encoding: .utf8)
            }
            return (outURL, nil)
            
        case .minify:
            let outURL = FileUtils.uniqueURL(for: url, suffix: "_min", extension: ext)
            if ext == "json" {
                let data = rawContent.data(using: .utf8) ?? Data()
                let obj = try JSONSerialization.jsonObject(with: data, options: [])
                let minData = try JSONSerialization.data(withJSONObject: obj, options: [.sortedKeys])
                try minData.write(to: outURL)
            } else {
                let lines = rawContent.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                let minText = lines.joined(separator: "")
                try minText.write(to: outURL, atomically: true, encoding: .utf8)
            }
            return (outURL, nil)
            
        case .copyToClipboard:
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(rawContent, forType: .string)
            return (nil, nil)
            
        case .csvToMarkdownTableClipboard:
            let rows: [[String]]
            if ext == "csv" {
                rows = parseCSVRows(csvText: rawContent)
            } else {
                let obj = try JSONSerialization.jsonObject(with: rawContent.data(using: .utf8) ?? Data(), options: [])
                rows = try convertObjectToRows(obj)
            }
            let mdTable = formatRowsToMarkdownTable(rows)
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(mdTable, forType: .string)
            return (nil, nil)
            
        case .validateInfo:
            let attrs = try FileManager.default.attributesOfItem(atPath: url.path)
            let sizeBytes = attrs[.size] as? Int64 ?? 0
            let sizeStr = sizeBytes >= 1024 * 1024 ? String(format: "%.1f MB", Double(sizeBytes) / (1024 * 1024)) : "\(sizeBytes) байт"
            
            var isValid = true
            var note = "Синтаксис корректен"
            
            if ext == "json" {
                do {
                    let obj = try JSONSerialization.jsonObject(with: rawContent.data(using: .utf8) ?? Data(), options: [])
                    if let dict = obj as? [String: Any] {
                        note = "\(dict.count) ключей верхнего уровня"
                    } else if let arr = obj as? [Any] {
                        note = "\(arr.count) элементов массива"
                    }
                } catch {
                    isValid = false
                    note = "Синтаксическая ошибка JSON"
                }
            } else if ext == "csv" {
                let rows = parseCSVRows(csvText: rawContent)
                let count = max(0, rows.count - 1)
                note = "\(count) записей в таблице"
            } else if ext == "yaml" || ext == "yml" {
                do {
                    let obj = try parseYAML(yamlText: rawContent)
                    note = "\(obj.count) параметров"
                } catch {
                    isValid = false
                    note = "Ошибка парсинга YAML"
                }
            }
            
            let lines = rawContent.components(separatedBy: .newlines).count
            let meta = DocumentMetadata(
                fileName: url.lastPathComponent,
                fileSizeString: sizeStr,
                formatName: ext.uppercased(),
                icon: "curlybraces",
                pageCount: nil,
                wordCount: nil,
                charCount: rawContent.count,
                linesCount: lines,
                readingTimeMinutes: nil,
                isEncrypted: nil,
                hasTextLayer: nil,
                syntaxValid: isValid,
                note: note
            )
            return (nil, meta)
        }
    }
    
    // MARK: - Document Magic Actions
    
    public func executeDocMagicAction(_ action: DocMagicAction, on url: URL) throws -> (URL?, DocumentMetadata?) {
        let ext = url.pathExtension.lowercased()
        
        let textContent: String
        if ext == "docx" || ext == "rtf" {
            let attr = try NSAttributedString(url: url, options: [:], documentAttributes: nil)
            textContent = attr.string
        } else {
            textContent = try Self.readText(from: url)
        }
        
        switch action {
        case .wordCountInfo:
            let attrs = try FileManager.default.attributesOfItem(atPath: url.path)
            let sizeBytes = attrs[.size] as? Int64 ?? 0
            let sizeStr = sizeBytes >= 1024 * 1024 ? String(format: "%.1f MB", Double(sizeBytes) / (1024 * 1024)) : "\(sizeBytes) байт"
            
            let words = textContent.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
            let lines = textContent.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            let readingTime = Double(words.count) / 200.0
            
            let meta = DocumentMetadata(
                fileName: url.lastPathComponent,
                fileSizeString: sizeStr,
                formatName: ext.uppercased(),
                icon: "doc.text.fill",
                pageCount: nil,
                wordCount: words.count,
                charCount: textContent.count,
                linesCount: lines.count,
                readingTimeMinutes: readingTime,
                isEncrypted: nil,
                hasTextLayer: true,
                syntaxValid: nil,
                note: "Скорость чтения: ~200 сл/мин"
            )
            return (nil, meta)
            
        case .cleanText:
            let outURL = FileUtils.uniqueURL(for: url, suffix: "_clean", extension: ext)
            let lines = textContent.components(separatedBy: .newlines)
            var cleanedLines: [String] = []
            var lastWasEmpty = false
            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.isEmpty {
                    if !lastWasEmpty {
                        cleanedLines.append("")
                        lastWasEmpty = true
                    }
                } else {
                    cleanedLines.append(line.replacingOccurrences(of: "\\s+$", with: "", options: .regularExpression))
                    lastWasEmpty = false
                }
            }
            let cleaned = cleanedLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines) + "\n"
            try cleaned.write(to: outURL, atomically: true, encoding: .utf8)
            return (outURL, nil)
            
        case .copyCleanText:
            let plain = textContent.trimmingCharacters(in: .whitespacesAndNewlines)
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(plain, forType: .string)
            return (nil, nil)
            
        case .uppercase:
            let outURL = FileUtils.uniqueURL(for: url, suffix: "_UPPER", extension: ext)
            try textContent.uppercased().write(to: outURL, atomically: true, encoding: .utf8)
            return (outURL, nil)
            
        case .lowercase:
            let outURL = FileUtils.uniqueURL(for: url, suffix: "_lower", extension: ext)
            try textContent.lowercased().write(to: outURL, atomically: true, encoding: .utf8)
            return (outURL, nil)
        }
    }
    
    // MARK: - Option & Command Actions (PDF)
    
    public func executePDFOptionAction(_ action: PDFOptionAction, on url: URL) throws -> URL {
        guard let doc = PDFDocument(url: url) else {
            throw NSError(domain: "DocumentProcessor", code: 30, userInfo: [NSLocalizedDescriptionKey: "Не удалось открыть PDF"])
        }
        if doc.isLocked {
            throw NSError(domain: "DocumentProcessor", code: 31, userInfo: [NSLocalizedDescriptionKey: "PDF защищен паролем. Снимите защиту перед обработкой."])
        }
        
        switch action {
        case .rotateCW:
            let outURL = FileUtils.uniqueURL(for: url, suffix: "_cw", extension: "pdf")
            let copy = PDFDocument(url: url) ?? doc
            for i in 0..<copy.pageCount {
                if let page = copy.page(at: i) {
                    page.rotation = (page.rotation + 90) % 360
                }
            }
            copy.write(to: outURL)
            return outURL
            
        case .rotateCCW:
            let outURL = FileUtils.uniqueURL(for: url, suffix: "_ccw", extension: "pdf")
            let copy = PDFDocument(url: url) ?? doc
            for i in 0..<copy.pageCount {
                if let page = copy.page(at: i) {
                    page.rotation = (page.rotation + 270) % 360
                }
            }
            copy.write(to: outURL)
            return outURL
            
        case .rotate180:
            let outURL = FileUtils.uniqueURL(for: url, suffix: "_180", extension: "pdf")
            let copy = PDFDocument(url: url) ?? doc
            for i in 0..<copy.pageCount {
                if let page = copy.page(at: i) {
                    page.rotation = (page.rotation + 180) % 360
                }
            }
            copy.write(to: outURL)
            return outURL
            
        case .extractFirstPage:
            guard let first = doc.page(at: 0) else {
                throw NSError(domain: "DocumentProcessor", code: 31, userInfo: [NSLocalizedDescriptionKey: "PDF пуст"])
            }
            let outURL = FileUtils.uniqueURL(for: url, suffix: "_page1", extension: "pdf")
            let single = PDFDocument()
            single.insert(first, at: 0)
            single.write(to: outURL)
            return outURL
            
        case .removeFirstPage:
            guard doc.pageCount > 1 else {
                throw NSError(domain: "DocumentProcessor", code: 32, userInfo: [NSLocalizedDescriptionKey: "В документе всего 1 страница, невозможно удалить"])
            }
            let outURL = FileUtils.uniqueURL(for: url, suffix: "_no_cover", extension: "pdf")
            let copy = PDFDocument(url: url) ?? doc
            copy.removePage(at: 0)
            copy.write(to: outURL)
            return outURL
            
        case .cleanZip:
            return try createCleanZip(for: url)
        }
    }
    
    public func executePDFCommandAction(_ action: PDFCommandAction, on url: URL) throws -> URL {
        guard let doc = PDFDocument(url: url) else {
            throw NSError(domain: "DocumentProcessor", code: 40, userInfo: [NSLocalizedDescriptionKey: "Не удалось открыть PDF"])
        }
        if doc.isLocked {
            throw NSError(domain: "DocumentProcessor", code: 41, userInfo: [NSLocalizedDescriptionKey: "PDF защищен паролем. Снимите защиту перед обработкой."])
        }
        let folder = url.deletingLastPathComponent()
        
        switch action {
        case .trimMargins:
            let outURL = FileUtils.uniqueURL(for: url, suffix: "_trimmed", extension: "pdf")
            let copy = PDFDocument(url: url) ?? doc
            for i in 0..<copy.pageCount {
                if let page = copy.page(at: i) {
                    let box = page.bounds(for: .mediaBox)
                    let trimmed = box.insetBy(dx: 24, dy: 30)
                    page.setBounds(trimmed, for: .cropBox)
                }
            }
            copy.write(to: outURL)
            return outURL
            
        case .standardizeA4:
            let outURL = FileUtils.uniqueURL(for: url, suffix: "_A4", extension: "pdf")
            let a4Rect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8)
            let newDoc = PDFDocument()
            for i in 0..<doc.pageCount {
                if let page = doc.page(at: i) {
                    let img = NSImage(size: a4Rect.size, flipped: false) { rect in
                        guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
                        ctx.setFillColor(CGColor.white)
                        ctx.fill(rect)
                        let pageBounds = page.bounds(for: .mediaBox)
                        let scale = min(rect.width / pageBounds.width, rect.height / pageBounds.height) * 0.95
                        let dx = (rect.width - pageBounds.width * scale) / 2
                        let dy = (rect.height - pageBounds.height * scale) / 2
                        ctx.translateBy(x: dx, y: dy)
                        ctx.scaleBy(x: scale, y: scale)
                        page.draw(with: .mediaBox, to: ctx)
                        return true
                    }
                    if let newPage = PDFPage(image: img) {
                        newDoc.insert(newPage, at: newDoc.pageCount)
                    }
                }
            }
            newDoc.write(to: outURL)
            return outURL
            
        case .stampCopy:
            let outURL = FileUtils.uniqueURL(for: url, suffix: "_КОПИЯ", extension: "pdf")
            return try applyWatermark(doc: doc, stamp: "КОПИЯ", color: NSColor.systemRed, toURL: outURL)
            
        case .stampDraft:
            let outURL = FileUtils.uniqueURL(for: url, suffix: "_DRAFT", extension: "pdf")
            return try applyWatermark(doc: doc, stamp: "DRAFT", color: NSColor.systemOrange, toURL: outURL)
            
        case .mergeFolderPDFs:
            let outURL = FileUtils.uniqueURL(for: url, suffix: "_merged", extension: "pdf")
            let files = try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
                .filter { $0.pathExtension.lowercased() == "pdf" && !$0.lastPathComponent.contains("_merged") }
                .sorted(by: { $0.lastPathComponent < $1.lastPathComponent })
            
            let mergedDoc = PDFDocument()
            for file in files {
                if let subDoc = PDFDocument(url: file) {
                    for i in 0..<subDoc.pageCount {
                        if let page = subDoc.page(at: i) {
                            mergedDoc.insert(page, at: mergedDoc.pageCount)
                        }
                    }
                }
            }
            guard mergedDoc.pageCount > 0 else {
                throw NSError(domain: "DocumentProcessor", code: 41, userInfo: [NSLocalizedDescriptionKey: "Нет файлов для объединения"])
            }
            mergedDoc.write(to: outURL)
            return outURL
        }
    }
    
    private func applyWatermark(doc: PDFDocument, stamp: String, color: NSColor, toURL: URL) throws -> URL {
        let newDoc = PDFDocument()
        for i in 0..<doc.pageCount {
            guard let page = doc.page(at: i) else { continue }
            let bounds = page.bounds(for: .mediaBox)
            let img = NSImage(size: bounds.size, flipped: false) { rect in
                guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
                page.draw(with: .mediaBox, to: ctx)
                
                ctx.saveGState()
                ctx.translateBy(x: rect.midX, y: rect.midY)
                ctx.rotate(by: CGFloat.pi / 4.0)
                
                let fontSize = min(rect.width, rect.height) / 7.0
                let stampColor = color.withAlphaComponent(0.28)
                let attr: [NSAttributedString.Key: Any] = [
                    .font: NSFont.boldSystemFont(ofSize: fontSize),
                    .foregroundColor: stampColor
                ]
                let str = NSAttributedString(string: stamp, attributes: attr)
                let strSize = str.size()
                str.draw(at: CGPoint(x: -strSize.width / 2, y: -strSize.height / 2))
                
                let boxRect = CGRect(x: -strSize.width / 2 - 16, y: -strSize.height / 2 - 8, width: strSize.width + 32, height: strSize.height + 16)
                ctx.setStrokeColor(stampColor.cgColor)
                ctx.setLineWidth(4.0)
                ctx.stroke(boxRect)
                
                ctx.restoreGState()
                return true
            }
            if let newPage = PDFPage(image: img) {
                newDoc.insert(newPage, at: newDoc.pageCount)
            }
        }
        newDoc.write(to: toURL)
        return toURL
    }
    
    // MARK: - Option & Command Actions (Data & Text)
    
    public func executeDataOptionAction(_ action: DataOptionAction, on url: URL) throws -> URL {
        let ext = url.pathExtension.lowercased()
        
        switch action {
        case .cleanZip:
            return try createCleanZip(for: url)
            
        case .sortAZ:
            let outURL = FileUtils.uniqueURL(for: url, suffix: "_sorted", extension: ext)
            let content = try Self.readText(from: url)
            let lines = content.components(separatedBy: .newlines)
            if ext == "csv" && lines.count > 1 {
                let header = lines[0]
                let sortedRows = lines.dropFirst().filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.sorted()
                let result = ([header] + sortedRows).joined(separator: "\n") + "\n"
                try result.write(to: outURL, atomically: true, encoding: .utf8)
            } else {
                let sortedLines = lines.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.sorted()
                let result = sortedLines.joined(separator: "\n") + "\n"
                try result.write(to: outURL, atomically: true, encoding: .utf8)
            }
            return outURL
            
        case .deduplicate:
            let outURL = FileUtils.uniqueURL(for: url, suffix: "_unique", extension: ext)
            let content = try Self.readText(from: url)
            let lines = content.components(separatedBy: .newlines)
            var seen = Set<String>()
            var uniqueLines: [String] = []
            for line in lines {
                if !seen.contains(line) {
                    seen.insert(line)
                    uniqueLines.append(line)
                }
            }
            let result = uniqueLines.joined(separator: "\n")
            try result.write(to: outURL, atomically: true, encoding: .utf8)
            return outURL
            
        case .numberLines:
            let outURL = FileUtils.uniqueURL(for: url, suffix: "_numbered", extension: ext)
            let content = try Self.readText(from: url)
            let lines = content.components(separatedBy: .newlines)
            var numbered: [String] = []
            var counter = 1
            for line in lines {
                if line.trimmingCharacters(in: .whitespaces).isEmpty {
                    numbered.append("")
                } else {
                    numbered.append("\(counter). \(line)")
                    counter += 1
                }
            }
            let result = numbered.joined(separator: "\n")
            try result.write(to: outURL, atomically: true, encoding: .utf8)
            return outURL
            
        case .backupTimestamp:
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
            let timestamp = formatter.string(from: Date())
            let outURL = FileUtils.uniqueURL(for: url, suffix: "_\(timestamp)", extension: ext)
            try FileManager.default.copyItem(at: url, to: outURL)
            return outURL
        }
    }
    
    public func executeDataCommandAction(_ action: DataCommandAction, on url: URL) throws -> URL {
        let ext = url.pathExtension.lowercased()
        
        switch action {
        case .head10:
            let outURL = FileUtils.uniqueURL(for: url, suffix: "_head10", extension: ext)
            let content = try Self.readText(from: url)
            let lines = content.components(separatedBy: .newlines)
            let head = Array(lines.prefix(11)).joined(separator: "\n")
            try head.write(to: outURL, atomically: true, encoding: .utf8)
            return outURL
            
        case .head100:
            let outURL = FileUtils.uniqueURL(for: url, suffix: "_head100", extension: ext)
            let content = try Self.readText(from: url)
            let lines = content.components(separatedBy: .newlines)
            let head = Array(lines.prefix(101)).joined(separator: "\n")
            try head.write(to: outURL, atomically: true, encoding: .utf8)
            return outURL
            
        case .sample10:
            let outURL = FileUtils.uniqueURL(for: url, suffix: "_sample10", extension: ext)
            let content = try Self.readText(from: url)
            let lines = content.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            if ext == "csv" && lines.count > 1 {
                let header = lines[0]
                let rows = Array(lines.dropFirst()).shuffled()
                let sample = ([header] + Array(rows.prefix(10))).joined(separator: "\n") + "\n"
                try sample.write(to: outURL, atomically: true, encoding: .utf8)
            } else {
                let sample = Array(lines.shuffled().prefix(10)).joined(separator: "\n") + "\n"
                try sample.write(to: outURL, atomically: true, encoding: .utf8)
            }
            return outURL
            
        case .base64Encode:
            let outURL = FileUtils.uniqueURL(for: url, suffix: "_base64", extension: "txt")
            let data = try Data(contentsOf: url)
            let base64 = data.base64EncodedString(options: .lineLength76Characters)
            try base64.write(to: outURL, atomically: true, encoding: .utf8)
            return outURL
            
        case .base64Decode:
            let outURL = FileUtils.uniqueURL(for: url, suffix: "_decoded", extension: ext == "txt" ? "bin" : ext)
            let base64String = try Self.readText(from: url)
            guard let data = Data(base64Encoded: base64String, options: .ignoreUnknownCharacters) else {
                throw NSError(domain: "DocumentProcessor", code: 42, userInfo: [NSLocalizedDescriptionKey: "Файл не является валидным Base64"])
            }
            try data.write(to: outURL)
            return outURL
        }
    }
    
    // MARK: - Clean ZIP Utility
    
    public func createCleanZip(for url: URL) throws -> URL {
        let folder = url.deletingLastPathComponent()
        let zipURL = FileUtils.uniqueURL(for: url, extension: "zip")
        let result = try ProcessRunner.run(
            executable: "/usr/bin/zip",
            arguments: [
                "-r",
                "-X",
                zipURL.lastPathComponent,
                url.lastPathComponent,
                "-x", "*.DS_Store",
                "-x", "__MACOSX*"
            ],
            currentDirectoryURL: folder
        )
        if !result.isSuccess {
            throw NSError(domain: "DocumentProcessor", code: 43, userInfo: [NSLocalizedDescriptionKey: "Ошибка создания ZIP архива: \(result.stderrString)"])
        }
        return zipURL
    }
}
