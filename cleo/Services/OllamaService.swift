//
//  OllamaService.swift
//  cleo
//
//  Created by Jacob Fu on 2025-10-11.
//
import Foundation


struct OllamaService {
    
    func generateTextWithStreaming(_ text: String, _ selectedShortcut: Int, onStreamStart: @MainActor @escaping () -> Void, onChunk: @MainActor @escaping (String) -> Void) async throws {
        guard let url = URL(string: Config.ollamaURL) else {
            throw NSError(domain: "Invalid URL", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid Ollama URL"])
        }
        var isFirstChunk = true;

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": Config.model,
            "prompt": selectedShortcut == 14 ? Config.getExplanationPrompt(text) : Config.getSummarizePrompt(text),
            "stream": true,
            "options": [
                "temperature": 0.5,        // balanced tone: stable and factual, not too creative
                "top_p": 0.8,              // focus more on likely words
                "top_k": 40,               // standard top-k filtering
                "repeat_penalty": 1.2,     // avoid repetition in concise responses
                "repeat_last_n": 64,       // moderate memory of previous tokens
                "mirostat": 0,             // disable adaptive perplexity control for stability
                "num_ctx": 2048,           // enough context for short explanations
                "num_predict": 250,        // max tokens (~2–3 paragraphs)
                "min_p": 0.05,             // filter out extremely low-probability words
                "seed": 42,                // deterministic responses for consistency
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
    
    
    func reviseText(_ text: String) async throws -> String {
        print("🟢 [OLLAMA] Starting reviseText")
        guard let url = URL(string: Config.ollamaURL) else {
            throw NSError(domain: "Invalid URL", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid Ollama URL"])
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        // Force NON-streaming for revise text since we need the complete result before pasting
        let requestBody: [String: Any] = [
            "model": Config.model,
            "prompt": Config.getRevisionPrompt(text),
            "stream": false,  // MUST be false to get complete response
        ]

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
    
    
    
    func explainText(_ text: String) async throws -> String {
        guard let url = URL(string: Config.ollamaURL) else {
            throw NSError(domain: "Invalid URL", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid Ollama URL"])
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30

        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    
        
        // STEP 5: Create the request body
        // This is the actual data we send to Ollama in JSON format
        let requestBody: [String: Any] = [
            "model": Config.model, // Which AI model to use
            "prompt": Config.getExplanationPrompt(text), // Our question
            "stream": Config.stream, // Don't stream (get full response at once)
            "options": [
                "temperature": 0.7, // How creative (0=focused, 1=creative)
                "num_predict": 200 // Maximum words to generate
            ]
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        }
        catch {
            throw NSError(domain: "JSON Error", code: -1)
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(
                domain: "Invalid response",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid HTTP response"]
            )
        }

        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(
                domain: "Ollama Error",
                code: httpResponse.statusCode,
                userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode): \(errorMessage)"]
            )
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let responseText = json["response"] as? String else {
            throw NSError(
                domain: "Parse Error",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to parse response"]
            )
        }

        return responseText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
