import Foundation
import Cocoa

public enum FileCategory: Sendable {
    case image
    case video
    case pdf
    case data
    case document
    case other
}

public struct SelectedFile: Equatable, Sendable {
    public let url: URL
    public let name: String
    public let ext: String
    public let category: FileCategory
    
    public var isImage: Bool { category == .image }
    public var isVideo: Bool { category == .video }
    public var isPDF: Bool { category == .pdf }
    public var isData: Bool { category == .data }
    public var isDocument: Bool { category == .document }
    public var isSupported: Bool { category != .other }
    public var isCloudStub: Bool { ext == "icloud" || name.hasSuffix(".icloud") }
    
    public static let supportedImageExtensions: Set<String> = [
        "png", "jpg", "jpeg", "webp", "heic", "heif", "gif", "tiff", "bmp", "svg", "avif"
    ]
    
    public static let supportedVideoExtensions: Set<String> = [
        "mov", "mp4", "mkv", "avi", "webm", "m4v", "flv", "wmv", "3gp", "ts"
    ]
    
    public static let supportedPDFExtensions: Set<String> = [
        "pdf"
    ]
    
    public static let supportedDataExtensions: Set<String> = [
        "json", "yaml", "yml", "csv", "xml", "plist"
    ]
    
    public static let supportedDocExtensions: Set<String> = [
        "docx", "doc", "pages", "rtf", "rtfd", "md", "markdown", "txt", "html", "htm"
    ]
    
    public init(url: URL) {
        self.url = url
        self.name = url.lastPathComponent
        let extensionLower = url.pathExtension.lowercased()
        self.ext = extensionLower
        
        if Self.supportedImageExtensions.contains(extensionLower) {
            self.category = .image
        } else if Self.supportedVideoExtensions.contains(extensionLower) {
            self.category = .video
        } else if Self.supportedPDFExtensions.contains(extensionLower) {
            self.category = .pdf
        } else if Self.supportedDataExtensions.contains(extensionLower) {
            self.category = .data
        } else if Self.supportedDocExtensions.contains(extensionLower) {
            self.category = .document
        } else {
            self.category = .other
        }
    }
}

public final class FinderBridge: @unchecked Sendable {
    public static let shared = FinderBridge()
    
    private let compiledFinderScript: NSAppleScript?
    private let scriptLock = NSLock()
    
    private init() {
        let scriptSource = """
        tell application "Finder"
            set theSelection to selection as alias list
            if theSelection is not {} then
                return POSIX path of (item 1 of theSelection)
            end if
        end tell
        return ""
        """
        let script = NSAppleScript(source: scriptSource)
        script?.compileAndReturnError(nil)
        self.compiledFinderScript = script
    }
    
    /// Проверяет, что Finder сейчас активен, и возвращает выбранный в нем файл
    public func getSelectedFile() -> SelectedFile? {
        guard let frontApp = NSWorkspace.shared.frontmostApplication else { return nil }
        let currentBundleId = Bundle.main.bundleIdentifier
        guard frontApp.bundleIdentifier == "com.apple.finder" ||
              (currentBundleId != nil && frontApp.bundleIdentifier == currentBundleId) else {
            return nil
        }
        
        guard let script = compiledFinderScript else { return nil }
        
        var error: NSDictionary?
        let descriptor: NSAppleEventDescriptor
        scriptLock.lock()
        descriptor = script.executeAndReturnError(&error)
        scriptLock.unlock()
        
        if let error = error {
            print("[FinderBridge] AppleScript Error: \(error)")
            return nil
        }
        
        let rawPath = descriptor.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !rawPath.isEmpty else { return nil }
        
        let fileURL: URL
        if rawPath.hasPrefix("file://") {
            guard let u = URL(string: rawPath) else { return nil }
            fileURL = u
        } else {
            fileURL = URL(fileURLWithPath: rawPath)
        }
        
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: fileURL.path, isDirectory: &isDir), !isDir.boolValue {
            return SelectedFile(url: fileURL)
        }
        
        return nil
    }
}
