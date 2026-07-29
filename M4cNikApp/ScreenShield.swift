import SwiftUI
import UIKit

/// Hides content from screenshots / screen recording via secure UITextField container.
final class SecureContainerView: UIView {
    private let secureField = UITextField()
    private weak var contentView: UIView?
    private var secureHost: UIView?

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = true
        clipsToBounds = true
        setupSecureHost()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSecureHost()
    }

    private func setupSecureHost() {
        secureField.isSecureTextEntry = true
        secureField.isUserInteractionEnabled = false
        addSubview(secureField)
        secureField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            secureField.leadingAnchor.constraint(equalTo: leadingAnchor),
            secureField.trailingAnchor.constraint(equalTo: trailingAnchor),
            secureField.topAnchor.constraint(equalTo: topAnchor),
            secureField.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        // The first subview of a secure text field is a private container that
        // is omitted from screenshots when isSecureTextEntry is true.
        if let host = secureField.subviews.first {
            secureHost = host
            host.isUserInteractionEnabled = true
        }
    }

    func setContent(_ view: UIView) {
        contentView?.removeFromSuperview()
        contentView = view
        let parent = secureHost ?? self
        parent.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: parent.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: parent.trailingAnchor),
            view.topAnchor.constraint(equalTo: parent.topAnchor),
            view.bottomAnchor.constraint(equalTo: parent.bottomAnchor),
        ])
    }

    var isSecure: Bool {
        get { secureField.isSecureTextEntry }
        set { secureField.isSecureTextEntry = newValue }
    }
}

final class ScreenShieldController: ObservableObject {
    static let shared = ScreenShieldController()

    @Published var isEnabled: Bool = false {
        didSet { apply() }
    }
    @Published var isScreenCaptured = false

    private var observer: NSObjectProtocol?
    private weak var container: SecureContainerView?

    private init() {
        observer = NotificationCenter.default.addObserver(
            forName: UIScreen.capturedDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refreshCaptureState()
        }
        refreshCaptureState()
    }

    deinit {
        if let observer { NotificationCenter.default.removeObserver(observer) }
    }

    func attach(container: SecureContainerView) {
        self.container = container
        apply()
    }

    func refreshCaptureState() {
        isScreenCaptured = UIScreen.main.isCaptured
    }

    private func apply() {
        container?.isSecure = isEnabled
    }
}
