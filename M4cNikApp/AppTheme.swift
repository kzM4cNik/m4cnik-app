import SwiftUI

enum AppTheme {
    static let bgTop = Color(red: 0.08, green: 0.06, blue: 0.10)
    static let bgBottom = Color(red: 0.02, green: 0.02, blue: 0.04)
    static let accent = Color(red: 0.95, green: 0.27, blue: 0.21)
    static let accentSoft = Color(red: 0.95, green: 0.27, blue: 0.21).opacity(0.18)
    static let card = Color(red: 0.11, green: 0.11, blue: 0.14).opacity(0.92)
    static let cardBorder = Color.white.opacity(0.08)
    static let textMuted = Color.white.opacity(0.55)
    static let radiusXL: CGFloat = 28
    static let radiusLG: CGFloat = 22
    static let radiusMD: CGFloat = 16
}

struct AmbientBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppTheme.bgTop, AppTheme.bgBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Circle()
                .fill(AppTheme.accent.opacity(0.14))
                .frame(width: 320, height: 320)
                .blur(radius: 80)
                .offset(x: -120, y: -260)
            Circle()
                .fill(Color.blue.opacity(0.10))
                .frame(width: 280, height: 280)
                .blur(radius: 90)
                .offset(x: 140, y: 220)
        }
        .ignoresSafeArea()
    }
}

struct GlassCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.radiusLG, style: .continuous)
                    .fill(AppTheme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.radiusLG, style: .continuous)
                            .stroke(AppTheme.cardBorder, lineWidth: 1)
                    )
            )
    }
}
