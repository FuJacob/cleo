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
        Explain the following text in simple, clear terms. Keep your explanation concise (under 100 words).
        
        Text to explain: "\(text)"
        
        Explanation:
        """}
}
