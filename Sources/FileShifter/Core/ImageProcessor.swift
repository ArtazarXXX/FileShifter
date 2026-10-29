import Foundation
import Cocoa
import CoreGraphics
import CoreImage
import Vision
import UniformTypeIdentifiers
import PDFKit

public enum ImageTargetFormat: String, CaseIterable, Sendable {
    case webp = "WebP"
    case avif = "AVIF"
    case png = "PNG"
    case jpg = "JPG"
    case pdf = "PDF"
    
    public var fileExtension: String {
        switch self {
        case .webp: return "webp"
        case .avif: return "avif"
        case .png: return "png"
        case .jpg: return "jpg"
        case .pdf: return "pdf"
        }
    }
}

public enum MagicAction: String, CaseIterable, Sendable {
    case removeBackground = "Удалить фон"
    case compress = "Сжать"
    case ocr = "OCR текст"
    case cleanMetadata = "Очистить EXIF"
    case copyBase64 = "Копировать Base64"
    case imageInfo = "Инфо о файле"
    case avatar = "Аватарка"
    case rotate90 = "Поворот (+90°)"
    
    public var icon: String {
        switch self {
        case .removeBackground: return "wand.and.stars"
        case .compress: return "arrow.down.right.and.arrow.up.left"
        case .ocr: return "doc.text.viewfinder"
        case .cleanMetadata: return "lock.shield"
        case .copyBase64: return "curlybraces"
        case .imageInfo: return "info.circle"
        case .avatar: return "person.crop.circle"
        case .rotate90: return "rotate.right"
        }
    }
}

public enum CropRatio: String, CaseIterable, Sendable {
    case square = "1:1 Квадрат"
    case widescreen = "16:9 Широкий"
    case story = "9:16 Сторис"
    case classic = "4:3 Фото"
    case portrait = "4:5 Пост"
    case film = "3:2 Стандарт"
    
    public var icon: String {
        switch self {
        case .square: return "square"
        case .widescreen: return "rectangle.ratio.16.to.9"
        case .story: return "rectangle.portrait"
        case .classic: return "rectangle.ratio.4.to.3"
        case .portrait: return "rectangle.portrait.fill"
        case .film: return "film"
        }
    }
    
    public var ratioValue: CGFloat {
        switch self {
        case .square: return 1.0
        case .widescreen: return 16.0 / 9.0
        case .story: return 9.0 / 16.0
        case .classic: return 4.0 / 3.0
        case .portrait: return 4.0 / 5.0
        case .film: return 3.0 / 2.0
        }
    }
    
    public var suffix: String {
        switch self {
        case .square: return "_1x1"
        case .widescreen: return "_16x9"
        case .story: return "_9x16"
        case .classic: return "_4x3"
        case .portrait: return "_4x5"
        case .film: return "_3x2"
        }
    }
}

public struct ImageMetadata: Sendable {
    public let fileName: String
    public let width: Int
    public let height: Int
    public let fileSizeString: String
    public let megaPixels: String
    public let aspectRatio: String
    public let colorProfile: String
    public let hasGPS: Bool
}

public final class ImageProcessor: @unchecked Sendable {
    public static let shared = ImageProcessor()
    private let ciContext = CIContext(options: [.useSoftwareRenderer: false])
    
    private init() {}
    
    private func makeOutputPath(for inputURL: URL, suffix: String, ext: String) -> URL {
        FileUtils.uniqueURL(for: inputURL, suffix: suffix, extension: ext)
    }
    
    private func findExecutable(named name: String) -> String? {
        ProcessRunner.findExecutable(named: name)
    }
    
    private func exportIntermediatePNG(from imageURL: URL) throws -> URL {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".png")
        guard let imageSource = CGImageSourceCreateWithURL(imageURL as CFURL, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            throw NSError(domain: "FileShifter", code: 1, userInfo: [NSLocalizedDescriptionKey: "Ошибка чтения исходного изображения"])
        }
        guard let dest = CGImageDestinationCreateWithURL(tempURL as CFURL, UTType.png.identifier as CFString, 1, nil) else {
            throw NSError(domain: "FileShifter", code: 2, userInfo: [NSLocalizedDescriptionKey: "Ошибка создания временного файла"])
        }
        CGImageDestinationAddImage(dest, cgImage, nil)
        guard CGImageDestinationFinalize(dest) else {
            throw NSError(domain: "FileShifter", code: 3, userInfo: [NSLocalizedDescriptionKey: "Ошибка записи временного файла"])
        }
        return tempURL
    }
    
    // MARK: - Конвертация форматов
    
    public func convert(imageURL: URL, to format: ImageTargetFormat) throws -> URL {
        switch format {
        case .webp:
            return try convertToWebP(imageURL: imageURL)
        case .avif:
            return try convertToAVIF(imageURL: imageURL)
        case .pdf:
            return try convertToPDF(imageURL: imageURL)
        case .png, .jpg:
            return try convertToStandardImage(imageURL: imageURL, format: format)
        }
    }
    
    private func convertToWebP(imageURL: URL) throws -> URL {
        guard let cwebpPath = findExecutable(named: "cwebp") else {
            throw NSError(domain: "FileShifter", code: 10, userInfo: [NSLocalizedDescriptionKey: "Утилита cwebp не найдена"])
        }
        let tempPNG = try exportIntermediatePNG(from: imageURL)
        defer { try? FileManager.default.removeItem(at: tempPNG) }
        
        let outputURL = makeOutputPath(for: imageURL, suffix: "", ext: "webp")
        let result = try ProcessRunner.run(executable: cwebpPath, arguments: ["-q", "85", tempPNG.path, "-o", outputURL.path])
        
        guard result.isSuccess, FileManager.default.fileExists(atPath: outputURL.path) else {
            throw NSError(domain: "FileShifter", code: 11, userInfo: [NSLocalizedDescriptionKey: "Ошибка конвертации в WebP: \(result.stderrString)"])
        }
        return outputURL
    }
    
    private func convertToAVIF(imageURL: URL) throws -> URL {
        guard let avifencPath = findExecutable(named: "avifenc") else {
            throw NSError(domain: "FileShifter", code: 12, userInfo: [NSLocalizedDescriptionKey: "Утилита avifenc не найдена"])
        }
        let tempPNG = try exportIntermediatePNG(from: imageURL)
        defer { try? FileManager.default.removeItem(at: tempPNG) }
        
        let outputURL = makeOutputPath(for: imageURL, suffix: "", ext: "avif")
        let result = try ProcessRunner.run(executable: avifencPath, arguments: ["-s", "6", "-j", "all", tempPNG.path, outputURL.path])
        
        guard result.isSuccess, FileManager.default.fileExists(atPath: outputURL.path) else {
            throw NSError(domain: "FileShifter", code: 13, userInfo: [NSLocalizedDescriptionKey: "Ошибка конвертации в AVIF: \(result.stderrString)"])
        }
        return outputURL
    }
    
    private func convertToStandardImage(imageURL: URL, format: ImageTargetFormat) throws -> URL {
        guard let imageSource = CGImageSourceCreateWithURL(imageURL as CFURL, nil),
              let originalCGImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            throw NSError(domain: "FileShifter", code: 14, userInfo: [NSLocalizedDescriptionKey: "Не удалось прочитать исходное изображение"])
        }
        
        let cgImage: CGImage
        if format == .jpg {
            // Если исходное изображение содержит прозрачность (PNG/WebP),
            // отрисовываем его на белом фоне в пространстве sRGB, предотвращая заливку черным
            let width = originalCGImage.width
            let height = originalCGImage.height
            let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
            let bitmapInfo = CGImageAlphaInfo.noneSkipLast.rawValue
            
            if let context = CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: colorSpace,
                bitmapInfo: bitmapInfo
            ) {
                context.setFillColor(CGColor.white)
                context.fill(CGRect(x: 0, y: 0, width: width, height: height))
                context.draw(originalCGImage, in: CGRect(x: 0, y: 0, width: width, height: height))
                cgImage = context.makeImage() ?? originalCGImage
            } else {
                cgImage = originalCGImage
            }
        } else {
            cgImage = originalCGImage
        }
        
        let outputURL = makeOutputPath(for: imageURL, suffix: "", ext: format.fileExtension)
        let utType = format == .png ? UTType.png : UTType.jpeg
        guard let destination = CGImageDestinationCreateWithURL(outputURL as CFURL, utType.identifier as CFString, 1, nil) else {
            throw NSError(domain: "FileShifter", code: 15, userInfo: [NSLocalizedDescriptionKey: "Не удалось создать целевой файл"])
        }
        
        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: 0.92
        ]
        CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)
        guard CGImageDestinationFinalize(destination) else {
            throw NSError(domain: "FileShifter", code: 16, userInfo: [NSLocalizedDescriptionKey: "Ошибка сохранения файла"])
        }
        return outputURL
    }
    
    private func convertToPDF(imageURL: URL) throws -> URL {
        guard let nsImage = NSImage(contentsOf: imageURL) else {
            throw NSError(domain: "FileShifter", code: 17, userInfo: [NSLocalizedDescriptionKey: "Не удалось загрузить изображение"])
        }
        let pdfDocument = PDFDocument()
        guard let pdfPage = PDFPage(image: nsImage) else {
            throw NSError(domain: "FileShifter", code: 18, userInfo: [NSLocalizedDescriptionKey: "Не удалось сформировать страницу PDF"])
        }
        pdfDocument.insert(pdfPage, at: 0)
        let outputURL = makeOutputPath(for: imageURL, suffix: "", ext: "pdf")
        guard pdfDocument.write(to: outputURL) else {
            throw NSError(domain: "FileShifter", code: 19, userInfo: [NSLocalizedDescriptionKey: "Ошибка записи PDF"])
        }
        return outputURL
    }
    
    // MARK: - Магические действия (Control)
    
    public func executeMagicAction(_ action: MagicAction, on imageURL: URL) async throws -> (URL?, String?, ImageMetadata?) {
        switch action {
        case .removeBackground:
            let outURL = try await removeBackground(imageURL: imageURL)
            return (outURL, nil, nil)
            
        case .compress:
            let outURL = try compressGuaranteed(imageURL: imageURL)
            return (outURL, nil, nil)
            
        case .ocr:
            let text = try await recognizeText(imageURL: imageURL)
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                throw NSError(domain: "FileShifter", code: 31, userInfo: [NSLocalizedDescriptionKey: "Текст на изображении не обнаружен"])
            }
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.declareTypes([.string], owner: nil)
            pasteboard.setString(trimmed, forType: .string)
            return (nil, trimmed, nil)
            
        case .cleanMetadata:
            let outURL = try stripMetadata(imageURL: imageURL)
            return (outURL, nil, nil)
            
        case .copyBase64:
            let base64 = try copyBase64(imageURL: imageURL)
            return (nil, base64, nil)
            
        case .imageInfo:
            let meta = try getImageMetadata(imageURL: imageURL)
            return (nil, nil, meta)
            
        case .avatar:
            let outURL = try await makeSmartFaceAvatar(imageURL: imageURL)
            return (outURL, nil, nil)
            
        case .rotate90:
            let outURL = try rotate(imageURL: imageURL)
            return (outURL, nil, nil)
        }
    }
    
    /// Очистка метаданных (EXIF, GPS, Камера)
    public func stripMetadata(imageURL: URL) throws -> URL {
        guard let source = CGImageSourceCreateWithURL(imageURL as CFURL, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw NSError(domain: "FileShifter", code: 80, userInfo: [NSLocalizedDescriptionKey: "Ошибка чтения файла"])
        }
        
        let ext = imageURL.pathExtension.lowercased()
        let isPng = ext == "png"
        let outputURL = makeOutputPath(for: imageURL, suffix: "_clean", ext: isPng ? "png" : "jpg")
        let utType = isPng ? UTType.png : UTType.jpeg
        
        guard let destination = CGImageDestinationCreateWithURL(outputURL as CFURL, utType.identifier as CFString, 1, nil) else {
            throw NSError(domain: "FileShifter", code: 81, userInfo: [NSLocalizedDescriptionKey: "Ошибка создания файла"])
        }
        
        // Передаем пустые свойства, чтобы стереть EXIF, GPS и TIFF теги
        let emptyProperties = [String: Any]() as CFDictionary
        CGImageDestinationAddImage(destination, cgImage, emptyProperties)
        guard CGImageDestinationFinalize(destination) else {
            throw NSError(domain: "FileShifter", code: 82, userInfo: [NSLocalizedDescriptionKey: "Ошибка записи"])
        }
        return outputURL
    }
    
    /// Копирование в Base64 Data URL
    public func copyBase64(imageURL: URL) throws -> String {
        let data = try Data(contentsOf: imageURL)
        let ext = imageURL.pathExtension.lowercased()
        let mime: String
        switch ext {
        case "jpg", "jpeg": mime = "image/jpeg"
        case "png": mime = "image/png"
        case "webp": mime = "image/webp"
        case "avif": mime = "image/avif"
        case "svg": mime = "image/svg+xml"
        case "gif": mime = "image/gif"
        default: mime = "image/png"
        }
        let dataURLString = "data:\(mime);base64,\(data.base64EncodedString())"
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.setString(dataURLString, forType: .string)
        return "Base64 скопирован (\(data.count / 1024) КБ)"
    }
    
    /// Получение информации о файле
    public func getImageMetadata(imageURL: URL) throws -> ImageMetadata {
        guard let source = CGImageSourceCreateWithURL(imageURL as CFURL, nil) else {
            throw NSError(domain: "FileShifter", code: 90, userInfo: [NSLocalizedDescriptionKey: "Ошибка чтения"])
        }
        
        let properties = (CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]) ?? [:]
        let width = (properties[kCGImagePropertyPixelWidth] as? Int) ?? 0
        let height = (properties[kCGImagePropertyPixelHeight] as? Int) ?? 0
        
        let fileSize = (try? FileManager.default.attributesOfItem(atPath: imageURL.path)[.size] as? Int64) ?? 0
        let sizeString: String
        if fileSize > 1024 * 1024 {
            sizeString = String(format: "%.1f МБ", Double(fileSize) / (1024 * 1024))
        } else {
            sizeString = "\(fileSize / 1024) КБ"
        }
        
        let mp = Double(width * height) / 1_000_000.0
        let mpString = String(format: "%.1f MP", mp)
        
        let gcdVal = gcd(width, height)
        let ratioStr = gcdVal > 0 ? "\(width / gcdVal):\(height / gcdVal)" : "\(width)x\(height)"
        
        let colorModel = (properties[kCGImagePropertyColorModel] as? String) ?? "RGB"
        let hasGPS = properties[kCGImagePropertyGPSDictionary] != nil
        
        return ImageMetadata(
            fileName: imageURL.lastPathComponent,
            width: width,
            height: height,
            fileSizeString: sizeString,
            megaPixels: mpString,
            aspectRatio: ratioStr,
            colorProfile: colorModel,
            hasGPS: hasGPS
        )
    }
    
    private func gcd(_ a: Int, _ b: Int) -> Int {
        var x = a, y = b
        while y != 0 {
            let t = y
            y = x % y
            x = t
        }
        return abs(x)
    }
    
    // MARK: - Умный нейросетевой кроп (Command)
    
    public func smartCrop(imageURL: URL, ratio: CropRatio) async throws -> URL {
        guard let imageSource = CGImageSourceCreateWithURL(imageURL as CFURL, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            throw NSError(domain: "FileShifter", code: 100, userInfo: [NSLocalizedDescriptionKey: "Ошибка загрузки файла"])
        }
        
        let imgWidth = CGFloat(cgImage.width)
        let imgHeight = CGFloat(cgImage.height)
        let targetRatio = ratio.ratioValue
        
        // Сначала ищем лица (если есть человек — приоритет лицу)
        let faceRequest = VNDetectFaceRectanglesRequest()
        let saliencyRequest = VNGenerateAttentionBasedSaliencyImageRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try? handler.perform([faceRequest, saliencyRequest])
        
        var focusCenter = CGPoint(x: imgWidth / 2.0, y: imgHeight / 2.0)
        
        if let face = faceRequest.results?.first {
            let box = face.boundingBox
            focusCenter = CGPoint(
                x: (box.origin.x + box.width / 2.0) * imgWidth,
                y: (1.0 - (box.origin.y + box.height / 2.0)) * imgHeight
            )
        } else if let saliency = saliencyRequest.results?.first,
                  let objects = saliency.salientObjects, !objects.isEmpty {
            // Берем центр главного объекта внимания
            let mainObj = objects[0].boundingBox
            focusCenter = CGPoint(
                x: (mainObj.origin.x + mainObj.width / 2.0) * imgWidth,
                y: (1.0 - (mainObj.origin.y + mainObj.height / 2.0)) * imgHeight
            )
        }
        
        // Рассчитываем размер кропа под пропорцию targetRatio (W / H)
        var cropWidth: CGFloat
        var cropHeight: CGFloat
        let currentRatio = imgWidth / imgHeight
        
        if currentRatio > targetRatio {
            // Картинка шире чем нужно — режем по ширине
            cropHeight = imgHeight
            cropWidth = cropHeight * targetRatio
        } else {
            // Картинка выше чем нужно — режем по высоте
            cropWidth = imgWidth
            cropHeight = cropWidth / targetRatio
        }
        
        // Кадрируем вокруг focusCenter
        var cropX = focusCenter.x - cropWidth / 2.0
        var cropY = focusCenter.y - cropHeight / 2.0
        
        if cropX < 0 { cropX = 0 }
        if cropY < 0 { cropY = 0 }
        if cropX + cropWidth > imgWidth { cropX = imgWidth - cropWidth }
        if cropY + cropHeight > imgHeight { cropY = imgHeight - cropHeight }
        
        let cropRect = CGRect(x: cropX, y: cropY, width: cropWidth, height: cropHeight)
        guard let croppedCGImage = cgImage.cropping(to: cropRect) else {
            throw NSError(domain: "FileShifter", code: 101, userInfo: [NSLocalizedDescriptionKey: "Ошибка кадрирования"])
        }
        
        let ext = imageURL.pathExtension.lowercased()
        let outputURL = makeOutputPath(for: imageURL, suffix: ratio.suffix, ext: ext)
        let utType = UTType(filenameExtension: ext) ?? .jpeg
        
        guard let destination = CGImageDestinationCreateWithURL(outputURL as CFURL, utType.identifier as CFString, 1, nil) else {
            throw NSError(domain: "FileShifter", code: 102, userInfo: [NSLocalizedDescriptionKey: "Ошибка сохранения"])
        }
        CGImageDestinationAddImage(destination, croppedCGImage, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw NSError(domain: "FileShifter", code: 103, userInfo: [NSLocalizedDescriptionKey: "Ошибка записи"])
        }
        return outputURL
    }
    
    // MARK: - Вспомогательные функции
    
    private func removeBackground(imageURL: URL) async throws -> URL {
        guard let ciImage = CIImage(contentsOf: imageURL) else {
            throw NSError(domain: "FileShifter", code: 20, userInfo: [NSLocalizedDescriptionKey: "Не удалось загрузить изображение"])
        }
        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(ciImage: ciImage)
        try handler.perform([request])
        
        guard let result = request.results?.first else {
            throw NSError(domain: "FileShifter", code: 21, userInfo: [NSLocalizedDescriptionKey: "Vision не обнаружил объект"])
        }
        
        let maskPixelBuffer = try result.generateScaledMaskForImage(forInstances: result.allInstances, from: handler)
        let maskCI = CIImage(cvPixelBuffer: maskPixelBuffer)
        
        let filter = CIFilter(name: "CIBlendWithMask")!
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(CIImage.empty(), forKey: kCIInputBackgroundImageKey)
        filter.setValue(maskCI, forKey: kCIInputMaskImageKey)
        
        guard let outputCI = filter.outputImage,
              let cgImage = ciContext.createCGImage(outputCI, from: outputCI.extent) else {
            throw NSError(domain: "FileShifter", code: 22, userInfo: [NSLocalizedDescriptionKey: "Ошибка наложения маски"])
        }
        
        let outputURL = makeOutputPath(for: imageURL, suffix: "_nobg", ext: "png")
        guard let destination = CGImageDestinationCreateWithURL(outputURL as CFURL, UTType.png.identifier as CFString, 1, nil) else {
            throw NSError(domain: "FileShifter", code: 23, userInfo: [NSLocalizedDescriptionKey: "Не удалось создать целевой PNG"])
        }
        CGImageDestinationAddImage(destination, cgImage, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw NSError(domain: "FileShifter", code: 24, userInfo: [NSLocalizedDescriptionKey: "Ошибка сохранения PNG"])
        }
        return outputURL
    }
    
    private func compressGuaranteed(imageURL: URL) throws -> URL {
        let originalAttributes = try FileManager.default.attributesOfItem(atPath: imageURL.path)
        let originalSize = (originalAttributes[.size] as? Int64) ?? 0
        guard originalSize > 0 else {
            throw NSError(domain: "FileShifter", code: 70, userInfo: [NSLocalizedDescriptionKey: "Файл пуст"])
        }
        
        let ext = imageURL.pathExtension.lowercased()
        let tempDir = FileManager.default.temporaryDirectory
        
        let trial1URL = tempDir.appendingPathComponent(UUID().uuidString + ".\(ext == "png" ? "png" : "jpg")")
        _ = try? ProcessRunner.run(executable: "/usr/bin/sips", arguments: ["-s", "format", ext == "png" ? "png" : "jpeg", "-s", "formatOptions", "65", imageURL.path, "--out", trial1URL.path], captureOutput: false)
        
        let size1: Int64 = (try? FileManager.default.attributesOfItem(atPath: trial1URL.path)[.size] as? Int64) ?? 0
        if size1 > 0 && size1 < originalSize {
            let finalURL = makeOutputPath(for: imageURL, suffix: "_compressed", ext: trial1URL.pathExtension)
            try? FileManager.default.removeItem(at: finalURL)
            try FileManager.default.moveItem(at: trial1URL, to: finalURL)
            return finalURL
        }
        try? FileManager.default.removeItem(at: trial1URL)
        
        if ProcessRunner.findExecutable(named: "cwebp") != nil {
            let trialWebP = tempDir.appendingPathComponent(UUID().uuidString + ".webp")
            _ = try? ProcessRunner.run(executable: "cwebp", arguments: ["-q", "75", imageURL.path, "-o", trialWebP.path], captureOutput: false)
            
            let sizeWebP = (try? FileManager.default.attributesOfItem(atPath: trialWebP.path)[.size] as? Int64) ?? 0
            if sizeWebP > 0 && sizeWebP < originalSize {
                let finalURL = makeOutputPath(for: imageURL, suffix: "_compressed", ext: "webp")
                try? FileManager.default.removeItem(at: finalURL)
                try FileManager.default.moveItem(at: trialWebP, to: finalURL)
                return finalURL
            }
            try? FileManager.default.removeItem(at: trialWebP)
        }
        
        let trialJpg = tempDir.appendingPathComponent(UUID().uuidString + ".jpg")
        _ = try? ProcessRunner.run(executable: "/usr/bin/sips", arguments: ["-s", "format", "jpeg", "-s", "formatOptions", "50", imageURL.path, "--out", trialJpg.path], captureOutput: false)
        
        let sizeJpg = (try? FileManager.default.attributesOfItem(atPath: trialJpg.path)[.size] as? Int64) ?? 0
        if sizeJpg > 0 && sizeJpg < originalSize {
            let finalURL = makeOutputPath(for: imageURL, suffix: "_compressed", ext: "jpg")
            try? FileManager.default.removeItem(at: finalURL)
            try FileManager.default.moveItem(at: trialJpg, to: finalURL)
            return finalURL
        }
        try? FileManager.default.removeItem(at: trialJpg)
        
        throw NSError(
            domain: "FileShifter",
            code: 71,
            userInfo: [NSLocalizedDescriptionKey: "Файл уже максимально сжат (\(originalSize / 1024) КБ)"]
        )
    }
    
    private func recognizeText(imageURL: URL) async throws -> String {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["ru-RU", "en-US", "uk-UA"]
        
        let handler = VNImageRequestHandler(url: imageURL, options: [:])
        try handler.perform([request])
        
        guard let observations = request.results, !observations.isEmpty else {
            return ""
        }
        let recognizedStrings = observations.compactMap { $0.topCandidates(1).first?.string }
        return recognizedStrings.joined(separator: "\n")
    }
    
    private func rotate(imageURL: URL) throws -> URL {
        guard let ciImage = CIImage(contentsOf: imageURL) else {
            throw NSError(domain: "FileShifter", code: 50, userInfo: [NSLocalizedDescriptionKey: "Ошибка загрузки файла"])
        }
        let rotated = ciImage.oriented(.right)
        guard let cgImage = ciContext.createCGImage(rotated, from: rotated.extent) else {
            throw NSError(domain: "FileShifter", code: 51, userInfo: [NSLocalizedDescriptionKey: "Ошибка поворота"])
        }
        let ext = imageURL.pathExtension.lowercased()
        let outputURL = makeOutputPath(for: imageURL, suffix: "_rotated", ext: ext)
        let utType = UTType(filenameExtension: ext) ?? .png
        guard let destination = CGImageDestinationCreateWithURL(outputURL as CFURL, utType.identifier as CFString, 1, nil) else {
            throw NSError(domain: "FileShifter", code: 52, userInfo: [NSLocalizedDescriptionKey: "Ошибка создания файла"])
        }
        CGImageDestinationAddImage(destination, cgImage, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw NSError(domain: "FileShifter", code: 53, userInfo: [NSLocalizedDescriptionKey: "Ошибка записи"])
        }
        return outputURL
    }
    
    private func makeSmartFaceAvatar(imageURL: URL) async throws -> URL {
        guard let imageSource = CGImageSourceCreateWithURL(imageURL as CFURL, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            throw NSError(domain: "FileShifter", code: 60, userInfo: [NSLocalizedDescriptionKey: "Ошибка загрузки файла"])
        }
        
        let imgWidth = CGFloat(cgImage.width)
        let imgHeight = CGFloat(cgImage.height)
        
        let faceRequest = VNDetectFaceRectanglesRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try? handler.perform([faceRequest])
        
        var cropCenter = CGPoint(x: imgWidth / 2.0, y: imgHeight / 2.0)
        var cropSide = min(imgWidth, imgHeight)
        
        if let firstFace = faceRequest.results?.first {
            let faceBox = firstFace.boundingBox
            let faceCenterX = (faceBox.origin.x + faceBox.width / 2.0) * imgWidth
            let faceCenterY = (1.0 - (faceBox.origin.y + faceBox.height / 2.0)) * imgHeight
            cropCenter = CGPoint(x: faceCenterX, y: faceCenterY)
            let faceSize = max(faceBox.width * imgWidth, faceBox.height * imgHeight)
            cropSide = min(max(faceSize * 2.2, 200), min(imgWidth, imgHeight))
        }
        
        var cropX = cropCenter.x - cropSide / 2.0
        var cropY = cropCenter.y - cropSide / 2.0
        if cropX < 0 { cropX = 0 }
        if cropY < 0 { cropY = 0 }
        if cropX + cropSide > imgWidth { cropX = imgWidth - cropSide }
        if cropY + cropSide > imgHeight { cropY = imgHeight - cropSide }
        
        let cropRect = CGRect(x: cropX, y: cropY, width: cropSide, height: cropSide)
        guard let croppedCGImage = cgImage.cropping(to: cropRect) else {
            throw NSError(domain: "FileShifter", code: 61, userInfo: [NSLocalizedDescriptionKey: "Ошибка кадрирования"])
        }
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        let sideInt = Int(cropSide)
        guard let context = CGContext(data: nil, width: sideInt, height: sideInt, bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo) else {
            throw NSError(domain: "FileShifter", code: 62, userInfo: [NSLocalizedDescriptionKey: "Ошибка графического контекста"])
        }
        
        let circlePath = CGPath(ellipseIn: CGRect(x: 0, y: 0, width: cropSide, height: cropSide), transform: nil)
        context.addPath(circlePath)
        context.clip()
        context.draw(croppedCGImage, in: CGRect(x: 0, y: 0, width: cropSide, height: cropSide))
        
        guard let avatarCGImage = context.makeImage() else {
            throw NSError(domain: "FileShifter", code: 63, userInfo: [NSLocalizedDescriptionKey: "Ошибка создания аватара"])
        }
        
        let outputURL = makeOutputPath(for: imageURL, suffix: "_avatar", ext: "png")
        guard let destination = CGImageDestinationCreateWithURL(outputURL as CFURL, UTType.png.identifier as CFString, 1, nil) else {
            throw NSError(domain: "FileShifter", code: 64, userInfo: [NSLocalizedDescriptionKey: "Ошибка создания PNG"])
        }
        CGImageDestinationAddImage(destination, avatarCGImage, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw NSError(domain: "FileShifter", code: 65, userInfo: [NSLocalizedDescriptionKey: "Ошибка записи аватара"])
        }
        return outputURL
    }
    
    // MARK: - Масштабирование размера фото (Option)
    
    public func scaleImage(imageURL: URL, factor: Double) throws -> URL {
        guard let imageSource = CGImageSourceCreateWithURL(imageURL as CFURL, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            throw NSError(domain: "FileShifter", code: 70, userInfo: [NSLocalizedDescriptionKey: "Не удалось загрузить изображение"])
        }
        
        let newWidth = max(1, Int(Double(cgImage.width) * factor))
        let newHeight = max(1, Int(Double(cgImage.height) * factor))
        
        let colorSpace = cgImage.colorSpace ?? CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        
        guard let context = CGContext(
            data: nil,
            width: newWidth,
            height: newHeight,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            throw NSError(domain: "FileShifter", code: 71, userInfo: [NSLocalizedDescriptionKey: "Ошибка создания графического контекста"])
        }
        
        context.interpolationQuality = .high
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        
        guard let scaledCGImage = context.makeImage() else {
            throw NSError(domain: "FileShifter", code: 72, userInfo: [NSLocalizedDescriptionKey: "Ошибка рендеринга изображения"])
        }
        
        let factorStr = factor.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0fx", factor) : String(format: "%.2fx", factor).replacingOccurrences(of: "0x", with: "x")
        let suffix = "_\(factorStr)"
        let ext = imageURL.pathExtension.isEmpty ? "png" : imageURL.pathExtension.lowercased()
        let outputURL = makeOutputPath(for: imageURL, suffix: suffix, ext: ext)
        
        let uti: CFString = (ext == "jpg" || ext == "jpeg") ? (UTType.jpeg.identifier as CFString) : (UTType.png.identifier as CFString)
        guard let destination = CGImageDestinationCreateWithURL(outputURL as CFURL, uti, 1, nil) else {
            throw NSError(domain: "FileShifter", code: 73, userInfo: [NSLocalizedDescriptionKey: "Ошибка создания выходного файла"])
        }
        
        CGImageDestinationAddImage(destination, scaledCGImage, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw NSError(domain: "FileShifter", code: 74, userInfo: [NSLocalizedDescriptionKey: "Ошибка сохранения масштабированного изображения"])
        }
        
        return outputURL
    }
}
