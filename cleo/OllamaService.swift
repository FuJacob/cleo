//
//  OllamaService.swift
//  cleo
//
//  Created by Jacob Fu on 2025-10-11.
//
import Foundation


struct OllamaService {
    
    func explainText(_ text: String) async throws -> String {
        
        
        guard let url = URL(string: Config.ollamaURL) else {
            throw NSError(domain: "Invalid URL", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid Ollama URL"])
        }
        
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let prompt = """
        Explain the following text in simple, clear terms. Keep your explanation concise (under 100 words).
        
        Text to explain: "\(text)"
        
        Explanation:
        """
        
        // STEP 5: Create the request body
        // This is the actual data we send to Ollama in JSON format
        let requestBody: [String: Any] = [
            "model": Config.model, // Which AI model to use
            "prompt": prompt, // Our question
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
            // If something went wrong, get the error message
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(
                domain: "Ollama Error",
                code: httpResponse.statusCode,
                userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode): \(errorMessage)"]
            )
        }
        
        // STEP 10: Parse the JSON response
        // Ollama sends back JSON, we need to extract the text
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
