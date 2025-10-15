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
    static let shared = AppState()
    private let hasLaunchedKey = "hasLaunchedBefore"
    
    var isFirstLaunch: Bool {
        return !UserDefaults.standard.bool(forKey: hasLaunchedKey)
    }
    
    func markAsLaunched() {
        UserDefaults.standard.set(true, forKey: hasLaunchedKey)
    }
    
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
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.modifierFlags.contains([.command, .control]) && ShortcutsConfig.avaliableShortcuts.contains(Int(event.keyCode)) {
                self?.handleShortcut(keyCode: Int(event.keyCode))
            }
        }
    }

    func handleShortcut(keyCode: Int) {
        print("Shortcut detected!")

        selectedShortcut = keyCode

        // Determine which window to open based on shortcut
        let windowId: String = (keyCode == 0) ? "promptOverlay" : "overlay"

        if let text = ClipboardService.getSelectedText(), !text.isEmpty {
            print("Selected text: \(text)")

            // Check if this is the same text as currently stored
            if text == selectedText {
                print("Same text - just toggling visibility")
                // Same text - just toggle window (don't regenerate)
                if isWindowVisible {
                    closeOverlay(windowId)
                } else {
                    openOverlayWindow(windowId)
                    isWindowVisible = true
                }
            } else {
                // New text - close old window and show new one with fresh explanation
                print("New text - generating new explanation")
                closeOverlay(windowId)
                showOverlay(with: text, windowId: windowId)
                isWindowVisible = true
            }
        } else {
            print("No text selected - toggling window visibility")
            // No text selected: toggle window visibility
            if isWindowVisible {
                closeOverlay(windowId)
            } else {
                // Reopen with last explanation if available
                if selectedText != nil {
                    openOverlayWindow(windowId)
                    isWindowVisible = true
                }
            }
        }
    }

    // MARK: - Window Management

    func showOverlay(with text: String, windowId: String) {
        DispatchQueue.main.async { [weak self] in
            self?.selectedText = text
            self?.openOverlayWindow(windowId)
        }
    }

    func openOverlayWindow(_ windowId: String) {
        // Open the overlay window using SwiftUI's window management
        openWindowAction?(windowId)

        // Configure window appearance after opening
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == windowId }) {
                window.level = .floating
                window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
                window.isMovableByWindowBackground = true

                // For promptOverlay, make sure it can accept key events
                if windowId == "promptOverlay" {
                    window.makeKeyAndOrderFront(nil)
                    window.makeFirstResponder(window.contentView)
                } else {
                    window.makeKeyAndOrderFront(nil)
                }
            }
        }
    }

    func closeOverlay(_ windowId: String) {
        DispatchQueue.main.async { [weak self] in
            if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == windowId }) {
                window.close()
            }
            self?.isWindowVisible = false
            // Keep selectedText so window can be reopened with same content
        }
    }
}
