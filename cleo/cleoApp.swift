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
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
        
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
    
    
    
}


class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    
    var overlayWindow: NSWindow?
    
    var eventMonitor: Any?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {

            button.image = NSImage(systemSymbolName: "sparkles", accessibilityDescription: "Meet Cleo.")


            button.action = #selector(statusBarButtonClicked)

            checkAndRequestPermissions()
        }
    }
    
    @objc func statusBarButtonClicked() {
        let alert = NSAlert()
        alert.messageText = "Cleo - AI Text Analysis"
        alert.informativeText = "Select some text, and press Cmd+Shift+E to analyze it."
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    
    // This function checks and requests all necessary permissions
    func checkAndRequestPermissions() {
        checkAccessibilityPermissions()
        setupKeyboardMonitor()
    }

    // This function checks if we have accessibility permissions
    func checkAccessibilityPermissions() {
        let accessEnabled = AXIsProcessTrusted()

        if !accessEnabled {
            print("Requesting accessibility permissions...")
            // Show the permission dialog
            let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
            let _ = AXIsProcessTrustedWithOptions(options)
        } else {
            print("Accessibility permissions granted")
        }
    }
    
    
    // This function sets up a listener for keyboard shortcuts
    func setupKeyboardMonitor() {
        // addGlobalMonitorForEvents listens for keyboard events ANYWHERE on the Mac
        // Not just in our app, but in ANY app
        // .keyDown means we're listening for key press events
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            // [weak self] prevents memory leaks by not holding a strong reference to self
            // event contains information about the key that was pressed
            
            // Check if Command + Shift keys are held down
            // AND if the E key (keyCode 14) was pressed
            if event.modifierFlags.contains([.command, .shift]) && event.keyCode == 14 {
                // If both conditions are true, call our handleShortcut function
                self?.handleShortcut()
            }
        }
    }
    
    
    func handleShortcut() {
        print("Shortcut detected!")
        
        // Try to get the text the user has selected
        if let selectedText = getSelectedText() {
            // If we got text successfully, print it and show the overlay
            print("Selected text: \(selectedText)")
            showOverlay(with: selectedText)
        } else {
            // If no text was selected, show an error message
            print("No text selected")
            showError("No text selected. Please select some text first.")
        }
    }
    
    
    
    // This function gets whatever text the user has selected in any app
    // It returns an optional String (String?) because it might fail
    func getSelectedText() -> String? {
        // Access the system clipboard (where copied text is stored)
        let pasteboard = NSPasteboard.general
        
        // Save whatever is currently on the clipboard
        // We'll restore this later so we don't mess up the user's clipboard
        let oldContents = pasteboard.string(forType: .string)
        
        // We're going to simulate pressing Cmd+C to copy selected text
        // CGEventSource creates keyboard events
        let source = CGEventSource(stateID: .combinedSessionState)
        
        // Create virtual key press events
        // 0x37 is the keycode for Command key
        // 0x08 is the keycode for C key
        let cmdDown = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: true)
        let cDown = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: true)
        let cUp = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: false)
        let cmdUp = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: false)
        
        // Set the Command modifier flag on the events
        cmdDown?.flags = .maskCommand
        cDown?.flags = .maskCommand
        cUp?.flags = .maskCommand
        
        // Actually send these keyboard events to the system
        // This simulates the user pressing Cmd+C
        cmdDown?.post(tap: .cghidEventTap)
        cDown?.post(tap: .cghidEventTap)
        cUp?.post(tap: .cghidEventTap)
        cmdUp?.post(tap: .cghidEventTap)
        
        // Wait 0.1 seconds for the clipboard to update with the copied text
        Thread.sleep(forTimeInterval: 0.1)
        
        // Get whatever is now on the clipboard (should be the selected text)
        let selectedText = pasteboard.string(forType: .string)
        
        // Check if we actually got new text
        // If the clipboard is the same as before, or empty, nothing was selected
        if selectedText == oldContents || selectedText?.isEmpty == true {
            return nil // Return nil to indicate failure
        }
        
        // Return the selected text
        return selectedText
    }
    
    
    // This function shows the overlay window with the explanation
    func showOverlay(with text: String) {
        // Close any existing overlay window first
        // This ensures we only have one overlay at a time
        overlayWindow?.close()
        overlayWindow = nil

        // Create our SwiftUI view for the overlay
        // onClose is a callback that will be called when user clicks the X button
        let overlayView = OverlayView(selectedText: text) { [weak self] in
            DispatchQueue.main.async {
                self?.overlayWindow?.close()
                self?.overlayWindow = nil
            }
        }
        
        // NSHostingView wraps a SwiftUI view so it can be used in an NSWindow
        // (NSWindow is the old AppKit way of creating windows)
        let hostingView = NSHostingView(rootView: overlayView)
        
        // Create a new window for our overlay
        overlayWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 300), // Size and position
            styleMask: [.borderless, .nonactivatingPanel], // No title bar, doesn't steal focus
            backing: .buffered, // How the window is drawn (buffered is standard)
            defer: false // Create the window immediately
        )
        
        // Configure the window appearance and behavior
        overlayWindow?.contentView = hostingView // Put our view inside the window
        overlayWindow?.backgroundColor = .clear // Transparent background
        overlayWindow?.isOpaque = false // Allow transparency
        overlayWindow?.level = .floating // Float above other windows
        overlayWindow?.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary] // Show on all desktops
        
        // Center the window on the screen
        if let screen = NSScreen.main, let window = overlayWindow {
            let screenRect = screen.visibleFrame // Get the visible area (excluding menu bar)
            let windowRect = window.frame // Get our window's size

            // Calculate center position
            let x = screenRect.midX - windowRect.width / 2
            let y = screenRect.midY - windowRect.height / 2

            // Move the window to the center
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }
        
        // Show the window
        overlayWindow?.makeKeyAndOrderFront(nil)
    }
    
    // This function shows an error dialog
    func showError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "Error" // Title
        alert.informativeText = message // Error message
        alert.alertStyle = .warning // Warning style (yellow icon)
        alert.addButton(withTitle: "OK") // OK button
        alert.runModal() // Show and wait for user to click
    }
}
