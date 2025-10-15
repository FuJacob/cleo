import SwiftUI

@main
struct cleoApp: App {
    @StateObject private var appState = AppState.shared

    var body: some Scene {
        // Menu bar icon
        MenuBarExtra {
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
        } label: {
            Image("cleo_logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 18, height: 18)
        }

        // Onboarding window
        Window("Welcome to Cleo", id: "onboarding") {
            OnboardingView()
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)

        // Prompt overlay window (for custom prompts - shortcut A)
        Window("Prompt Overlay", id: "promptOverlay") {
            if let text = appState.selectedText {
                PromptOverlayView(selectedText: text) {
                    appState.closeOverlay("promptOverlay")
                }
            }
        }
        .windowStyle(.plain)
        .windowResizability(.contentSize)
        .defaultPosition(.center)

        // Standard overlay window (for explanations/summaries)
        Window("Overlay", id: "overlay") {
            if let text = appState.selectedText,
               let shortcutKey = appState.selectedShortcut,
               shortcutKey != 0 {  // Don't show for A shortcut (keycode 0)
                OverlayView(selectedText: text, selectedShortcut: shortcutKey) {
                    appState.closeOverlay("overlay")
                }
            }
        }
        .windowStyle(.plain)
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }
}
