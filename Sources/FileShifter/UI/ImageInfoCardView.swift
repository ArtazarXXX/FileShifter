import SwiftUI

public struct ImageInfoCardView: View {
    public let meta: ImageMetadata
    
    public var body: some View {
        GlassCard(width: 290) {
            VStack(alignment: .leading, spacing: 10) {
                // Header
                HStack(spacing: 8) {
                    Image(systemName: "photo.circle.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.cyan)
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text(meta.fileName)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(white: 0.12))
                            .lineLimit(1)
                        
                        Text("\(meta.megaPixels) • \(meta.fileSizeString)")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(Color(white: 0.4))
                    }
                    
                    Spacer()
                    
                    if meta.hasGPS {
                        HStack(spacing: 3) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 9))
                            Text("GPS")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(.orange.opacity(0.18)))
                        .foregroundStyle(.orange)
                    } else {
                        HStack(spacing: 3) {
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 9))
                            Text("Чисто")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(.green.opacity(0.18)))
                        .foregroundStyle(.green)
                    }
                }
                
                Divider()
                    .background(Color.black.opacity(0.1))
                
                // Grid specs
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    InfoCellView(icon: "arrow.up.left.and.arrow.down.right", title: "Разрешение", value: "\(meta.width) × \(meta.height)")
                    InfoCellView(icon: "aspectratio", title: "Пропорции", value: meta.aspectRatio)
                    InfoCellView(icon: "internaldrive", title: "Вес на диске", value: meta.fileSizeString)
                    InfoCellView(icon: "paintpalette", title: "Цвет", value: meta.colorProfile)
                }
            }
        }
    }
}
