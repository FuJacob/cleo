//
//  OverlayView.swift
//  cleo
//
//  Created by Jacob Fu on 2025-10-11.
//

import SwiftUI


struct OverlayView: View {
    let selectedText: String
    let onClose: () -> Void
    
    @State private var explanation: String = "Thinking..."
    @State private var isLoading: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // HEADER SECTION
            // HStack stacks views horizontally (left to right)
            HStack {
                // Show a sparkles icon
                Image(systemName: "sparkles")
                    .foregroundColor(.blue) // Make it blue
                
                // Title text
                Text("AI Explanation")
                    .font(.headline) // Make it bold and larger
                
                // Spacer pushes everything to the edges
                // This pushes the X button to the right
                Spacer()
                
                // Close button (X)
                Button(action: onClose) { // When clicked, call onClose function
                    Image(systemName: "xmark.circle.fill") // X icon
                        .foregroundColor(.secondary) // Gray color
                }
                .buttonStyle(.plain) // No button styling, just the icon
            }
            
            // Divider creates a horizontal line
            Divider()
            
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Selected Text:").font(.caption).foregroundStyle(.secondary)
                
                Text(selectedText)
                    .font(.body)
            }
            
            Divider()
            
            // EXPLANATION SECTION
            VStack(alignment: .leading, spacing: 4) {
                // Label for the explanation
                Text("Explanation:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // ScrollView allows scrolling if content is too long
                ScrollView {
                    // Show different content based on whether we're still loading
                    if isLoading {
                        // While loading, show a spinner
                        HStack {
                            ProgressView() // Spinning loading indicator
                                .scaleEffect(0.8) // Make it slightly smaller
                            Text(explanation) // "Thinking..." text
                                .foregroundColor(.secondary)
                        }
                    } else {
                        // When done loading, show the explanation
                        Text(explanation)
                            .font(.body)
                            .textSelection(.enabled) // Allow user to select and copy text
                    }
                }
                .frame(maxHeight: 150) // Limit height to 150 points max
            }
        }
        .padding(20) // Add 20 points of space around everything
        .frame(width: 500) // Make the view 500 points wide
        .background(
            // Create a rounded rectangle for the background
            RoundedRectangle(cornerRadius: 16) // 16 point corner radius
                .fill(Color(NSColor.windowBackgroundColor)) // Use system background color
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10) // Add shadow
        )
        .onAppear {
            // onAppear runs when this view first appears on screen
            // This is where we start fetching the explanation
            fetchExplanation()
        }
    }
    
    // This function "fetches" the explanation from AI
    // Right now it's fake - we'll add real AI in the next step
    func fetchExplanation() {
        
        let service = OllamaService()
        // DispatchQueue.main.asyncAfter runs code after a delay
        // .now() + 1.5 means wait 1.5 seconds
        // This simulates waiting for an AI response
        
        
        Task {
            do {
                let result = try await service.explainText(selectedText)
                
                await MainActor.run {
                    self.explanation = result
                    self.isLoading = false
                }
            }
            catch {
                await MainActor.run {
                    self.explanation = """
                                        Error: \(error.localizedDescription)
                                        
                                        Troubleshooting:
                                        • Make sure Ollama is running (check menu bar)
                                        • Try running: ollama serve
                                        • Check if model is installed: ollama list
                                        • Pull the model: ollama pull \(Config.model)
                                        """
                    self.isLoading = false
                }
                print("❌ Error fetching explanation: \(error)")
                
            }
        }
    }}
