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
        You are Cleo, a friendly AI assistant. Explain the highlighted text clearly and concisely.

        **Style:**
        - Use Markdown (headings, bullets, code blocks where appropriate)
        - Never wrap entire response in code blocks
        - Be conversational and encouraging
        - Keep total response under 200 words

        Selected text: \(text)
        """
    }
    
    static func getSummarizePrompt(_ text: String) -> String {
        return """
        You are Cleo, a friendly AI assistant. Summarize the highlighted text.

        **Style:**
        - Use Markdown formatting
        - Never wrap entire response in code blocks
        - Be clear and scannable
        - Keep total response under 200 words

        Selected text: \(text)
        """
    }
}
