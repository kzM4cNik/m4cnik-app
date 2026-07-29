import SwiftUI

struct ContentView: View {
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var shield = ScreenShieldController.shared
    @ObservedObject private var appState = AppState.shared
    @State private var tab = 0

    var body: some View {
        ZStack {
            AmbientBackground()

            if !appState.showSplash {
                VStack(spacing: 0) {
                    header
                        .padding(.horizontal, 18)
                        .padding(.top, 8)
                        .padding(.bottom, 6)

                    Group {
                        switch tab {
                        case 0:
                            WebPanelView(path: "/index.html", isActive: true, settings: settings)
                        case 1:
                            WebPanelView(path: "/pages/admin.html", isActive: true, settings: settings)
                        case 2:
                            WebPanelView(path: "/pages/crm.html", isActive: true, settings: settings)
                        default:
                            SettingsView(settings: settings)
                                .padding(.horizontal, 10)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    customTabBar
                        .padding(.horizontal, 14)
                        .padding(.bottom, 10)
                }
                .transition(.opacity)
            }

            if appState.showSplash {
                LaunchSplashView()
                    .transition(.opacity)
            }

            if appState.showLoginBurst {
                LoginSuccessBurst(name: appState.loginBurstName)
                    .zIndex(20)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            shield.isEnabled = settings.antiCaptureEnabled
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                appState.finishSplash()
            }
        }
        .onChange(of: settings.antiCaptureEnabled) { on in
            shield.isEnabled = on
        }
        .onReceive(NotificationCenter.default.publisher(for: UIScreen.capturedDidChangeNotification)) { _ in
            shield.refreshCaptureState()
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Kaspi")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                Text(tabTitle)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textMuted)
            }
            Spacer()

            Toggle(isOn: $settings.antiCaptureEnabled) {
                Image(systemName: settings.antiCaptureEnabled ? "eye.slash.fill" : "eye.fill")
            }
            .toggleStyle(.button)
            .tint(settings.antiCaptureEnabled ? AppTheme.accent : AppTheme.textMuted)
            .accessibilityLabel("Анти-скрин")

            Button {
                NotificationCenter.default.post(name: .m4cnikReloadWeb, object: nil)
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.body.weight(.semibold))
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.white.opacity(0.08)))
            }
            .buttonStyle(.plain)
        }
    }

    private var tabTitle: String {
        switch tab {
        case 0: return "Клиент · сайт в приложении"
        case 1: return "Панель управления"
        case 2: return "CRM · клиенты"
        default: return "Настройки"
        }
    }

    private var customTabBar: some View {
        HStack(spacing: 6) {
            tabButton(0, "Kaspi", "creditcard.fill")
            tabButton(1, "Админ", "shield.lefthalf.filled")
            tabButton(2, "CRM", "person.3.fill")
            tabButton(3, "Ещё", "slider.horizontal.3")
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.radiusXL, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.radiusXL, style: .continuous)
                        .stroke(AppTheme.cardBorder, lineWidth: 1)
                )
        )
    }

    private func tabButton(_ index: Int, _ title: String, _ icon: String) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) { tab = index }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 16, weight: .semibold))
                Text(title).font(.caption2.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .foregroundStyle(tab == index ? .white : AppTheme.textMuted)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.radiusMD, style: .continuous)
                    .fill(tab == index ? AppTheme.accent.opacity(0.85) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

struct SettingsView: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Сервер", systemImage: "server.rack").font(.headline)
                        TextField("http://77.67.8.98", text: $settings.serverURL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.URL)
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: AppTheme.radiusMD, style: .continuous)
                                    .fill(Color.white.opacity(0.06))
                            )
                    }
                }
                GlassCard {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Label("Анти-скрин", systemImage: "eye.slash.fill").font(.headline)
                            Text("Скрывает экран при скрине и записи")
                                .font(.caption)
                                .foregroundStyle(AppTheme.textMuted)
                        }
                        Spacer()
                        Toggle("", isOn: $settings.antiCaptureEnabled).labelsHidden().tint(AppTheme.accent)
                    }
                }
                GlassCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Kaspi WebView").font(.headline)
                        Text("Версия 1.4 · сайт внутри IPA")
                            .foregroundStyle(AppTheme.textMuted)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.vertical, 8)
        }
    }
}
