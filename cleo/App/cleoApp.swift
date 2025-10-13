//
//  cleoApp.swift
//  cleo
//
//  Created by Jacob Fu on 2025-10-11.
//

import SwiftUI

@main
struct cleoApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        // Menu bar icon with dropdown
        MenuBarExtra("Cleo", systemImage: "sparkles") {
            MenuBarView(appState: appState)
        }

        // Overlay window for showing explanations
        Window("Overlay", id: "overlay") {
            if let text = appState.selectedText, let shortcutKey = appState.selectedShortcut {
                OverlayView(selectedText: text, selectedShortcut: shortcutKey) {
                    appState.closeOverlay()
                }
            }
        }
        .windowStyle(.plain)
        .windowResizability(.contentMinSize)
        .defaultPosition(.center)
    }
}
