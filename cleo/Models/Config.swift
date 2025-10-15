//
//  AIConfig.swift
//  cleo
//
//  Created by Jacob Fu on 2025-10-11.
//
import Foundation

struct AIConfig {
    static let ollamaURL = "http://localhost:11435/api/generate"
    static let model = "llama3.2:1b"
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
        Revise the following text to improve grammar and clarity. Never use em dashes in your text. Avoid heavily altering the sentence structure. Output ONLY the revised text with no explanations, notes, or meta-commentary. Do not add parenthetical explanations or comments about your changes. Preserve all original line breaks, paragraph spacing, and formatting.

        Text: \(text)
        """
    }

    static func getCustomPrompt(userPrompt: String, text: String) -> String {
        return """
        Respond in valid JSON format with exactly two fields: "type" and "response".

        Classification rules:
        - type: "question" → user wants information, explanation, or understanding about the text
        - type: "generate" → user wants to create, modify, or generate new text

        Rules:
        - Output ONLY valid JSON with no extra commentary
        - Do NOT add explanations or notes outside the JSON
        - The "response" field should contain your actual answer or generated text

        User request: \(userPrompt)
        Text: \(text)

        Example output format:
        {"type": "question", "response": "Your answer here"}
        OR
        {"type": "generate", "response": "Generated text here"}
        """
    }
}

struct ShortcutsConfig {
    // 14: E, 13: W, 1: S, 0: A, 17: T
    static let avaliableShortcuts = Set([14, 13, 1, 17, 0])
    static let shortcutCodeToChar: [Int: String] = [
        14: "E",
        13: "W",
        1: "S",
        0: "A",
        17: "T"
    ]
}
