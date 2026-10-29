import Foundation
import AppKit

@MainActor
public final class ActionExecutor {
    public static let shared = ActionExecutor()
    private init() {}
    
    public func execute(action: FileAction, for file: SelectedFile, at location: CGPoint) {
        switch action {
        // MARK: - Shift (Конвертация)
        case .convertVideo(let format):
            let startMsg = format == .movieRemux ? "Ремукс фильма для Mac..." : "Конвертирую в \(format.rawValue)..."
            let startIcon = format == .movieRemux ? "popcorn.fill" : "gearshape.arrow.triangle.2.circlepath"
            let successMsg = format == .movieRemux ? "Фильм готов для Mac ✓" : "\(format.rawValue) готов ✓"
            let successIcon = format == .mp3 ? "music.note" : (format == .movieRemux ? "popcorn.fill" : "checkmark.circle.fill")
            
            runTask(startMsg: startMsg, icon: startIcon, successMsg: successMsg, successIcon: successIcon, at: location) {
                try await VideoProcessor.shared.convert(videoURL: file.url, to: format)
            }
            
        case .convertImage(let format):
            runTask(startMsg: "Конвертирую в \(format.rawValue)...", icon: "photo", successMsg: "\(format.rawValue) готов ✓", successIcon: "checkmark.circle.fill", at: location) {
                try ImageProcessor.shared.convert(imageURL: file.url, to: format)
            }
            
        case .convertPDF(let format):
            runTask(startMsg: "Экспорт \(format.rawValue)...", icon: "doc.richtext", successMsg: "\(format.rawValue) готов ✓", successIcon: "checkmark.circle.fill", at: location) {
                try DocumentProcessor.shared.convertPDF(url: file.url, to: format)
            }
            
        case .convertData(let format):
            runTask(startMsg: "Конвертирую в \(format.rawValue)...", icon: "gearshape.arrow.triangle.2.circlepath", successMsg: "\(format.rawValue) готов ✓", successIcon: "checkmark.circle.fill", at: location) {
                try DocumentProcessor.shared.convertData(url: file.url, to: format)
            }
            
        case .convertDocument(let format):
            runTask(startMsg: "Конвертирую в \(format.rawValue)...", icon: "doc.text", successMsg: "\(format.rawValue) готов ✓", successIcon: "checkmark.circle.fill", at: location) {
                try DocumentProcessor.shared.convertDocument(url: file.url, to: format)
            }
            
        // MARK: - Control (Магия)
        case .magicVideo(let magicAction):
            if magicAction == .videoInfo {
                Task {
                    do {
                        let (_, metadata) = try await VideoProcessor.shared.executeMagicAction(magicAction, on: file.url)
                        if let meta = metadata {
                            OverlayWindowController.shared.showVideoInfoCard(meta: meta, at: location)
                        }
                    } catch {
                        OverlayWindowController.shared.showToast(message: error.localizedDescription, icon: "exclamationmark.triangle.fill", at: location)
                    }
                }
            } else {
                runTask(
                    startMsg: "Обработка: \(magicAction.rawValue)...",
                    icon: "gearshape.arrow.triangle.2.circlepath",
                    successMsg: "\(magicAction.rawValue) готово ✓",
                    successIcon: magicAction == .mute ? "speaker.slash.fill" : "checkmark.circle.fill",
                    at: location
                ) {
                    let (outURL, _) = try await VideoProcessor.shared.executeMagicAction(magicAction, on: file.url)
                    return outURL
                }
            }
            
        case .magicImage(let magicAction):
            Task {
                do {
                    let (outURL, textResult, metadata) = try await ImageProcessor.shared.executeMagicAction(magicAction, on: file.url)
                    if let meta = metadata {
                        OverlayWindowController.shared.showInfoCard(meta: meta, at: location)
                    } else if magicAction == .cleanMetadata {
                        OverlayWindowController.shared.showToast(message: "EXIF и GPS очищены ✓", icon: "lock.shield.fill", at: location)
                    } else if magicAction == .copyBase64 {
                        OverlayWindowController.shared.showToast(message: "Base64 в буфере обмена ✓", icon: "curlybraces", at: location)
                    } else if let text = textResult {
                        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\n", with: " ")
                        let preview = clean.count > 25 ? "\(clean.prefix(25))..." : clean
                        OverlayWindowController.shared.showToast(message: "Текст: \"\(preview)\"", icon: "doc.text.viewfinder", at: location)
                    } else {
                        OverlayWindowController.shared.showToast(message: "\(magicAction.rawValue) готово ✓", icon: "sparkles", at: location)
                        if let out = outURL {
                            print("[ActionExecutor] Магия фото: \(out.lastPathComponent)")
                        }
                    }
                } catch {
                    OverlayWindowController.shared.showToast(message: error.localizedDescription, icon: "exclamationmark.triangle.fill", at: location)
                }
            }
            
        case .magicPDF(let magicAction):
            if magicAction == .pdfInfo {
                Task {
                    do {
                        let (_, meta) = try await DocumentProcessor.shared.executePDFMagicAction(magicAction, on: file.url)
                        if let m = meta {
                            OverlayWindowController.shared.showDocumentInfoCard(meta: m, at: location)
                        }
                    } catch {
                        OverlayWindowController.shared.showToast(message: error.localizedDescription, icon: "exclamationmark.triangle.fill", at: location)
                    }
                }
            } else {
                let successMsg: String
                let iconName: String
                switch magicAction {
                case .compress:
                    successMsg = "PDF оптимизирован ✓"
                    iconName = "arrow.down.right.and.arrow.up.left"
                case .ocrClipboard:
                    successMsg = "Текст скана в буфере ✓"
                    iconName = "doc.text.viewfinder"
                case .extractImages:
                    successMsg = "Картинки извлечены ✓"
                    iconName = "photo.stack"
                case .splitPages:
                    successMsg = "PDF разрезан на страницы ✓"
                    iconName = "scissors"
                case .rotate90:
                    successMsg = "PDF повернут +90° ✓"
                    iconName = "rotate.right"
                case .pdfInfo:
                    successMsg = "Инфо готово"
                    iconName = "info.circle"
                }
                
                runTask(startMsg: "\(magicAction.rawValue)...", icon: "gearshape.arrow.triangle.2.circlepath", successMsg: successMsg, successIcon: iconName, at: location) {
                    let (outURL, _) = try await DocumentProcessor.shared.executePDFMagicAction(magicAction, on: file.url)
                    return outURL
                }
            }
            
        case .magicData(let magicAction):
            if magicAction == .validateInfo {
                do {
                    let (_, meta) = try DocumentProcessor.shared.executeDataMagicAction(magicAction, on: file.url)
                    if let m = meta {
                        OverlayWindowController.shared.showDocumentInfoCard(meta: m, at: location)
                    }
                } catch {
                    OverlayWindowController.shared.showToast(message: error.localizedDescription, icon: "exclamationmark.triangle.fill", at: location)
                }
            } else {
                do {
                    let (outURL, _) = try DocumentProcessor.shared.executeDataMagicAction(magicAction, on: file.url)
                    let successMsg: String
                    let iconName: String
                    switch magicAction {
                    case .prettify:
                        successMsg = "Форматирование готово ✓"
                        iconName = "sparkles"
                    case .minify:
                        successMsg = "В 1 строку сжато ✓"
                        iconName = "arrow.right.to.line.compact"
                    case .copyToClipboard:
                        successMsg = "Код в буфере обмена ✓"
                        iconName = "doc.on.clipboard"
                    case .csvToMarkdownTableClipboard:
                        successMsg = "MD-таблица в буфере ✓"
                        iconName = "tablecells"
                    case .validateInfo:
                        successMsg = "Валидация готова"
                        iconName = "info.circle"
                    }
                    OverlayWindowController.shared.showToast(message: successMsg, icon: iconName, at: location)
                    if let out = outURL {
                        print("[ActionExecutor] Data магия выполнена: \(out.lastPathComponent)")
                    }
                } catch {
                    OverlayWindowController.shared.showToast(message: error.localizedDescription, icon: "exclamationmark.triangle.fill", at: location)
                }
            }
            
        case .magicDoc(let magicAction):
            if magicAction == .wordCountInfo {
                do {
                    let (_, meta) = try DocumentProcessor.shared.executeDocMagicAction(magicAction, on: file.url)
                    if let m = meta {
                        OverlayWindowController.shared.showDocumentInfoCard(meta: m, at: location)
                    }
                } catch {
                    OverlayWindowController.shared.showToast(message: error.localizedDescription, icon: "exclamationmark.triangle.fill", at: location)
                }
            } else {
                do {
                    let (outURL, _) = try DocumentProcessor.shared.executeDocMagicAction(magicAction, on: file.url)
                    let successMsg: String
                    let iconName: String
                    switch magicAction {
                    case .wordCountInfo:
                        successMsg = "Статистика готова"
                        iconName = "info.circle"
                    case .cleanText:
                        successMsg = "Текст очищен ✓"
                        iconName = "wand.and.stars"
                    case .copyCleanText:
                        successMsg = "Текст в буфере ✓"
                        iconName = "doc.on.clipboard"
                    case .uppercase:
                        successMsg = "UPPERCASE готов ✓"
                        iconName = "textformat.size.larger"
                    case .lowercase:
                        successMsg = "lowercase готов ✓"
                        iconName = "textformat.size.smaller"
                    }
                    OverlayWindowController.shared.showToast(message: successMsg, icon: iconName, at: location)
                    if let out = outURL {
                        print("[ActionExecutor] Document магия выполнена: \(out.lastPathComponent)")
                    }
                } catch {
                    OverlayWindowController.shared.showToast(message: error.localizedDescription, icon: "exclamationmark.triangle.fill", at: location)
                }
            }
            
        // MARK: - Option (Скорость / Масштаб / Действия)
        case .videoSpeed(let speed):
            let speedLabel = speed.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0fx", speed) : String(format: "%.2fx", speed).replacingOccurrences(of: "0x", with: "x")
            runTask(startMsg: "Скорость: \(speedLabel)...", icon: "gauge.with.dots.needle.100percent", successMsg: "Скорость \(speedLabel) готова ✓", successIcon: "checkmark.circle.fill", at: location) {
                try await VideoProcessor.shared.changeSpeed(videoURL: file.url, speed: speed)
            }
            
        case .imageScale(let scale):
            let scaleLabel = String(format: "%.0f%%", scale * 100)
            runTask(startMsg: "Масштаб: \(scaleLabel)...", icon: "arrow.up.left.and.arrow.down.right", successMsg: "Масштаб \(scaleLabel) готов ✓", successIcon: "checkmark.circle.fill", at: location) {
                try ImageProcessor.shared.scaleImage(imageURL: file.url, factor: scale)
            }
            
        case .optionPDF(let optAction):
            runTask(startMsg: "\(optAction.rawValue)...", icon: "arrow.triangle.2.circlepath", successMsg: "\(optAction.rawValue) готово ✓", successIcon: "checkmark.circle.fill", at: location) {
                try DocumentProcessor.shared.executePDFOptionAction(optAction, on: file.url)
            }
            
        case .optionData(let optAction):
            runTask(startMsg: "\(optAction.rawValue)...", icon: "archivebox", successMsg: "\(optAction.rawValue) готово ✓", successIcon: "checkmark.circle.fill", at: location) {
                try DocumentProcessor.shared.executeDataOptionAction(optAction, on: file.url)
            }
            
        // MARK: - Command (Кроп / Кадрирование / Команды)
        case .cropVideo(let cropMode):
            runTask(startMsg: "Кадрирование: \(cropMode.rawValue)...", icon: "crop", successMsg: "\(cropMode.rawValue) готово ✓", successIcon: "checkmark.circle.fill", at: location) {
                try await VideoProcessor.shared.cropVideo(videoURL: file.url, mode: cropMode)
            }
            
        case .cropImage(let ratio):
            runTask(startMsg: "Кроп \(ratio.rawValue)...", icon: "crop", successMsg: "Кроп \(ratio.rawValue) готов ✓", successIcon: "crop", at: location) {
                try await ImageProcessor.shared.smartCrop(imageURL: file.url, ratio: ratio)
            }
            
        case .commandPDF(let cmdAction):
            runTask(startMsg: "\(cmdAction.rawValue)...", icon: "crop", successMsg: "\(cmdAction.rawValue) готово ✓", successIcon: "checkmark.circle.fill", at: location) {
                try DocumentProcessor.shared.executePDFCommandAction(cmdAction, on: file.url)
            }
            
        case .commandData(let cmdAction):
            runTask(startMsg: "\(cmdAction.rawValue)...", icon: "scissors", successMsg: "\(cmdAction.rawValue) готово ✓", successIcon: "checkmark.circle.fill", at: location) {
                try DocumentProcessor.shared.executeDataCommandAction(cmdAction, on: file.url)
            }
        }
    }
    
    private func runTask(
        startMsg: String,
        icon: String,
        successMsg: String,
        successIcon: String,
        at location: CGPoint,
        work: @Sendable @escaping () async throws -> URL?
    ) {
        OverlayWindowController.shared.showToast(message: startMsg, icon: icon, at: location)
        
        Task.detached(priority: .userInitiated) {
            do {
                let outURL = try await work()
                await MainActor.run {
                    OverlayWindowController.shared.showToast(message: successMsg, icon: successIcon, at: location)
                    if let out = outURL {
                        print("[ActionExecutor] Готово: \(out.lastPathComponent)")
                    }
                }
            } catch {
                await MainActor.run {
                    OverlayWindowController.shared.showToast(
                        message: error.localizedDescription,
                        icon: "exclamationmark.triangle.fill",
                        at: location
                    )
                    print("[ActionExecutor] Ошибка: \(error)")
                }
            }
        }
    }
}
