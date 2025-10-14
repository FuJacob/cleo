import SwiftUI

@main
struct cleoApp: App {
    @StateObject private var appState = AppState.shared

    var body: some Scene {
        // Menu bar icon
        MenuBarExtra("Cleo", systemImage: "sparkles") {
            MenuBarView(appState: appState)
                .onAppear {
                    // Open onboarding on first launch after menu bar appears
                    if appState.isFirstLaunch {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            NSApp.activate(ignoringOtherApps: true)
                            if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "onboarding" }) {
                                window.makeKeyAndOrderFront(nil)
                            }
                        }
                    }
                }
        }

        // Onboarding window
        Window("Welcome to Cleo", id: "onboarding") {
            OnboardingView()
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)

        // Overlay window
        Window("Overlay", id: "overlay") {
            if let text = appState.selectedText, let shortcutKey = appState.selectedShortcut {
                OverlayView(selectedText: text, selectedShortcut: shortcutKey) {
                    appState.closeOverlay()
                }
            }
        }
        .windowStyle(.plain)
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }
}
