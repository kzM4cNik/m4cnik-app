import SwiftUI
import AVFoundation
import AudioToolbox

final class AppState: ObservableObject {
    static let shared = AppState()

    @Published var showSplash = true
    @Published var showLoginBurst = false
    @Published var loginBurstName = ""

    private init() {}

    func finishSplash() {
        LoginSound.playWelcome()
        withAnimation(.easeOut(duration: 0.45)) {
            showSplash = false
        }
    }

    func triggerLoginSuccess(login: String) {
        LoginSound.play()
        loginBurstName = login
        withAnimation(.spring(response: 0.5, dampingFraction: 0.72)) {
            showLoginBurst = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.35) {
            withAnimation(.easeOut(duration: 0.35)) {
                self.showLoginBurst = false
            }
        }
    }
}

enum LoginSound {
    static func playWelcome() {
        let gen = UIImpactFeedbackGenerator(style: .light)
        gen.impactOccurred()
        AudioServicesPlaySystemSound(1104)
    }

    static func play() {
        let gen = UINotificationFeedbackGenerator()
        gen.notificationOccurred(.success)
        AudioServicesPlaySystemSound(1111)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            AudioServicesPlaySystemSound(1104)
        }
    }
}

struct LaunchSplashView: View {
    @State private var pulse = false
    @State private var ring = false
    @State private var textIn = false

    var body: some View {
        ZStack {
            AmbientBackground()

            VStack(spacing: 28) {
                ZStack {
                    Circle()
                        .stroke(AppTheme.accent.opacity(0.25), lineWidth: 2)
                        .frame(width: ring ? 130 : 90, height: ring ? 130 : 90)
                        .opacity(ring ? 0 : 0.9)
                        .animation(.easeOut(duration: 1.4).repeatForever(autoreverses: false), value: ring)

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [AppTheme.accent.opacity(0.35), .clear],
                                center: .center,
                                startRadius: 8,
                                endRadius: 56
                            )
                        )
                        .frame(width: 100, height: 100)
                        .scaleEffect(pulse ? 1.08 : 0.92)

                    Image(systemName: "shield.lefthalf.filled")
                        .font(.system(size: 42, weight: .semibold))
                        .foregroundStyle(.white)
                        .shadow(color: AppTheme.accent.opacity(0.5), radius: 12)
                }

                VStack(spacing: 8) {
                    Text("M4cNik")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .opacity(textIn ? 1 : 0)
                        .offset(y: textIn ? 0 : 12)
                    Text("Admin · CRM")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.textMuted)
                        .opacity(textIn ? 1 : 0)
                        .offset(y: textIn ? 0 : 8)
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) { pulse = true }
            ring = true
            withAnimation(.easeOut(duration: 0.55).delay(0.15)) { textIn = true }
        }
    }
}

struct LoginSuccessBurst: View {
    let name: String
    @State private var scale: CGFloat = 0.4
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()

            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(AppTheme.accent.opacity(0.2))
                        .frame(width: 110, height: 110)
                        .scaleEffect(scale)
                    Circle()
                        .stroke(AppTheme.accent, lineWidth: 3)
                        .frame(width: 88, height: 88)
                        .scaleEffect(scale)
                    Image(systemName: "checkmark")
                        .font(.system(size: 38, weight: .bold))
                        .foregroundStyle(.white)
                        .scaleEffect(scale)
                }
                Text("Добро пожаловать")
                    .font(.title3.weight(.bold))
                Text(name.isEmpty ? "Вход выполнен" : name)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textMuted)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.radiusXL, style: .continuous)
                    .fill(AppTheme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.radiusXL, style: .continuous)
                            .stroke(AppTheme.cardBorder, lineWidth: 1)
                    )
            )
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.68)) {
                scale = 1
                opacity = 1
            }
        }
    }
}
