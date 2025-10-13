//
//  cleoApp.swift
//  cleo
//
//  Created by Jacob Fu on 2025-10-11.
//

import SwiftUI
import AppKit

@main
struct cleoApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        // Menu bar icon with dropdown
        MenuBarExtra("Cleo", systemImage: "sparkles") {
            MenuContent(appState: appState)
        }

        // Overlay window for showing explanations
        Window("Overlay", id: "overlay") {
            if let text = appState.selectedText {
                OverlayView(selectedText: text) {
                    appState.closeOverlay()
                }
            }
        }
        .windowStyle(.plain)
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }
}

struct MenuContent: View {
    @ObservedObject var appState: AppState
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Group {
            Button("About Cleo") {
                appState.showAboutAlert()
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

// Observable state manager for the app
class AppState: ObservableObject {
    @Published var selectedText: String?
    private var eventMonitor: Any?
    var openWindowAction: ((String) -> Void)?
    private var isWindowVisible: Bool = false

    init() {
        checkAndRequestPermissions()
    }

    deinit {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    func showAboutAlert() {
        let alert = NSAlert()
        alert.messageText = "Cleo - AI Text Analysis"
        alert.informativeText = "Select some text, and press Cmd+Shift+E to analyze it."
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    func checkAndRequestPermissions() {
        checkAccessibilityPermissions()
        setupKeyboardMonitor()
    }

    func checkAccessibilityPermissions() {
        let accessEnabled = AXIsProcessTrusted()

        if !accessEnabled {
            print("Requesting accessibility permissions...")
            let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
            let _ = AXIsProcessTrustedWithOptions(options)
        } else {
            print("Accessibility permissions granted")
        }
    }

    func setupKeyboardMonitor() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.modifierFlags.contains([.command, .shift]) && event.keyCode == 14 {
                self?.handleShortcut()
            }
        }
    }

    func handleShortcut() {
        print("Shortcut detected!")

        if let text = getSelectedText(), !text.isEmpty {
            print("Selected text: \(text)")

            // Check if this is the same text as currently stored
            if text == selectedText {
                print("Same text - just toggling visibility")
                // Same text - just toggle window (don't regenerate)
                if isWindowVisible {
                    closeOverlay()
                } else {
                    openOverlayWindow()
                    isWindowVisible = true
                }
            } else {
                // New text - close old window and show new one with fresh explanation
                print("New text - generating new explanation")
                closeOverlay()
                showOverlay(with: text)
                isWindowVisible = true
            }
        } else {
            print("No text selected - toggling window visibility")
            // No text selected: toggle window visibility
            if isWindowVisible {
                closeOverlay()
            } else {
                // Reopen with last explanation if available
                if selectedText != nil {
                    openOverlayWindow()
                    isWindowVisible = true
                }
            }
        }
    }

    func getSelectedText() -> String? {
        let pasteboard = NSPasteboard.general
        let oldContents = pasteboard.string(forType: .string)

        let source = CGEventSource(stateID: .combinedSessionState)

        let cmdDown = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: true)
        let cDown = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: true)
        let cUp = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: false)
        let cmdUp = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: false)

        cmdDown?.flags = .maskCommand
        cDown?.flags = .maskCommand
        cUp?.flags = .maskCommand

        cmdDown?.post(tap: .cghidEventTap)
        cDown?.post(tap: .cghidEventTap)
        cUp?.post(tap: .cghidEventTap)
        cmdUp?.post(tap: .cghidEventTap)

        Thread.sleep(forTimeInterval: 0.1)

        let selectedText = pasteboard.string(forType: .string)

        if selectedText == oldContents || selectedText?.isEmpty == true {
            return nil
        }

        return selectedText
    }

    func showOverlay(with text: String) {
        DispatchQueue.main.async { [weak self] in
            self?.selectedText = text
            self?.openOverlayWindow()
        }
    }

    func openOverlayWindow() {
        // Open the overlay window using SwiftUI's window management
        openWindowAction?("overlay")

        // Configure window appearance after opening
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "overlay" }) {
                window.level = .floating
                window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
                window.isMovableByWindowBackground = true  // Make entire window draggable
                window.makeKeyAndOrderFront(nil)  // Allow window to become key so it works properly
            }
        }
    }

    func closeOverlay() {
        DispatchQueue.main.async { [weak self] in
            if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "overlay" }) {
                window.close()
            }
            self?.isWindowVisible = false
            // Keep selectedText so window can be reopened with same content
        }
    }
}
