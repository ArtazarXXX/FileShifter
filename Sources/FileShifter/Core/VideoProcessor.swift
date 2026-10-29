import Foundation
import Cocoa
import AVFoundation
import Vision

public enum VideoTargetFormat: String, CaseIterable, Sendable {
    case movieRemux = "Фильм"
    case mp4 = "MP4"
    case webm = "WebM"
    case gif = "GIF"
    case mp3 = "MP3"
    case mov = "MOV"
    
    public var fileExtension: String {
        switch self {
        case .movieRemux: return "mp4"
        case .mp4: return "mp4"
        case .webm: return "webm"
        case .gif: return "gif"
        case .mp3: return "mp3"
        case .mov: return "mov"
        }
    }
    
    public var icon: String {
        switch self {
        case .movieRemux: return "popcorn.fill"
        case .mp4: return "film"
        case .webm: return "globe"
        case .gif: return "play.rectangle.on.rectangle"
        case .mp3: return "music.note"
        case .mov: return "applelogo"
        }
    }
}

public enum VideoMagicAction: String, CaseIterable, Sendable {
    case compressTelegram = "Сжать <25МБ"
    case mute = "Без звука"
    case gif5sec = "5 сек GIF"
    case gif15sec = "15 сек GIF"
    case rotate90 = "Поворот"
    case videoInfo = "Инфо"
    
    public var icon: String {
        switch self {
        case .compressTelegram: return "arrow.down.right.and.arrow.up.left"
        case .mute: return "speaker.slash.fill"
        case .gif5sec: return "play.rectangle.on.rectangle"
        case .gif15sec: return "video.fill"
        case .rotate90: return "rotate.right"
        case .videoInfo: return "info.circle"
        }
    }
}

public enum VideoCropMode: String, CaseIterable, Sendable {
    case storyAuto = "9:16 Авто"
    case storyBlur = "9:16 Поля"
    case squareAuto = "1:1 Авто"
    case squareBlur = "1:1 Поля"
    case widescreen = "16:9"
    case portrait = "4:5 Инста"
    
    public var suffix: String {
        switch self {
        case .storyAuto: return "_9x16_auto"
        case .storyBlur: return "_9x16_blur"
        case .squareAuto: return "_1x1_auto"
        case .squareBlur: return "_1x1_blur"
        case .widescreen: return "_16x9"
        case .portrait: return "_4x5"
        }
    }
}

public final class VideoProcessor: @unchecked Sendable {
    public static let shared = VideoProcessor()
    
    private init() {}
    
    private func makeOutputPath(for inputURL: URL, suffix: String, ext: String) -> URL {
        FileUtils.uniqueURL(for: inputURL, suffix: suffix, extension: ext)
    }
    
    private func findExecutable(named name: String) -> String? {
        ProcessRunner.findExecutable(named: name)
    }
    
    private func runFFmpeg(args: [String], outputURL: URL) throws {
        guard let ffmpeg = findExecutable(named: "ffmpeg") else {
            throw NSError(domain: "FileShifter", code: 200, userInfo: [NSLocalizedDescriptionKey: "ffmpeg не найден. Установите: brew install ffmpeg"])
        }
        let fullArgs = ["-nostdin", "-y"] + args
        let result = try ProcessRunner.run(executable: ffmpeg, arguments: fullArgs, captureOutput: true)
        if !result.isSuccess {
            let errStr = result.stderrString
            let shortErr = errStr.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
                .suffix(3)
                .joined(separator: " ")
            let msg = shortErr.isEmpty ? "Ошибка ffmpeg" : shortErr
            throw NSError(domain: "FileShifter", code: 201, userInfo: [NSLocalizedDescriptionKey: "Ошибка ffmpeg: \(msg)"])
        }
        guard FileManager.default.fileExists(atPath: outputURL.path) else {
            throw NSError(domain: "FileShifter", code: 202, userInfo: [NSLocalizedDescriptionKey: "Целевой файл не был создан"])
        }
    }
    
    // MARK: - Асинхронная неблокирующая конвертация (Shift)
    
    public func convert(videoURL: URL, to format: VideoTargetFormat) async throws -> URL {
        guard findExecutable(named: "ffmpeg") != nil else {
            throw NSError(domain: "FileShifter", code: 200, userInfo: [NSLocalizedDescriptionKey: "ffmpeg не найден. Установите: brew install ffmpeg"])
        }
        
        let suffix = format == .movieRemux ? "_mac" : ""
        let outputURL = makeOutputPath(for: videoURL, suffix: suffix, ext: format.fileExtension)
        
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    switch format {
                    case .movieRemux:
                        let success = self.runRemux(inputURL: videoURL, outputURL: outputURL, withSubtitles: true)
                        if success && FileManager.default.fileExists(atPath: outputURL.path) {
                            continuation.resume(returning: outputURL)
                            return
                        }
                        
                        try? FileManager.default.removeItem(at: outputURL)
                        let fallbackSuccess = self.runRemux(inputURL: videoURL, outputURL: outputURL, withSubtitles: false)
                        if fallbackSuccess && FileManager.default.fileExists(atPath: outputURL.path) {
                            continuation.resume(returning: outputURL)
                            return
                        }
                        continuation.resume(throwing: NSError(domain: "FileShifter", code: 205, userInfo: [NSLocalizedDescriptionKey: "Ошибка ремукса фильма"]))
                        
                    case .mp4:
                        let hasAudio = self.checkHasAudioStream(videoURL: videoURL)
                        var args = ["-i", videoURL.path, "-c:v", "h264_videotoolbox", "-b:v", "6M"]
                        if hasAudio {
                            args += ["-c:a", "aac", "-b:a", "192k"]
                        } else {
                            args += ["-an"]
                        }
                        args.append(outputURL.path)
                        try self.runFFmpeg(args: args, outputURL: outputURL)
                        continuation.resume(returning: outputURL)
                        
                    case .webm:
                        let hasAudio = self.checkHasAudioStream(videoURL: videoURL)
                        var args = [
                            "-i", videoURL.path,
                            "-c:v", "libvpx-vp9", "-deadline", "realtime", "-speed", "6", "-threads", "8", "-b:v", "2.5M"
                        ]
                        if hasAudio {
                            args += ["-c:a", "libopus", "-ar", "48000"]
                        } else {
                            args += ["-an"]
                        }
                        args.append(outputURL.path)
                        try self.runFFmpeg(args: args, outputURL: outputURL)
                        continuation.resume(returning: outputURL)
                        
                    case .gif:
                        try self.runFFmpeg(args: [
                            "-i", videoURL.path,
                            "-vf", "fps=15,scale=480:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse",
                            outputURL.path
                        ], outputURL: outputURL)
                        continuation.resume(returning: outputURL)
                        
                    case .mp3:
                        guard self.checkHasAudioStream(videoURL: videoURL) else {
                            throw NSError(domain: "FileShifter", code: 206, userInfo: [NSLocalizedDescriptionKey: "В исходном видео отсутствует звуковая дорожка для экспорта в MP3"])
                        }
                        try self.runFFmpeg(args: [
                            "-i", videoURL.path,
                            "-vn", "-c:a", "libmp3lame", "-b:a", "320k",
                            outputURL.path
                        ], outputURL: outputURL)
                        continuation.resume(returning: outputURL)
                        
                    case .mov:
                        let hasAudio = self.checkHasAudioStream(videoURL: videoURL)
                        var args = ["-i", videoURL.path, "-c:v", "h264_videotoolbox", "-b:v", "8M"]
                        if hasAudio {
                            args += ["-c:a", "aac", "-b:a", "256k"]
                        } else {
                            args += ["-an"]
                        }
                        args.append(outputURL.path)
                        try self.runFFmpeg(args: args, outputURL: outputURL)
                        continuation.resume(returning: outputURL)
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Магические действия (Control)
    
    public func executeMagicAction(_ action: VideoMagicAction, on videoURL: URL) async throws -> (URL?, VideoMetadata?) {
        switch action {
        case .videoInfo:
            let meta = try getVideoMetadata(videoURL: videoURL)
            return (nil, meta)
            
        case .mute:
            let ext = videoURL.pathExtension.isEmpty ? "mp4" : videoURL.pathExtension
            let outputURL = makeOutputPath(for: videoURL, suffix: "_muted", ext: ext)
            try runFFmpeg(args: [
                "-i", videoURL.path,
                "-c:v", "copy", "-an",
                outputURL.path
            ], outputURL: outputURL)
            return (outputURL, nil)
            
        case .compressTelegram:
            let outputURL = try await compressUnderLimit(videoURL: videoURL, targetMB: 23)
            return (outputURL, nil)
            
        case .gif5sec:
            let outputURL = makeOutputPath(for: videoURL, suffix: "_5s", ext: "gif")
            try runFFmpeg(args: [
                "-t", "5", "-i", videoURL.path,
                "-vf", "fps=15,scale=480:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse",
                outputURL.path
            ], outputURL: outputURL)
            return (outputURL, nil)
            
        case .gif15sec:
            let outputURL = makeOutputPath(for: videoURL, suffix: "_15s", ext: "gif")
            try runFFmpeg(args: [
                "-t", "15", "-i", videoURL.path,
                "-vf", "fps=12,scale=360:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse",
                outputURL.path
            ], outputURL: outputURL)
            return (outputURL, nil)
            
        case .rotate90:
            let outputURL = makeOutputPath(for: videoURL, suffix: "_rotated", ext: "mp4")
            try runFFmpeg(args: [
                "-i", videoURL.path,
                "-vf", "transpose=1",
                "-c:v", "h264_videotoolbox", "-b:v", "6M",
                "-c:a", "aac", "-b:a", "192k",
                outputURL.path
            ], outputURL: outputURL)
            return (outputURL, nil)
        }
    }
    
    /// Умное сжатие под лимит мессенджеров (например, 25 МБ)
    private func compressUnderLimit(videoURL: URL, targetMB: Double) async throws -> URL {
        // Получаем длительность видео
        let duration = getDuration(videoURL: videoURL) ?? 30.0
        let targetBits = targetMB * 8192.0 * 1024.0 // в битах
        var targetBitrateK = Int((targetBits / duration) / 1024.0)
        if targetBitrateK > 4000 { targetBitrateK = 4000 }
        if targetBitrateK < 400 { targetBitrateK = 400 }
        
        let outputURL = makeOutputPath(for: videoURL, suffix: "_compressed", ext: "mp4")
        try runFFmpeg(args: [
            "-i", videoURL.path,
            "-c:v", "h264_videotoolbox",
            "-b:v", "\(targetBitrateK)k",
            "-c:a", "aac",
            "-b:a", "128k",
            outputURL.path
        ], outputURL: outputURL)
        return outputURL
    }
    
    // MARK: - Изменение скорости видео (Option)
    
    public func changeSpeed(videoURL: URL, speed: Double) async throws -> URL {
        let speedStr = speed.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0fx", speed) : String(format: "%.2fx", speed).replacingOccurrences(of: "0x", with: "x")
        let suffix = "_\(speedStr)"
        let outputURL = makeOutputPath(for: videoURL, suffix: suffix, ext: "mp4")
        
        let hasAudio = checkHasAudioStream(videoURL: videoURL)
        let ptsFactor = 1.0 / speed
        let videoFilter = String(format: "setpts=%.4f*PTS", ptsFactor)
        
        var args = [
            "-i", videoURL.path,
            "-filter:v", videoFilter,
            "-c:v", "h264_videotoolbox",
            "-b:v", "6M"
        ]
        
        if hasAudio {
            let audioFilter: String
            if speed <= 2.0 {
                audioFilter = String(format: "atempo=%.4f", speed)
            } else {
                let first = 2.0
                let second = speed / 2.0
                audioFilter = String(format: "atempo=%.2f,atempo=%.4f", first, second)
            }
            args += [
                "-filter:a", audioFilter,
                "-c:a", "aac",
                "-b:a", "192k"
            ]
        } else {
            args += ["-an"]
        }
        
        args.append(outputURL.path)
        try runFFmpeg(args: args, outputURL: outputURL)
        return outputURL
    }
    
    private func checkHasAudioStream(videoURL: URL) -> Bool {
        guard let ffprobePath = findExecutable(named: "ffprobe") else { return true }
        let args = [
            "-v", "error",
            "-select_streams", "a:0",
            "-show_entries", "stream=codec_name",
            "-of", "default=noprint_wrappers=1:nokey=1",
            videoURL.path
        ]
        guard let result = try? ProcessRunner.run(executable: ffprobePath, arguments: args, captureOutput: true) else {
            return true
        }
        let str = result.stdoutString.trimmingCharacters(in: .whitespacesAndNewlines)
        return !str.isEmpty
    }
    
    // MARK: - Умное кадрирование видео (Command)
    
    public func cropVideo(videoURL: URL, mode: VideoCropMode) async throws -> URL {
        guard findExecutable(named: "ffmpeg") != nil else {
            throw NSError(domain: "FileShifter", code: 200, userInfo: [NSLocalizedDescriptionKey: "ffmpeg не найден"])
        }
        
        let outputURL = makeOutputPath(for: videoURL, suffix: mode.suffix, ext: "mp4")
        let hasAudio = checkHasAudioStream(videoURL: videoURL)
        
        var args = ["-i", videoURL.path]
        
        switch mode {
        case .storyBlur:
            let filter = "[0:v]scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920,boxblur=25:5[bg];[0:v]scale=1080:1920:force_original_aspect_ratio=decrease[fg];[bg][fg]overlay=(W-w)/2:(H-h)/2"
            args += ["-filter_complex", filter]
            args += ["-c:v", "h264_videotoolbox", "-b:v", "6M"]
            if hasAudio {
                args += ["-c:a", "aac", "-b:a", "192k"]
            } else {
                args += ["-an"]
            }
            
        case .squareBlur:
            let filter = "[0:v]scale=1080:1080:force_original_aspect_ratio=increase,crop=1080:1080,boxblur=25:5[bg];[0:v]scale=1080:1080:force_original_aspect_ratio=decrease[fg];[bg][fg]overlay=(W-w)/2:(H-h)/2"
            args += ["-filter_complex", filter]
            args += ["-c:v", "h264_videotoolbox", "-b:v", "6M"]
            if hasAudio {
                args += ["-c:a", "aac", "-b:a", "192k"]
            } else {
                args += ["-an"]
            }
            
        case .storyAuto, .squareAuto, .widescreen, .portrait:
            let meta = try getVideoMetadata(videoURL: videoURL)
            let dims = meta.resolution.components(separatedBy: "×").map { $0.trimmingCharacters(in: .whitespaces) }
            var inW = 1920
            var inH = 1080
            if dims.count == 2, let w = Int(dims[0]), let h = Int(dims[1]), w > 0, h > 0 {
                inW = w
                inH = h
            }
            
            let targetRatio: Double
            switch mode {
            case .storyAuto: targetRatio = 9.0 / 16.0
            case .squareAuto: targetRatio = 1.0
            case .widescreen: targetRatio = 16.0 / 9.0
            case .portrait: targetRatio = 4.0 / 5.0
            default: targetRatio = 1.0
            }
            
            let currentRatio = Double(inW) / Double(inH)
            let (centerX, centerY) = findCenterOfFocus(videoURL: videoURL)
            
            var outW: Int
            var outH: Int
            var cropX: Int
            var cropY: Int
            
            if currentRatio > targetRatio {
                // Исходник шире, обрезаем по бокам
                outH = inH
                let rawW = Int(Double(inH) * targetRatio)
                outW = rawW - (rawW % 2)
                let calculatedX = Int(Double(inW) * centerX - Double(outW) / 2.0)
                cropX = max(0, min(inW - outW, calculatedX))
                cropY = 0
            } else {
                // Исходник уже / выше, обрезаем сверху и снизу
                outW = inW
                let rawH = Int(Double(inW) / targetRatio)
                outH = rawH - (rawH % 2)
                cropX = 0
                let calculatedY = Int(Double(inH) * centerY - Double(outH) / 2.0)
                cropY = max(0, min(inH - outH, calculatedY))
            }
            
            let cropFilter = "crop=\(outW):\(outH):\(cropX):\(cropY)"
            args += ["-vf", cropFilter]
            args += ["-c:v", "h264_videotoolbox", "-b:v", "6M"]
            if hasAudio {
                args += ["-c:a", "copy"]
            } else {
                args += ["-an"]
            }
        }
        
        args.append(outputURL.path)
        try runFFmpeg(args: args, outputURL: outputURL)
        return outputURL
    }
    
    private func findCenterOfFocus(videoURL: URL) -> (centerX: Double, centerY: Double) {
        let asset = AVURLAsset(url: videoURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        let time = CMTime(seconds: 1.0, preferredTimescale: 600)
        
        guard let cgImage = try? generator.copyCGImage(at: time, actualTime: nil) else {
            return (0.5, 0.5)
        }
        
        let faceReq = VNDetectFaceRectanglesRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        if (try? handler.perform([faceReq])) != nil,
           let face = faceReq.results?.first {
            return (Double(face.boundingBox.midX), Double(1.0 - face.boundingBox.midY))
        }
        
        let saliencyReq = VNGenerateAttentionBasedSaliencyImageRequest()
        if (try? handler.perform([saliencyReq])) != nil,
           let sal = saliencyReq.results?.first?.salientObjects?.first {
            return (Double(sal.boundingBox.midX), Double(1.0 - sal.boundingBox.midY))
        }
        
        return (0.5, 0.5)
    }
    
    private func getDuration(videoURL: URL) -> Double? {
        guard let ffprobePath = findExecutable(named: "ffprobe") else { return nil }
        let args = [
            "-v", "error",
            "-show_entries", "format=duration",
            "-of", "default=noprint_wrappers=1:nokey=1",
            videoURL.path
        ]
        guard let result = try? ProcessRunner.run(executable: ffprobePath, arguments: args, captureOutput: true) else {
            return nil
        }
        let str = result.stdoutString.trimmingCharacters(in: .whitespacesAndNewlines)
        return Double(str)
    }
    
    /// Получение информации о видео через ffprobe
    public func getVideoMetadata(videoURL: URL) throws -> VideoMetadata {
        guard let ffprobePath = findExecutable(named: "ffprobe") else {
            throw NSError(domain: "FileShifter", code: 210, userInfo: [NSLocalizedDescriptionKey: "ffprobe не найден"])
        }
        
        let args = [
            "-v", "quiet",
            "-print_format", "json",
            "-show_format",
            "-show_streams",
            videoURL.path
        ]
        
        let result = try ProcessRunner.run(executable: ffprobePath, arguments: args, captureOutput: true)
        guard result.isSuccess,
              let json = try? JSONSerialization.jsonObject(with: result.stdoutData) as? [String: Any] else {
            throw NSError(domain: "FileShifter", code: 211, userInfo: [NSLocalizedDescriptionKey: "Не удалось распарсить метаданные видео"])
        }
        
        let formatObj = json["format"] as? [String: Any] ?? [:]
        let streams = json["streams"] as? [[String: Any]] ?? []
        
        var width = 0
        var height = 0
        var fpsStr = "30 fps"
        var vCodec = "H.264"
        var aCodec = "Нет звука"
        
        for st in streams {
            let type = (st["codec_type"] as? String) ?? ""
            if type == "video" && width == 0 {
                width = (st["width"] as? Int) ?? 0
                height = (st["height"] as? Int) ?? 0
                vCodec = (st["codec_name"] as? String)?.uppercased() ?? "VIDEO"
                if let rRate = st["r_frame_rate"] as? String {
                    let parts = rRate.split(separator: "/")
                    if parts.count == 2, let num = Double(parts[0]), let den = Double(parts[1]), den > 0 {
                        fpsStr = String(format: "%.0f fps", num / den)
                    }
                }
            } else if type == "audio" && aCodec == "Нет звука" {
                let name = (st["codec_name"] as? String)?.uppercased() ?? "AUDIO"
                let rate = (st["sample_rate"] as? String) ?? ""
                let rateK = (Int(rate) ?? 48000) / 1000
                aCodec = "\(name) (\(rateK) kHz)"
            }
        }
        
        let durationSec = Double((formatObj["duration"] as? String) ?? "0") ?? 0.0
        let mins = Int(durationSec) / 60
        let secs = Int(durationSec) % 60
        let durationStr = String(format: "%02d:%02d", mins, secs)
        
        let fileSize = (try? FileManager.default.attributesOfItem(atPath: videoURL.path)[.size] as? Int64) ?? 0
        let sizeString: String
        if fileSize > 1024 * 1024 {
            sizeString = String(format: "%.1f МБ", Double(fileSize) / (1024 * 1024))
        } else {
            sizeString = "\(fileSize / 1024) КБ"
        }
        
        let gcdVal = gcd(width, height)
        let ratioStr = gcdVal > 0 ? "\(width / gcdVal):\(height / gcdVal)" : "\(width)x\(height)"
        
        return VideoMetadata(
            fileName: videoURL.lastPathComponent,
            durationString: durationStr,
            resolution: "\(width) × \(height)",
            aspectRatio: ratioStr,
            fps: fpsStr,
            fileSizeString: sizeString,
            videoCodec: vCodec,
            audioCodec: aCodec
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
    
    private func runRemux(inputURL: URL, outputURL: URL, withSubtitles: Bool) -> Bool {
        var args = [
            "-i", inputURL.path,
            "-map", "0",
            "-c:v", "copy",
            "-c:a", "aac",
            "-b:a", "384k"
        ]
        
        if withSubtitles {
            args += ["-c:s", "mov_text"]
        } else {
            args += ["-sn"]
        }
        
        args.append(outputURL.path)
        do {
            try runFFmpeg(args: args, outputURL: outputURL)
            return true
        } catch {
            return false
        }
    }
}
