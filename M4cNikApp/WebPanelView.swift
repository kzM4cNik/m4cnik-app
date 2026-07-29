import SwiftUI
import WebKit

enum WebKitShared {
    static let processPool = WKProcessPool()
    static let dataStore = WKWebsiteDataStore.default()

    static let injectScript = """
    (function(){
      window.__M4CNIK_APP = true;
      if (typeof window.__M4CNIK_ANTI_CAPTURE === 'undefined') {
        window.__M4CNIK_ANTI_CAPTURE = true;
      }
      document.documentElement.classList.add('m4cnik-native');
      if (document.body) document.body.classList.add('native-app','m4cnik-native');

      var host = location.hostname || '';
      function patchHeaders(h) {
        if (!h) h = {};
        if (h instanceof Headers) { h.set('X-K-Host', host); return h; }
        if (typeof h === 'object') { h['X-K-Host'] = host; return h; }
        return { 'X-K-Host': host };
      }
      var _fetch = window.fetch;
      window.fetch = function(url, opts) {
        opts = opts || {};
        opts.credentials = opts.credentials || 'same-origin';
        opts.headers = patchHeaders(opts.headers);
        return _fetch.call(this, url, opts);
      };
      XMLHttpRequest.prototype.send = (function(send) {
        return function(body) {
          try { this.setRequestHeader('X-K-Host', host); } catch(e) {}
          return send.call(this, body);
        };
      })(XMLHttpRequest.prototype.send);

      window.M4cNikNative = {
        setAntiCapture: function(v) {
          window.__M4CNIK_ANTI_CAPTURE = !!v;
          window.webkit.messageHandlers.m4cnik.postMessage({action:'setAntiCapture', enabled: !!v});
        },
        loginSuccess: function(login) {
          window.webkit.messageHandlers.m4cnik.postMessage({action:'loginSuccess', login: login || ''});
        }
      };
    })();
    """
}

struct WebPanelView: View {
    let path: String
    let isActive: Bool
    @ObservedObject var settings: AppSettings
    @ObservedObject var shield = ScreenShieldController.shared
    @State private var isLoading = true
    @State private var loadError = ""

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppTheme.radiusXL, style: .continuous)
                .fill(Color(red: 0.04, green: 0.04, blue: 0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.radiusXL, style: .continuous)
                        .stroke(AppTheme.cardBorder, lineWidth: 1)
                )

            if isActive {
                WebViewRepresentable(
                    url: settings.pageURL(path),
                    antiCapture: settings.antiCaptureEnabled,
                    isLoading: $isLoading,
                    loadError: $loadError
                )
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusXL, style: .continuous))
            }

            if isActive && isLoading {
                loadingOverlay
            }
            if isActive && !loadError.isEmpty {
                errorOverlay
            }
            if isActive && settings.antiCaptureEnabled && shield.isScreenCaptured {
                captureOverlay
            }
        }
        .padding(.horizontal, 10)
        .padding(.top, 6)
        .padding(.bottom, 4)
    }

    private var loadingOverlay: some View {
        RoundedRectangle(cornerRadius: AppTheme.radiusXL, style: .continuous)
            .fill(Color.black.opacity(0.55))
            .overlay {
                VStack(spacing: 14) {
                    ProgressView().tint(AppTheme.accent).scaleEffect(1.2)
                    Text("Загрузка…")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.textMuted)
                }
            }
    }

    private var errorOverlay: some View {
        RoundedRectangle(cornerRadius: AppTheme.radiusXL, style: .continuous)
            .fill(Color.black.opacity(0.82))
            .overlay {
                VStack(spacing: 12) {
                    Image(systemName: "wifi.exclamationmark")
                        .font(.system(size: 32))
                        .foregroundStyle(AppTheme.accent)
                    Text("Не удалось загрузить").font(.headline)
                    Text(loadError)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                    Button("Повторить") {
                        loadError = ""
                        isLoading = true
                        NotificationCenter.default.post(name: .m4cnikReloadWeb, object: path)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.accent)
                }
            }
    }

    private var captureOverlay: some View {
        RoundedRectangle(cornerRadius: AppTheme.radiusXL, style: .continuous)
            .fill(Color.black)
            .overlay {
                VStack(spacing: 10) {
                    Image(systemName: "eye.slash.fill").font(.system(size: 34))
                    Text("Защита экрана").font(.headline)
                }
                .foregroundStyle(.white)
            }
            .allowsHitTesting(false)
    }
}

extension Notification.Name {
    static let m4cnikReloadWeb = Notification.Name("m4cnik.reloadWeb")
    static let m4cnikAntiCaptureChanged = Notification.Name("m4cnik.antiCaptureChanged")
}

struct WebViewRepresentable: UIViewRepresentable {
    let url: URL?
    let antiCapture: Bool
    @Binding var isLoading: Bool
    @Binding var loadError: String

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makeUIView(context: Context) -> SecureContainerView {
        let config = WKWebViewConfiguration()
        config.processPool = WebKitShared.processPool
        config.websiteDataStore = WebKitShared.dataStore
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        config.allowsInlineMediaPlayback = true

        let controller = WKUserContentController()
        let boot = WebKitShared.injectScript + """
        window.__M4CNIK_ANTI_CAPTURE = \(antiCapture ? "true" : "false");
        """
        controller.addUserScript(WKUserScript(
            source: boot,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        ))
        controller.add(context.coordinator, name: "m4cnik")
        config.userContentController = controller

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = true
        webView.backgroundColor = UIColor(red: 0.03, green: 0.03, blue: 0.04, alpha: 1)
        webView.scrollView.backgroundColor = webView.backgroundColor
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.customUserAgent = "M4cNikApp/1.4 iOS WebKit"

        let host = SecureContainerView()
        host.setContent(webView)
        host.isSecure = antiCapture
        ScreenShieldController.shared.attach(container: host)

        context.coordinator.webView = webView
        context.coordinator.host = host
        context.coordinator.lastURL = url
        context.coordinator.lastSecure = antiCapture

        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.reloadRequested),
            name: .m4cnikReloadWeb,
            object: nil
        )

        if let url {
            webView.load(URLRequest(url: url))
        }
        return host
    }

    func updateUIView(_ host: SecureContainerView, context: Context) {
        context.coordinator.parent = self
        host.isSecure = antiCapture
        if context.coordinator.lastSecure != antiCapture {
            context.coordinator.lastSecure = antiCapture
            context.coordinator.syncSecureToPage(antiCapture)
        }
        if context.coordinator.lastURL != url, let url {
            context.coordinator.lastURL = url
            context.coordinator.webView?.load(URLRequest(url: url))
        }
    }

    static func dismantleUIView(_ host: SecureContainerView, coordinator: Coordinator) {
        NotificationCenter.default.removeObserver(coordinator)
        coordinator.webView?.navigationDelegate = nil
        coordinator.webView?.uiDelegate = nil
        if let webView = coordinator.webView {
            webView.configuration.userContentController.removeScriptMessageHandler(forName: "m4cnik")
        }
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
        var parent: WebViewRepresentable
        weak var webView: WKWebView?
        weak var host: SecureContainerView?
        var lastURL: URL?
        var lastSecure = false

        init(parent: WebViewRepresentable) {
            self.parent = parent
        }

        func syncSecureToPage(_ enabled: Bool) {
            let js = """
            (function(){
              window.__M4CNIK_ANTI_CAPTURE = \(enabled ? "true" : "false");
              if (window.KaspiSecureView && window.KaspiSecureView.set) {
                window.KaspiSecureView.set(\(enabled ? "true" : "false"));
              }
              var t = document.getElementById('appAntiCaptureToggle');
              if (t) t.checked = \(enabled ? "true" : "false");
            })();
            """
            webView?.evaluateJavaScript(js, completionHandler: nil)
        }

        @objc func reloadRequested(_ note: Notification) {
            guard let webView else { return }
            if let obj = note.object as? String, let current = lastURL?.absoluteString, !current.contains(obj) {
                return
            }
            DispatchQueue.main.async {
                self.parent.isLoading = true
                self.parent.loadError = ""
            }
            if let url = lastURL {
                webView.load(URLRequest(url: url))
            } else {
                webView.reload()
            }
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "m4cnik",
                  let body = message.body as? [String: Any],
                  let action = body["action"] as? String
            else { return }

            DispatchQueue.main.async {
                if action == "setAntiCapture" {
                    let enabled = body["enabled"] as? Bool ?? false
                    AppSettings.shared.antiCaptureEnabled = enabled
                    ScreenShieldController.shared.isEnabled = enabled
                    self.host?.isSecure = enabled
                    self.lastSecure = enabled
                } else if action == "loginSuccess" {
                    let login = body["login"] as? String ?? ""
                    AppState.shared.triggerLoginSuccess(login: login)
                }
            }
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = true
                self.parent.loadError = ""
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async { self.parent.isLoading = false }
            let on = parent.antiCapture
            webView.evaluateJavaScript("""
              document.body.classList.add('native-app','m4cnik-native');
              document.documentElement.classList.add('m4cnik-native');
              window.__M4CNIK_ANTI_CAPTURE = \(on ? "true" : "false");
              if (window.KaspiSecureView && window.KaspiSecureView.set) {
                window.KaspiSecureView.set(\(on ? "true" : "false"));
              }
            """, completionHandler: nil)
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            fail(error)
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            let ns = error as NSError
            if ns.domain == NSURLErrorDomain && ns.code == NSURLErrorCancelled { return }
            fail(error)
        }

        private func fail(_ error: Error) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
                self.parent.loadError = error.localizedDescription
            }
        }

        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            if navigationAction.targetFrame == nil, let url = navigationAction.request.url {
                webView.load(URLRequest(url: url))
            }
            return nil
        }
    }
}

