//
//  Config.swift
//  cleo
//
//  Created by Jacob Fu on 2025-10-11.
//
import Foundation

struct Config {
    static let ollamaURL = "http://localhost:11435/api/generate"
    static let model = "phi3.5"
    static let stream = true

    static func getExplanationPrompt(_ text: String) -> String {
        return """
        Explain this text concisely in under 75 words. Use markdown formatting where helpful. Get straight to the point - no introductions or meta-commentary.

        Text: \(text)
        """
    }

    static func getSummarizePrompt(_ text: String) -> String {
        return """
        Provide a brief summary in under 50 words. Use markdown formatting. Just give the summary - no phrases like "this summarizes" or "the text describes".

        Text: \(text)
        """
    }
}
