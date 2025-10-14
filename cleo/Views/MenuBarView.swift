//
//  MenuBarView.swift
//  cleo
//
//  Created by Jacob Fu on 2025-10-11.
//

import SwiftUI

struct MenuBarView: View {
    @ObservedObject var appState: AppState
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Shortcuts section
            VStack(alignment: .leading, spacing: 4) {
                ShortcutRow(key: "⌘⌃E", description: "Explain")
                ShortcutRow(key: "⌘⌃S", description: "Summarize")
                ShortcutRow(key: "⌘⌃R", description: "Revise")
            }
            .padding(.vertical, 6)

            Divider()

            // Actions
            Button("Documentation") {
                NSWorkspace.shared.open(URL(string: "https://github.com/FuJacob/cleo")!)
            }

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .onAppear {
            appState.openWindowAction = { [openWindow] windowId in
                openWindow(id: windowId)
            }
        }
    }
}

struct ShortcutRow: View {
    let key: String
    let description: String

    var body: some View {
        HStack(spacing: 8) {
            Text(key)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
            Text(description)
                .font(.caption)
        }
    }
}
