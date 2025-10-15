//
//  OllamaService.swift
//  cleo
//
//  Created by Jacob Fu on 2025-10-11.
//
import Foundation


struct OllamaService {
    
    func generateTextWithStreaming(_ text: String, _ selectedShortcut: Int, onStreamStart: @MainActor @escaping () -> Void, onChunk: @MainActor @escaping (String) -> Void) async throws {
        guard let url = URL(string: AIConfig.ollamaURL) else {
            throw NSError(domain: "Invalid URL", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid Ollama URL"])
        }
        var isFirstChunk = true;

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Determine which prompt to use based on shortcut
        let prompt: String
        switch selectedShortcut {
        case 14: // E - Explain
            prompt = AIConfig.getExplanationPrompt(text)
        case 1: // S - Summarize
            prompt = AIConfig.getSummarizePrompt(text)
        case 17: // T - Translate
            prompt = AIConfig.getTranslatePrompt(text)
        default:
            prompt = AIConfig.getExplanationPrompt(text)
        }

        let body: [String: Any] = [
            "model": AIConfig.model,
            "prompt": prompt,
            "stream": true,
            "options": [
                "temperature": 0.5,
                "top_p": 0.8,
                "top_k": 40,
                "repeat_penalty": 1.2,
                "repeat_last_n": 64,
                "mirostat": 0,
                "num_ctx": 512,
                "num_predict": 250,
                "min_p": 0.05,
                "seed": 42
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (bytes, response) = try await URLSession.shared.bytes(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        for try await line in bytes.lines {
            if let data = line.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let chunk = json["response"] as? String {
                await MainActor.run {onChunk(chunk)}
                if isFirstChunk {
                    await onStreamStart()
                    isFirstChunk = false
                }
            }
        }
    }
    
    
    func generateText(_ text: String, _ prompt: String, jsonSchema: [String: Any]? = nil) async throws -> String {
        print("🟢 [OLLAMA] Starting generation of text")
        guard let url = URL(string: AIConfig.ollamaURL) else {
            throw NSError(domain: "Invalid URL", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid Ollama URL"])
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        // Force NON-streaming for revise text since we need the complete result before pasting
        var requestBody: [String: Any] = [
            "model": AIConfig.model,
            "prompt": prompt,
            "stream": false,
            "options": [
                "num_ctx": 512  // minimal context window for speed
            ]
        ]

        if let schema = jsonSchema {
            requestBody["format"] = schema
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        print("🟢 [OLLAMA] Sending request to \(url)")

        let (data, response) = try await URLSession.shared.data(for: request)
        print("🟢 [OLLAMA] Got response, data size: \(data.count) bytes")

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(
                domain: "Invalid response",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid HTTP response"]
            )
        }

        print("🟢 [OLLAMA] HTTP status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("🔴 [OLLAMA] HTTP error: \(errorMessage)")
            throw NSError(
                domain: "Ollama Error",
                code: httpResponse.statusCode,
                userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode): \(errorMessage)"]
            )
        }

        let jsonString = String(data: data, encoding: .utf8) ?? "unable to decode"
        print("🟢 [OLLAMA] Response JSON: \(jsonString.prefix(200))")

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let responseText = json["response"] as? String else {
            print("🔴 [OLLAMA] Failed to parse JSON response")
            throw NSError(
                domain: "Parse Error",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to parse response"]
            )
        }

        print("🟢 [OLLAMA] Successfully parsed response: \(responseText.prefix(50))...")
        return responseText
    }
    
    
    func generateRevisedText(_ text: String) async throws -> String {
        let responseText = try await generateText(text, AIConfig.getRevisionPrompt(text))
        return responseText
    }
    

    func generateCustomText(userPrompt: String, text: String) async throws -> (type: String, response: String) {
        // Define JSON schema for the response
        let jsonSchema: [String: Any] = [
            "type": "object",
            "properties": [
                "type": [
                    "type": "string",
                    "enum": ["question", "generate"]
                ],
                "response": [
                    "type": "string"
                ]
            ],
            "required": ["type", "response"]
        ]

        let responseText = try await generateText(text, AIConfig.getCustomPrompt(userPrompt: userPrompt, text: text), jsonSchema: jsonSchema)

        // The response contains JSON, parse it
        guard let data = responseText.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: String],
              let type = json["type"],
              let response = json["response"] else {
            print("🔴 [OLLAMA] Failed to parse custom text response")
            throw NSError(domain: "Parse error", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse JSON response"])
        }

        print("🟢 [OLLAMA] Custom text type: \(type), response: \(response.prefix(50))...")
        return (type: type, response: response)
    }
}
