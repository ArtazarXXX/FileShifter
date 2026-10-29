import Foundation

/// Результат выполнения внешнего процесса.
public struct ProcessResult: Sendable {
    public let exitCode: Int32
    public let stdoutData: Data
    public let stderrData: Data
    
    public var stdoutString: String {
        String(data: stdoutData, encoding: .utf8) ?? ""
    }
    
    public var stderrString: String {
        String(data: stderrData, encoding: .utf8) ?? ""
    }
    
    public var isSuccess: Bool {
        exitCode == 0
    }
}

/// Централизованный менеджер для безопасного поиска и запуска CLI-утилит (ffmpeg, ffprobe, cwebp, avifenc, zip, textutil, sips).
public enum ProcessRunner {
    private static var executableCache: [String: String] = [:]
    private static let lock = NSLock()
    
    /// Находит путь к исполняемому файлу в системе (Homebrew Apple Silicon, Homebrew Intel, системные пути, PATH).
    public static func findExecutable(named name: String) -> String? {
        lock.lock()
        defer { lock.unlock() }
        
        if let cached = executableCache[name] {
            return cached
        }
        
        var candidates = [
            "/opt/homebrew/bin/\(name)",
            "/usr/local/bin/\(name)",
            "/usr/bin/\(name)",
            "/bin/\(name)"
        ]
        
        if let envPath = ProcessInfo.processInfo.environment["PATH"] {
            for dir in envPath.split(separator: ":") {
                candidates.append("\(dir)/\(name)")
            }
        }
        
        for path in candidates {
            if FileManager.default.isExecutableFile(atPath: path) {
                executableCache[name] = path
                return path
            }
        }
        return nil
    }
    
    /// Выполняет процесс с защитой от дедлока буферов Pipe и перехватывает вывод.
    ///
    /// - Parameters:
    ///   - executable: Имя утилиты ("ffmpeg") или абсолютный путь ("/usr/bin/zip").
    ///   - arguments: Аргументы командной строки.
    ///   - currentDirectoryURL: Опциональная рабочая директория.
    ///   - captureOutput: Перехватывать ли stdout и stderr (по умолчанию true).
    /// - Returns: `ProcessResult` с кодом возврата и данными вывода.
    @discardableResult
    public static func run(
        executable: String,
        arguments: [String],
        currentDirectoryURL: URL? = nil,
        captureOutput: Bool = true
    ) throws -> ProcessResult {
        let execPath: String
        if executable.hasPrefix("/") {
            guard FileManager.default.isExecutableFile(atPath: executable) else {
                throw NSError(domain: "ProcessRunner", code: 404, userInfo: [NSLocalizedDescriptionKey: "Исполняемый файл не найден: \(executable)"])
            }
            execPath = executable
        } else {
            guard let resolved = findExecutable(named: executable) else {
                throw NSError(domain: "ProcessRunner", code: 404, userInfo: [NSLocalizedDescriptionKey: "Утилита \(executable) не найдена в системе"])
            }
            execPath = resolved
        }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: execPath)
        process.arguments = arguments
        if let currentDirectoryURL = currentDirectoryURL {
            process.currentDirectoryURL = currentDirectoryURL
        }
        
        process.standardInput = FileHandle.nullDevice
        
        let outPipe = Pipe()
        let errPipe = Pipe()
        
        if captureOutput {
            process.standardOutput = outPipe
            process.standardError = errPipe
        } else {
            process.standardOutput = FileHandle.nullDevice
            process.standardError = FileHandle.nullDevice
        }
        
        try process.run()
        
        var stdoutData = Data()
        var stderrData = Data()
        
        if captureOutput {
            // Асинхронное чтение предотвращает зависание процесса при превышении 64KB буфера пайпа
            let outHandle = outPipe.fileHandleForReading
            let errHandle = errPipe.fileHandleForReading
            
            let group = DispatchGroup()
            
            group.enter()
            DispatchQueue.global(qos: .userInitiated).async {
                stdoutData = outHandle.readDataToEndOfFile()
                group.leave()
            }
            
            group.enter()
            DispatchQueue.global(qos: .userInitiated).async {
                stderrData = errHandle.readDataToEndOfFile()
                group.leave()
            }
            
            process.waitUntilExit()
            group.wait()
        } else {
            process.waitUntilExit()
        }
        
        return ProcessResult(exitCode: process.terminationStatus, stdoutData: stdoutData, stderrData: stderrData)
    }
}
