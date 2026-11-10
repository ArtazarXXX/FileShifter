import SwiftUI

public struct ToastFeedbackView: View {
    @Environment(\.colorScheme) private var colorScheme
    public let message: String
    public let icon: String
    
    public init(message: String, icon: String = "checkmark.circle.fill") {
        self.message = message
        self.icon = icon
    }
    
    public var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.green)
            
            Text(message)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(colorScheme == .dark ? Color.white : Color(white: 0.12))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .stroke(
                            LinearGradient(
                                colors: colorScheme == .dark
                                    ? [.white.opacity(0.35), .white.opacity(0.1)]
                                    : [.white.opacity(0.85), .white.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: colorScheme == .dark ? .black.opacity(0.4) : .black.opacity(0.15),
                    radius: 16,
                    x: 0,
                    y: 6
                )
        )
    }
}
