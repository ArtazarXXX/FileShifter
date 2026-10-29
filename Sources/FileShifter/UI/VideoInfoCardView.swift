import SwiftUI

public struct VideoMetadata: Sendable {
    public let fileName: String
    public let durationString: String
    public let resolution: String
    public let aspectRatio: String
    public let fps: String
    public let fileSizeString: String
    public let videoCodec: String
    public let audioCodec: String
}

public struct VideoInfoCardView: View {
    public let meta: VideoMetadata
    
    public var body: some View {
        GlassCard(width: 300) {
            VStack(alignment: .leading, spacing: 10) {
                // Header
                HStack(spacing: 8) {
                    Image(systemName: "film.stack.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.blue)
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text(meta.fileName)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(white: 0.12))
                            .lineLimit(1)
                        
                        Text("\(meta.durationString) • \(meta.fileSizeString)")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(Color(white: 0.4))
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 3) {
                        Image(systemName: "video.badge.waveform")
                            .font(.system(size: 9))
                        Text(meta.videoCodec)
                            .font(.system(size: 9, weight: .bold))
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3.5)
                    .background(Capsule().fill(.blue.opacity(0.18)))
                    .foregroundStyle(.blue)
                }
                
                Divider()
                    .background(Color.black.opacity(0.1))
                
                // Grid specs
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    InfoCellView(icon: "clock", title: "Хронометраж", value: meta.durationString)
                    InfoCellView(icon: "arrow.up.left.and.arrow.down.right", title: "Разрешение", value: meta.resolution)
                    InfoCellView(icon: "speedometer", title: "Кадры", value: meta.fps)
                    InfoCellView(icon: "aspectratio", title: "Пропорции", value: meta.aspectRatio)
                    InfoCellView(icon: "internaldrive", title: "Вес на диске", value: meta.fileSizeString)
                    InfoCellView(icon: "waveform", title: "Звук", value: meta.audioCodec)
                }
            }
        }
    }
}
