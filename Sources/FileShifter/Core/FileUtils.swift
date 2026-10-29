import Foundation

/// Централизованные утилиты для безопасной работы с файловой системой и генерации путей.
public enum FileUtils {
    
    /// Генерирует гарантированно уникальный URL для выходного файла в той же директории,
    /// предотвращая случайную перезапись существующего файла (добавляет _2, _3 и т.д.).
    ///
    /// - Parameters:
    ///   - inputURL: Исходный URL файла.
    ///   - suffix: Дополнительный суффикс (например: `_compressed`, `_clean`, `_A4`).
    ///   - ext: Новое расширение файла (например: `"png"`, `"webp"`, `"pdf"`). Если nil или пустое, сохраняется исходное.
    /// - Returns: Уникальный `URL`, которого гарантированно нет на диске на момент вызова.
    public static func uniqueURL(for inputURL: URL, suffix: String = "", extension ext: String? = nil) -> URL {
        let folder = inputURL.deletingLastPathComponent()
        let baseName = inputURL.deletingPathExtension().lastPathComponent
        
        let targetExtension: String
        if let customExt = ext, !customExt.isEmpty {
            targetExtension = customExt.trimmingCharacters(in: CharacterSet(charactersIn: "."))
        } else {
            targetExtension = inputURL.pathExtension
        }
        
        let extPart = targetExtension.isEmpty ? "" : ".\(targetExtension)"
        let primaryName = "\(baseName)\(suffix)\(extPart)"
        var targetURL = folder.appendingPathComponent(primaryName)
        
        var counter = 2
        while FileManager.default.fileExists(atPath: targetURL.path) {
            let nextName = "\(baseName)\(suffix)_\(counter)\(extPart)"
            targetURL = folder.appendingPathComponent(nextName)
            counter += 1
        }
        
        return targetURL
    }
    
    /// Генерирует уникальный URL для папки вывода (например, для страниц PDF или извлеченных изображений).
    ///
    /// - Parameters:
    ///   - inputURL: Исходный URL файла.
    ///   - suffix: Суффикс папки (например: `_pages`, `_images`, `_split`).
    /// - Returns: Уникальный `URL` директории, которой еще нет на диске.
    public static func uniqueFolderURL(for inputURL: URL, suffix: String) -> URL {
        let folder = inputURL.deletingLastPathComponent()
        let baseName = inputURL.deletingPathExtension().lastPathComponent
        
        var targetURL = folder.appendingPathComponent("\(baseName)\(suffix)")
        var counter = 2
        while FileManager.default.fileExists(atPath: targetURL.path) {
            targetURL = folder.appendingPathComponent("\(baseName)\(suffix)_\(counter)")
            counter += 1
        }
        
        return targetURL
    }
}
