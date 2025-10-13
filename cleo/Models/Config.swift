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
    
    static func getPrompt(_ text: String) -> String {
        return """
        Explain the following text in simple, clear terms (under 100 words).

        Format your answer in Markdown using headings, bolding, bullet points, and spacing.
        Do NOT include triple backticks ``` in the output.

        Text to explain: "\(text)"

        Explanation:
        """
    }}
