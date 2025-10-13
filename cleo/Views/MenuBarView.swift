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
    @Namespace private var menuGlassNamespace

    var body: some View {
        if #available(macOS 26.0, *) {
            GlassEffectContainer(spacing: 8) {
                VStack(spacing: 8) {
                    Button {
                        appState.showAboutAlert()
                    } label: {
                        Label("About Cleo", systemImage: "info.circle")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.glass)
                    .glassEffectID("about-button", in: menuGlassNamespace)

                    Divider()
                        .padding(.vertical, 4)
                        .glassEffect(.regular.tint(.secondary), in: .rect(cornerRadius: 1))
                        .glassEffectID("divider", in: menuGlassNamespace)

                    Button(role: .destructive) {
                        NSApplication.shared.terminate(nil)
                    } label: {
                        Label("Quit", systemImage: "power")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.glassProminent)
                    .keyboardShortcut("q")
                    .glassEffectID("quit-button", in: menuGlassNamespace)
                }
                .padding(10)
                .glassEffect(.regular.tint(.secondary).interactive(), in: .rect(cornerRadius: 12))
                .glassEffectID("menu-container", in: menuGlassNamespace)
            }
            .onAppear {
                appState.openWindowAction = { [openWindow] windowId in
                    openWindow(id: windowId)
                }
            }
        } else {
            // Fallback on earlier versions
        }
    }
}
