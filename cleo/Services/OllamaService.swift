//
//  OllamaService.swift
//  cleo
//
//  Created by Jacob Fu on 2025-10-11.
//
import Foundation


struct OllamaService {
    
    func explainTextWithStreaming(_ text: String, onStreamStart: @MainActor @escaping () -> Void, onChunk: @MainActor @escaping (String) -> Void) async throws {
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
            "prompt": Config.getPrompt(text),
            "stream": true
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
            "prompt": Config.getPrompt(text), // Our question
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
