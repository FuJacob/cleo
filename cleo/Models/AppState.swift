//
//  AppState.swift
//  cleo
//
//  Created by Jacob Fu on 2025-10-11.
//

import SwiftUI
import AppKit

/// Main application state manager
class AppState: ObservableObject {
    @Published var selectedText: String?
    @Published var selectedShortcut: Int?
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

    // MARK: - UI Actions

    func showAboutAlert() {
        let alert = NSAlert()
        alert.messageText = "Cleo - AI Text Analysis"
        alert.informativeText = "Select some text, and press Cmd+Shift+E to analyze it."
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    // MARK: - Permissions

    func checkAndRequestPermissions() {
        checkAccessibilityPermissions()
        setupKeyboardMonitor()
    }

    private func checkAccessibilityPermissions() {
        let accessEnabled = AXIsProcessTrusted()

        if !accessEnabled {
            print("Requesting accessibility permissions...")
            let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
            let _ = AXIsProcessTrustedWithOptions(options)
        } else {
            print("Accessibility permissions granted")
        }
    }

    // MARK: - Keyboard Monitoring

    private func setupKeyboardMonitor() {
        let validKeyCodes = Set([14, 1])
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.modifierFlags.contains([.command, .control]) && validKeyCodes.contains(Int(event.keyCode)) {
                self?.handleShortcut(keyCode: Int(event.keyCode))
            }
        }
    }

    func handleShortcut(keyCode: Int) {
        print("Shortcut detected!")
        
        selectedShortcut = keyCode
        if let text = ClipboardService.getSelectedText(), !text.isEmpty {
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

    // MARK: - Window Management

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
                window.isMovableByWindowBackground = true
                window.makeKeyAndOrderFront(nil)
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
