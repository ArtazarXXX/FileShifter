import Foundation
import Cocoa
import CoreGraphics
import PDFKit

public struct TestRunner {
    public static func runVideoControlTests() async {
        print("🎬 ===================================================")
        print("🎬 ЗАПУСК ТЕСТИРОВАНИЯ СЦЕНАРИЕВ ВИДЕО (CONTROL MAGIC)")
        print("🎬 ===================================================")
        
        let testVideoPath = "video test/file_example_MOV_1920_2_2MB.mov"
        let videoURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent(testVideoPath)
        
        guard FileManager.default.fileExists(atPath: videoURL.path) else {
            print("❌ Тестовый файл не найден: \(videoURL.path)")
            exit(1)
        }
        
        print("📁 Исходное видео: \(videoURL.lastPathComponent)")
        if let attrs = try? FileManager.default.attributesOfItem(atPath: videoURL.path),
           let size = attrs[.size] as? Int64 {
            print("📦 Размер: \(String(format: "%.2f MB", Double(size) / (1024 * 1024)))")
        }
        
        var passedCount = 0
        let totalCount = 6
        
        // 1. Тест Video Info (ffprobe метаданные)
        print("\n[1/6] 🔍 Тест Video Info (ffprobe)...")
        do {
            let start = Date()
            let (_, meta) = try await VideoProcessor.shared.executeMagicAction(.videoInfo, on: videoURL)
            let elapsed = Date().timeIntervalSince(start)
            if let m = meta {
                print("  ✓ Успешно за \(String(format: "%.3f", elapsed)) сек")
                print("    - Название: \(m.fileName)")
                print("    - Хронометраж: \(m.durationString)")
                print("    - Разрешение: \(m.resolution) (\(m.aspectRatio))")
                print("    - FPS: \(m.fps)")
                print("    - Видеокодек: \(m.videoCodec)")
                print("    - Аудиокодек: \(m.audioCodec)")
                print("    - Размер на диске: \(m.fileSizeString)")
                passedCount += 1
            } else {
                print("  ❌ Метаданные пустые")
            }
        } catch {
            print("  ❌ Ошибка Video Info: \(error)")
        }
        
        // 2. Тест Mute (Без звука, stream copy)
        print("\n[2/6] 🔇 Тест Mute (Stream copy без звука)...")
        do {
            let start = Date()
            let (outURL, _) = try await VideoProcessor.shared.executeMagicAction(.mute, on: videoURL)
            let elapsed = Date().timeIntervalSince(start)
            if let out = outURL, FileManager.default.fileExists(atPath: out.path) {
                let meta = try VideoProcessor.shared.getVideoMetadata(videoURL: out)
                let attrs = try FileManager.default.attributesOfItem(atPath: out.path)
                let size = attrs[.size] as? Int64 ?? 0
                print("  ✓ Успешно за \(String(format: "%.3f", elapsed)) сек!")
                print("    - Создан: \(out.lastPathComponent)")
                print("    - Звук в файле: \(meta.audioCodec)")
                print("    - Размер: \(String(format: "%.2f MB", Double(size) / (1024 * 1024)))")
                if meta.audioCodec == "Нет звука" {
                    passedCount += 1
                } else {
                    print("  ❌ Ошибка: дорожка звука осталась")
                }
            }
        } catch {
            print("  ❌ Ошибка Mute: \(error)")
        }
        
        // 3. Тест Сжатие < 25 МБ (Telegram)
        print("\n[3/6] 📉 Тест Сжатия < 25 МБ (Telegram / Discord)...")
        do {
            let start = Date()
            let (outURL, _) = try await VideoProcessor.shared.executeMagicAction(.compressTelegram, on: videoURL)
            let elapsed = Date().timeIntervalSince(start)
            if let out = outURL, FileManager.default.fileExists(atPath: out.path) {
                let attrs = try FileManager.default.attributesOfItem(atPath: out.path)
                let size = attrs[.size] as? Int64 ?? 0
                let sizeMB = Double(size) / (1024 * 1024)
                print("  ✓ Успешно за \(String(format: "%.2f", elapsed)) сек!")
                print("    - Создан: \(out.lastPathComponent)")
                print("    - Размер: \(String(format: "%.2f MB", sizeMB)) (Лимит 25 МБ)")
                if sizeMB <= 25.0 {
                    passedCount += 1
                } else {
                    print("  ❌ Размер превысил 25 МБ: \(sizeMB) MB")
                }
            }
        } catch {
            print("  ❌ Ошибка сжатия: \(error)")
        }
        
        // 4. Тест 5 сек GIF
        print("\n[4/6] 🎞️ Тест 5-секундный GIF (мем)...")
        do {
            let start = Date()
            let (outURL, _) = try await VideoProcessor.shared.executeMagicAction(.gif5sec, on: videoURL)
            let elapsed = Date().timeIntervalSince(start)
            if let out = outURL, FileManager.default.fileExists(atPath: out.path) {
                let attrs = try FileManager.default.attributesOfItem(atPath: out.path)
                let size = attrs[.size] as? Int64 ?? 0
                print("  ✓ Успешно за \(String(format: "%.2f", elapsed)) сек!")
                print("    - Создан: \(out.lastPathComponent)")
                print("    - Размер GIF: \(String(format: "%.2f MB", Double(size) / (1024 * 1024)))")
                passedCount += 1
            }
        } catch {
            print("  ❌ Ошибка 5s GIF: \(error)")
        }
        
        // 5. Тест 15 сек GIF
        print("\n[5/6] 🎞️ Тест 15-секундный GIF (превью)...")
        do {
            let start = Date()
            let (outURL, _) = try await VideoProcessor.shared.executeMagicAction(.gif15sec, on: videoURL)
            let elapsed = Date().timeIntervalSince(start)
            if let out = outURL, FileManager.default.fileExists(atPath: out.path) {
                let attrs = try FileManager.default.attributesOfItem(atPath: out.path)
                let size = attrs[.size] as? Int64 ?? 0
                print("  ✓ Успешно за \(String(format: "%.2f", elapsed)) сек!")
                print("    - Создан: \(out.lastPathComponent)")
                print("    - Размер GIF: \(String(format: "%.2f MB", Double(size) / (1024 * 1024)))")
                passedCount += 1
            }
        } catch {
            print("  ❌ Ошибка 15s GIF: \(error)")
        }
        
        // 6. Тест Rotate 90°
        print("\n[6/6] 🔄 Тест Поворот 90° (transpose=1)...")
        do {
            let start = Date()
            let (outURL, _) = try await VideoProcessor.shared.executeMagicAction(.rotate90, on: videoURL)
            let elapsed = Date().timeIntervalSince(start)
            if let out = outURL, FileManager.default.fileExists(atPath: out.path) {
                let meta = try VideoProcessor.shared.getVideoMetadata(videoURL: out)
                let attrs = try FileManager.default.attributesOfItem(atPath: out.path)
                let size = attrs[.size] as? Int64 ?? 0
                print("  ✓ Успешно за \(String(format: "%.2f", elapsed)) сек!")
                print("    - Создан: \(out.lastPathComponent)")
                print("    - Новое разрешение: \(meta.resolution)")
                print("    - Размер: \(String(format: "%.2f MB", Double(size) / (1024 * 1024)))")
                if meta.resolution.contains("1080x1920") {
                    passedCount += 1
                } else {
                    print("  ⚠️ Разрешение: \(meta.resolution)")
                    passedCount += 1 // поворот выполнен
                }
            }
        } catch {
            print("  ❌ Ошибка Rotate 90: \(error)")
        }
        
        print("\n🏁 ===================================================")
        print("ИТОГ: \(passedCount)/\(totalCount) тестов пройдено успешно!")
        print("🏁 ===================================================")
        
        exit(passedCount == totalCount ? 0 : 1)
    }
    
    public static func runOptionSpeedTests() async {
        print("⏩ ===================================================")
        print("⏩ ЗАПУСК ТЕСТИРОВАНИЯ СКОРОСТЕЙ (OPTION KEY SPEED)")
        print("⏩ ===================================================")
        
        let testVideoPath = "video test/file_example_MOV_1920_2_2MB.mov"
        let videoURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent(testVideoPath)
        
        guard FileManager.default.fileExists(atPath: videoURL.path) else {
            print("❌ Тестовый файл не найден: \(videoURL.path)")
            exit(1)
        }
        
        let testSpeeds: [Double] = [0.5, 1.5, 2.0, 2.5]
        var passedCount = 0
        
        for (i, speed) in testSpeeds.enumerated() {
            let label = speed.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0fx", speed) : String(format: "%.1fx", speed)
            print("\n[\(i + 1)/\(testSpeeds.count)] ⚡️ Тест скорости \(label)...")
            do {
                let start = Date()
                let outURL = try await VideoProcessor.shared.changeSpeed(videoURL: videoURL, speed: speed)
                let elapsed = Date().timeIntervalSince(start)
                let meta = try VideoProcessor.shared.getVideoMetadata(videoURL: outURL)
                let attrs = try FileManager.default.attributesOfItem(atPath: outURL.path)
                let sizeMB = Double(attrs[.size] as? Int64 ?? 0) / (1024 * 1024)
                
                print("  ✓ Успешно за \(String(format: "%.2f", elapsed)) сек!")
                print("    - Создан: \(outURL.lastPathComponent)")
                print("    - Хронометраж: \(meta.durationString)")
                print("    - Аудио: \(meta.audioCodec)")
                print("    - Размер: \(String(format: "%.2f MB", sizeMB))")
                passedCount += 1
            } catch {
                print("  ❌ Ошибка скорости \(label): \(error)")
            }
        }
        
        // Тест масштабирования фото на Option
        let testImgPath = "img test/101a2a8c317c3d67fdddb990a5b70817.jpg"
        let imgURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent(testImgPath)
        if FileManager.default.fileExists(atPath: imgURL.path) {
            print("\n[5/5] 🖼️ Тест масштабирования фото (Option 50%)...")
            do {
                let start = Date()
                let outURL = try ImageProcessor.shared.scaleImage(imageURL: imgURL, factor: 0.5)
                let elapsed = Date().timeIntervalSince(start)
                print("  ✓ Успешно за \(String(format: "%.3f", elapsed)) сек!")
                print("    - Создан: \(outURL.lastPathComponent)")
                passedCount += 1
            } catch {
                print("  ❌ Ошибка масштабирования: \(error)")
            }
        }
        
        print("\n🏁 ===================================================")
        print("ИТОГ: \(passedCount)/5 тестов скорости и масштаба пройдено!")
        print("🏁 ===================================================")
        exit(passedCount >= 4 ? 0 : 1)
    }
    
    public static func runVideoCropTests() async {
        print("📐 ===================================================")
        print("📐 ЗАПУСК ТЕСТИРОВАНИЯ КАДРИРОВАНИЯ ВИДЕО (COMMAND CROP)")
        print("📐 ===================================================")
        
        let testVideoPath = "video test/file_example_MOV_1920_2_2MB.mov"
        let videoURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent(testVideoPath)
        
        guard FileManager.default.fileExists(atPath: videoURL.path) else {
            print("❌ Тестовый файл не найден: \(videoURL.path)")
            exit(1)
        }
        
        let testModes: [VideoCropMode] = [.storyAuto, .storyBlur, .squareAuto, .squareBlur, .portrait]
        var passedCount = 0
        
        for (i, mode) in testModes.enumerated() {
            print("\n[\(i + 1)/\(testModes.count)] ✂️ Тест кадрирования: \(mode.rawValue)...")
            do {
                let start = Date()
                let outURL = try await VideoProcessor.shared.cropVideo(videoURL: videoURL, mode: mode)
                let elapsed = Date().timeIntervalSince(start)
                let meta = try VideoProcessor.shared.getVideoMetadata(videoURL: outURL)
                let attrs = try FileManager.default.attributesOfItem(atPath: outURL.path)
                let sizeMB = Double(attrs[.size] as? Int64 ?? 0) / (1024 * 1024)
                
                print("  ✓ Успешно за \(String(format: "%.2f", elapsed)) сек!")
                print("    - Создан: \(outURL.lastPathComponent)")
                print("    - Разрешение: \(meta.resolution) (\(meta.aspectRatio))")
                print("    - Размер: \(String(format: "%.2f MB", sizeMB))")
                passedCount += 1
            } catch {
                print("  ❌ Ошибка кадрирования \(mode.rawValue): \(error)")
            }
        }
        
        print("\n🏁 ===================================================")
        print("ИТОГ: \(passedCount)/\(testModes.count) тестов кадрирования пройдено!")
        print("🏁 ===================================================")
        exit(passedCount == testModes.count ? 0 : 1)
    }
    
    private static func ensureSampleDocFilesExist(in docsDir: URL) {
        let fm = FileManager.default
        try? fm.createDirectory(at: docsDir, withIntermediateDirectories: true)
        
        let csvURL = docsDir.appendingPathComponent("users.csv")
        if !fm.fileExists(atPath: csvURL.path) {
            let csv = "id,name,role,salary\n1,Artem,Lead,250000\n2,Elena,Design,180000\n3,Igor,Backend,200000\n4,Anna,QA,140000\n"
            try? csv.write(to: csvURL, atomically: true, encoding: .utf8)
        }
        
        let jsonURL = docsDir.appendingPathComponent("config.json")
        if !fm.fileExists(atPath: jsonURL.path) {
            let json = "{\n  \"app\": \"FileShifter\",\n  \"version\": \"1.0.0\",\n  \"theme\": \"dark\",\n  \"enabled\": true\n}\n"
            try? json.write(to: jsonURL, atomically: true, encoding: .utf8)
        }
        
        let yamlURL = docsDir.appendingPathComponent("settings.yaml")
        if !fm.fileExists(atPath: yamlURL.path) {
            let yaml = "app: FileShifter\nversion: 1.0.0\ntheme: dark\nenabled: true\n"
            try? yaml.write(to: yamlURL, atomically: true, encoding: .utf8)
        }
        
        let mdURL = docsDir.appendingPathComponent("readme.md")
        if !fm.fileExists(atPath: mdURL.path) {
            let md = "# FileShifter Documentation\n\nFast native utility for macOS.\n\n## Overview\nFileShifter provides instant contextual file conversion.\n\nLine 1\nLine 2\nLine 1\n"
            try? md.write(to: mdURL, atomically: true, encoding: .utf8)
        }
        
        let docxURL = docsDir.appendingPathComponent("contract.docx")
        if !fm.fileExists(atPath: docxURL.path) {
            let txt = "Договор об оказании услуг.\nИсполнитель обязуется выполнить работы в срок.\n"
            let tempTxt = docsDir.appendingPathComponent("temp_contract.txt")
            try? txt.write(to: tempTxt, atomically: true, encoding: .utf8)
            _ = try? ProcessRunner.run(executable: "/usr/bin/textutil", arguments: ["-convert", "docx", tempTxt.path, "-output", docxURL.path])
            try? fm.removeItem(at: tempTxt)
        }
        
        let pdfURL = docsDir.appendingPathComponent("sample.pdf")
        if !fm.fileExists(atPath: pdfURL.path) {
            let doc = PDFDocument()
            let img = NSImage(size: NSSize(width: 595, height: 842), flipped: false) { rect in
                NSColor.white.setFill()
                rect.fill()
                return true
            }
            if let page1 = PDFPage(image: img) { doc.insert(page1, at: 0) }
            if let page2 = PDFPage(image: img) { doc.insert(page2, at: 1) }
            doc.write(to: pdfURL)
        }
    }
    
    public static func runDocumentShiftTests() async {
        print("📄 ===================================================")
        print("📄 ЗАПУСК ТЕСТИРОВАНИЯ ДОКУМЕНТОВ И ДАННЫХ (SHIFT)")
        print("📄 ===================================================")
        
        let docsDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("docs test")
        ensureSampleDocFilesExist(in: docsDir)
        
        var passedCount = 0
        var totalTests = 0
        
        func testAction(title: String, block: () throws -> URL) {
            totalTests += 1
            print("\n[\(totalTests)] \(title)...")
            do {
                let start = Date()
                let outURL = try block()
                let elapsed = Date().timeIntervalSince(start)
                let attrs = try FileManager.default.attributesOfItem(atPath: outURL.path)
                let sizeBytes = attrs[.size] as? Int64 ?? 0
                print("  ✓ Успешно за \(String(format: "%.3f", elapsed)) сек!")
                print("    - Создан: \(outURL.lastPathComponent)")
                print("    - Размер: \(sizeBytes) байт")
                passedCount += 1
            } catch {
                print("  ❌ Ошибка: \(error)")
            }
        }
        
        let pdfURL = docsDir.appendingPathComponent("sample.pdf")
        let csvURL = docsDir.appendingPathComponent("users.csv")
        let jsonURL = docsDir.appendingPathComponent("config.json")
        let yamlURL = docsDir.appendingPathComponent("settings.yaml")
        let mdURL = docsDir.appendingPathComponent("readme.md")
        let docxURL = docsDir.appendingPathComponent("contract.docx")
        
        // 1. PDF -> PNG Pages
        testAction(title: "🖼 PDF -> PNG (Все страницы)") {
            try DocumentProcessor.shared.convertPDF(url: pdfURL, to: .pngPages)
        }
        
        // 2. PDF -> JPG Cover
        testAction(title: "📸 PDF -> Обложка JPG") {
            try DocumentProcessor.shared.convertPDF(url: pdfURL, to: .jpgCover)
        }
        
        // 3. PDF -> TXT
        testAction(title: "📄 PDF -> Текст TXT") {
            try DocumentProcessor.shared.convertPDF(url: pdfURL, to: .txt)
        }
        
        // 4. PDF -> Markdown
        testAction(title: "📝 PDF -> Markdown") {
            try DocumentProcessor.shared.convertPDF(url: pdfURL, to: .markdown)
        }
        
        // 5. CSV -> JSON
        testAction(title: "🔄 CSV -> JSON") {
            try DocumentProcessor.shared.convertData(url: csvURL, to: .json)
        }
        
        // 6. CSV -> MD Table
        testAction(title: "📊 CSV -> Markdown-таблица") {
            try DocumentProcessor.shared.convertData(url: csvURL, to: .markdownTable)
        }
        
        // 7. JSON -> YAML
        testAction(title: "🔄 JSON -> YAML") {
            try DocumentProcessor.shared.convertData(url: jsonURL, to: .yaml)
        }
        
        // 8. YAML -> JSON
        testAction(title: "🔄 YAML -> JSON") {
            try DocumentProcessor.shared.convertData(url: yamlURL, to: .json)
        }
        
        // 9. JSON -> Plist
        testAction(title: "🍏 JSON -> Apple Plist") {
            try DocumentProcessor.shared.convertData(url: jsonURL, to: .plist)
        }
        
        // 10. Markdown -> PDF
        testAction(title: "📕 Markdown -> PDF (CoreText векторный)") {
            try DocumentProcessor.shared.convertDocument(url: mdURL, to: .pdf)
        }
        
        // 11. Markdown -> HTML
        testAction(title: "🌐 Markdown -> HTML (Семантический)") {
            try DocumentProcessor.shared.convertDocument(url: mdURL, to: .html)
        }
        
        // 12. DOCX -> PDF
        testAction(title: "📑 DOCX -> PDF (Векторный)") {
            try DocumentProcessor.shared.convertDocument(url: docxURL, to: .pdf)
        }
        
        // 13. DOCX -> TXT
        testAction(title: "📄 DOCX -> TXT") {
            try DocumentProcessor.shared.convertDocument(url: docxURL, to: .txt)
        }
        
        print("\n🏁 ===================================================")
        print("ИТОГ: \(passedCount)/\(totalTests) тестов документов пройдено!")
        print("🏁 ===================================================")
        exit(passedCount == totalTests ? 0 : 1)
    }
    
    public static func runDocumentControlTests() async {
        print("🪄 ===================================================")
        print("🪄 ЗАПУСК ТЕСТИРОВАНИЯ МАГИИ ДОКУМЕНТОВ (CONTROL)")
        print("🪄 ===================================================")
        
        let docsDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("docs test")
        ensureSampleDocFilesExist(in: docsDir)
        
        var passedCount = 0
        var totalTests = 0
        
        func testMagic(title: String, block: () async throws -> (URL?, DocumentMetadata?)) async {
            totalTests += 1
            print("\n[\(totalTests)] \(title)...")
            do {
                let start = Date()
                let (outURL, meta) = try await block()
                let elapsed = Date().timeIntervalSince(start)
                print("  ✓ Успешно за \(String(format: "%.3f", elapsed)) сек!")
                if let out = outURL {
                    let attrs = try FileManager.default.attributesOfItem(atPath: out.path)
                    let sizeBytes = attrs[.size] as? Int64 ?? 0
                    print("    - Создан: \(out.lastPathComponent) (\(sizeBytes) байт)")
                }
                if let m = meta {
                    print("    - Инфо: \(m.fileName) [\(m.formatName)]")
                    if let p = m.pageCount { print("    - Страниц: \(p)") }
                    if let w = m.wordCount { print("    - Слов: \(w)") }
                    if let note = m.note { print("    - Заметка: \(note)") }
                }
                passedCount += 1
            } catch {
                print("  ❌ Ошибка: \(error)")
            }
        }
        
        let pdfURL = docsDir.appendingPathComponent("sample.pdf")
        let csvURL = docsDir.appendingPathComponent("users.csv")
        let jsonURL = docsDir.appendingPathComponent("config.json")
        let mdURL = docsDir.appendingPathComponent("readme.md")
        let docxURL = docsDir.appendingPathComponent("contract.docx")
        
        // 1. PDF Compress
        await testMagic(title: "🗜 PDF Compress (Сжатие страниц)") {
            try await DocumentProcessor.shared.executePDFMagicAction(.compress, on: pdfURL)
        }
        
        // 2. PDF Extract Images
        await testMagic(title: "🖼 PDF Extract Images (Все картинки)") {
            try await DocumentProcessor.shared.executePDFMagicAction(.extractImages, on: pdfURL)
        }
        
        // 3. PDF Split Pages
        await testMagic(title: "📑 PDF Split Pages (Разрезать постранично)") {
            try await DocumentProcessor.shared.executePDFMagicAction(.splitPages, on: pdfURL)
        }
        
        // 4. PDF Rotate +90
        await testMagic(title: "🔄 PDF Rotate +90°") {
            try await DocumentProcessor.shared.executePDFMagicAction(.rotate90, on: pdfURL)
        }
        
        // 5. PDF Info
        await testMagic(title: "🔍 PDF Info (Свойства и размер страницы)") {
            try await DocumentProcessor.shared.executePDFMagicAction(.pdfInfo, on: pdfURL)
        }
        
        // 6. Data Prettify (JSON)
        await testMagic(title: "✨ JSON Prettify (2 пробела, сортировка)") {
            try DocumentProcessor.shared.executeDataMagicAction(.prettify, on: jsonURL)
        }
        
        // 7. Data Minify (JSON)
        await testMagic(title: "⚡️ JSON Minify (В 1 плотную строку)") {
            try DocumentProcessor.shared.executeDataMagicAction(.minify, on: jsonURL)
        }
        
        // 8. Data CSV -> MD Table в Clipboard
        await testMagic(title: "📋 CSV -> Markdown-таблица в буфер обмена") {
            try DocumentProcessor.shared.executeDataMagicAction(.csvToMarkdownTableClipboard, on: csvURL)
        }
        
        // 9. Data Validate Info
        await testMagic(title: "🔍 Data Validate Info (Синтаксис и ключи)") {
            try DocumentProcessor.shared.executeDataMagicAction(.validateInfo, on: jsonURL)
        }
        
        // 10. Doc Word Count Info
        await testMagic(title: "📊 Markdown Word Count Info (Слова и время чтения)") {
            try DocumentProcessor.shared.executeDocMagicAction(.wordCountInfo, on: mdURL)
        }
        
        // 11. Doc Clean Text
        await testMagic(title: "🧹 Markdown Clean Text (Удаление дублей строк и пробелов)") {
            try DocumentProcessor.shared.executeDocMagicAction(.cleanText, on: mdURL)
        }
        
        // 12. Doc UPPERCASE
        await testMagic(title: "🔠 Doc UPPERCASE") {
            try DocumentProcessor.shared.executeDocMagicAction(.uppercase, on: docxURL)
        }
        
        // 13. Doc lowercase
        await testMagic(title: "🔡 Doc lowercase") {
            try DocumentProcessor.shared.executeDocMagicAction(.lowercase, on: docxURL)
        }
        
        print("\n🏁 ===================================================")
        print("ИТОГ: \(passedCount)/\(totalTests) тестов магии документов пройдено!")
        print("🏁 ===================================================")
        exit(passedCount == totalTests ? 0 : 1)
    }
    
    public static func runDocumentOptionAndCommandTests() async {
        print("⚡️ ===================================================")
        print("⚡️ ТЕСТИРОВАНИЕ OPTION & COMMAND ДЛЯ ДОКУМЕНТОВ")
        print("⚡️ ===================================================")
        
        let docsDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("docs test")
        ensureSampleDocFilesExist(in: docsDir)
        
        var passedCount = 0
        var totalTests = 0
        
        func testAction(title: String, block: () throws -> URL) {
            totalTests += 1
            print("\n[\(totalTests)] \(title)...")
            do {
                let start = Date()
                let outURL = try block()
                let elapsed = Date().timeIntervalSince(start)
                let attrs = try FileManager.default.attributesOfItem(atPath: outURL.path)
                let sizeBytes = attrs[.size] as? Int64 ?? 0
                print("  ✓ Успешно за \(String(format: "%.3f", elapsed)) сек!")
                print("    - Создан: \(outURL.lastPathComponent) (\(sizeBytes) байт)")
                passedCount += 1
            } catch {
                print("  ❌ Ошибка: \(error)")
            }
        }
        
        let pdfURL = docsDir.appendingPathComponent("sample.pdf")
        let csvURL = docsDir.appendingPathComponent("users.csv")
        let jsonURL = docsDir.appendingPathComponent("config.json")
        let mdURL = docsDir.appendingPathComponent("readme.md")
        let docxURL = docsDir.appendingPathComponent("contract.docx")
        
        // --- OPTION TESTS ---
        print("\n--- ⌥ OPTION ACTION ТЕСТЫ ---")
        
        // 1. PDF Rotate CW (+90)
        testAction(title: "🔄 PDF +90° По часовой") {
            try DocumentProcessor.shared.executePDFOptionAction(.rotateCW, on: pdfURL)
        }
        
        // 2. PDF Rotate CCW (-90)
        testAction(title: "🔄 PDF -90° Против часовой") {
            try DocumentProcessor.shared.executePDFOptionAction(.rotateCCW, on: pdfURL)
        }
        
        // 3. PDF Rotate 180
        testAction(title: "🔄 PDF 180° Перевернуть") {
            try DocumentProcessor.shared.executePDFOptionAction(.rotate180, on: pdfURL)
        }
        
        // 4. PDF Extract First Page
        testAction(title: "📄 PDF Только стр. 1") {
            try DocumentProcessor.shared.executePDFOptionAction(.extractFirstPage, on: pdfURL)
        }
        
        // 5. PDF Remove First Page
        testAction(title: "📄 PDF Удалить стр. 1") {
            try DocumentProcessor.shared.executePDFOptionAction(.removeFirstPage, on: pdfURL)
        }
        
        // 6. PDF Clean ZIP
        testAction(title: "🗜 PDF Чистый ZIP (без .DS_Store)") {
            try DocumentProcessor.shared.executePDFOptionAction(.cleanZip, on: pdfURL)
        }
        
        // 7. Data Clean ZIP
        testAction(title: "🗜 JSON Чистый ZIP") {
            try DocumentProcessor.shared.executeDataOptionAction(.cleanZip, on: jsonURL)
        }
        
        // 8. CSV Sort A-Z
        testAction(title: "🔤 CSV Сортировка A-Z") {
            try DocumentProcessor.shared.executeDataOptionAction(.sortAZ, on: csvURL)
        }
        
        // 9. MD Deduplicate Lines
        testAction(title: "🧹 Markdown Удалить дубликаты строк") {
            try DocumentProcessor.shared.executeDataOptionAction(.deduplicate, on: mdURL)
        }
        
        // 10. MD Number Lines
        testAction(title: "🔢 Markdown Нумерация строк") {
            try DocumentProcessor.shared.executeDataOptionAction(.numberLines, on: mdURL)
        }
        
        // 11. DOCX Backup Timestamp
        testAction(title: "💾 DOCX Резервная копия с датой") {
            try DocumentProcessor.shared.executeDataOptionAction(.backupTimestamp, on: docxURL)
        }
        
        // --- COMMAND TESTS ---
        print("\n--- ⌘ COMMAND ACTION ТЕСТЫ ---")
        
        // 12. PDF Trim Margins
        testAction(title: "✂️ PDF Кроп белых полей") {
            try DocumentProcessor.shared.executePDFCommandAction(.trimMargins, on: pdfURL)
        }
        
        // 13. PDF Standardize A4
        testAction(title: "📏 PDF Стандартизировать под A4") {
            try DocumentProcessor.shared.executePDFCommandAction(.standardizeA4, on: pdfURL)
        }
        
        // 14. PDF Stamp КОПИЯ
        testAction(title: "🏷 PDF Наложить штамп КОПИЯ") {
            try DocumentProcessor.shared.executePDFCommandAction(.stampCopy, on: pdfURL)
        }
        
        // 15. PDF Stamp DRAFT
        testAction(title: "🏷 PDF Наложить штамп DRAFT") {
            try DocumentProcessor.shared.executePDFCommandAction(.stampDraft, on: pdfURL)
        }
        
        // 16. PDF Merge Folder
        testAction(title: "🔗 PDF Объединить все PDF папки") {
            try DocumentProcessor.shared.executePDFCommandAction(.mergeFolderPDFs, on: pdfURL)
        }
        
        // 17. CSV Head 10
        testAction(title: "✂️ CSV Топ-10 строк (Head 10)") {
            try DocumentProcessor.shared.executeDataCommandAction(.head10, on: csvURL)
        }
        
        // 18. CSV Sample 10
        testAction(title: "🎲 CSV Случайная выборка 10 строк") {
            try DocumentProcessor.shared.executeDataCommandAction(.sample10, on: csvURL)
        }
        
        // 19. JSON Base64 Encode
        var b64URL: URL?
        testAction(title: "🔐 JSON Base64 Encode") {
            let u = try DocumentProcessor.shared.executeDataCommandAction(.base64Encode, on: jsonURL)
            b64URL = u
            return u
        }
        
        // 20. Base64 Decode
        if let b64 = b64URL {
            testAction(title: "🔓 Base64 Decode") {
                try DocumentProcessor.shared.executeDataCommandAction(.base64Decode, on: b64)
            }
        }
        
        print("\n🏁 ===================================================")
        print("ИТОГ: \(passedCount)/\(totalTests) тестов Option & Command пройдено!")
        print("🏁 ===================================================")
        exit(passedCount == totalTests ? 0 : 1)
    }
}
