import SwiftUI

@main
struct M4cNikAppApp: App {
    init() {
        let nav = UINavigationBarAppearance()
        nav.configureWithOpaqueBackground()
        nav.backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.08, alpha: 1)
        nav.titleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UITabBar.appearance().backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.08, alpha: 1)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
