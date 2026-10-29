import SwiftUI

public struct GlassCard<Content: View>: View {
    public let width: CGFloat
    public let cornerRadius: CGFloat
    public let content: () -> Content
    
    public init(width: CGFloat = 300, cornerRadius: CGFloat = 18, @ViewBuilder content: @escaping () -> Content) {
        self.width = width
        self.cornerRadius = cornerRadius
        self.content = content
    }
    
    public var body: some View {
        content()
            .padding(14)
            .frame(width: width)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.8), .white.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: .black.opacity(0.14), radius: 14, x: 0, y: 6)
            )
            .padding(16)
    }
}

public struct InfoCellView: View {
    public let icon: String
    public let title: String
    public let value: String
    public let hasCardBackground: Bool
    
    public init(icon: String, title: String, value: String, hasCardBackground: Bool = false) {
        self.icon = icon
        self.title = title
        self.value = value
        self.hasCardBackground = hasCardBackground
    }
    
    public var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 14)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.system(size: 9, weight: .regular))
                    .foregroundStyle(Color(white: 0.45))
                Text(value)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(white: 0.15))
                    .lineLimit(1)
            }
            if hasCardBackground {
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, hasCardBackground ? 8 : 0)
        .padding(.vertical, hasCardBackground ? 6 : 0)
        .background(
            Group {
                if hasCardBackground {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.5))
                }
            }
        )
    }
}
