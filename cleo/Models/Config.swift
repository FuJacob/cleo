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
        Explain this text clearly and concisely. Use Markdown formatting (bold, italics, lists, and headers) for structure and clarity. Do NOT use code blocks or backticks in your response.

        Text: \(text)
        """
    }

    static func getSummarizePrompt(_ text: String) -> String {
        return """
        Provide a short, clear summary. Use Markdown formatting (bold, italics, lists, and headers) for readability. Do NOT use code blocks or backticks in your response.

        Text: \(text)
        """
    }
    static func getRevisionPrompt(_ text: String) -> String {
        return """
        Revise the following text to improve grammar, clarity, and flow. Output ONLY the revised text with no explanations, notes, or meta-commentary. Do not add parenthetical explanations or comments about your changes. Preserve all original line breaks, paragraph spacing, and formatting.

        Text: \(text)
        """
    }
}
