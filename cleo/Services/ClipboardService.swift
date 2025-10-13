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

        Thread.sleep(forTimeInterval: 0.1)

        let selectedText = pasteboard.string(forType: .string)

        if selectedText == oldContents || selectedText?.isEmpty == true {
            return nil
        }

        return selectedText
    }
}
