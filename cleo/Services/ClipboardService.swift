//
//  ClipboardService.swift
//  cleo
//
//  Created by Jacob Fu on 2025-10-11.
//

import Foundation
import AppKit

struct ClipboardService {
    /// Gets the currently selected text by simulating Cmd+C
    static func getSelectedText() -> String? {
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

        // Wait for clipboard to update
        Thread.sleep(forTimeInterval: 0.05)

        let selectedText = pasteboard.string(forType: .string)

        if let old = oldContents, !old.isEmpty {
            pasteboard.clearContents()
            pasteboard.setString(old, forType: .string)
        } else {
            pasteboard.clearContents()
        }

        if selectedText == oldContents || selectedText?.isEmpty == true {
            return nil
        }

        return selectedText
    }

    static func pasteGeneratedText(text: String) -> Void {
        print("🔧 [PASTE] Starting paste operation")
        print("🔧 [PASTE] Text to paste: \(text.prefix(50))...")

        let pasteboard = NSPasteboard.general
        let oldContents = pasteboard.string(forType: .string)
        print("🔧 [PASTE] Old clipboard: \(oldContents?.prefix(50) ?? "nil")")

        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        print("🔧 [PASTE] Set clipboard to new text")

        let source = CGEventSource(stateID: .combinedSessionState)
        print("🔧 [PASTE] Created event source")

        let cmdDown = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: true)
        let vDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
        let vUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
        let cmdUp = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: false)

        cmdDown?.flags = .maskCommand
        vDown?.flags = .maskCommand
        vUp?.flags = .maskCommand

        print("🔧 [PASTE] Posting Cmd+V events")
        cmdDown?.post(tap: .cghidEventTap)
        vDown?.post(tap: .cghidEventTap)
        vUp?.post(tap: .cghidEventTap)
        cmdUp?.post(tap: .cghidEventTap)
        print("🔧 [PASTE] Posted all keyboard events")

        // Wait for paste to complete before restoring clipboard
        Thread.sleep(forTimeInterval: 0.05)
        print("🔧 [PASTE] Waited 50ms")

        pasteboard.clearContents()
        if let old = oldContents, !old.isEmpty {
            pasteboard.setString(old, forType: .string)
            print("🔧 [PASTE] Restored old clipboard")
        }
        print("🔧 [PASTE] Paste operation complete")
    }
}
