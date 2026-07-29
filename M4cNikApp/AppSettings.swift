import Foundation
import Combine

final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    private let serverKey = "m4cnik_server_url"
    private let antiCaptureKey = "m4cnik_anti_capture"

    @Published var serverURL: String {
        didSet {
            let trimmed = serverURL.trimmingCharacters(in: .whitespacesAndNewlines)
            UserDefaults.standard.set(trimmed, forKey: serverKey)
        }
    }

    @Published var antiCaptureEnabled: Bool {
        didSet {
            UserDefaults.standard.set(antiCaptureEnabled, forKey: antiCaptureKey)
        }
    }

    private init() {
        serverURL = UserDefaults.standard.string(forKey: serverKey) ?? "http://77.67.8.98"
        antiCaptureEnabled = UserDefaults.standard.object(forKey: antiCaptureKey) as? Bool ?? true
    }

    func pageURL(_ path: String) -> URL? {
        var base = serverURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if base.hasSuffix("/") { base.removeLast() }
        let p = path.hasPrefix("/") ? path : "/" + path
        var url = base + p
        if url.contains("?") {
            url += "&app=1"
        } else {
            url += "?app=1"
        }
        return URL(string: url)
    }
}
