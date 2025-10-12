import Foundation
import SwiftUI

struct OverlayView: View {
    let selectedText: String
    let onClose: () -> Void
    
    @State private var explanation: String = "Thinking..."
    @State private var isLoading: Bool = true
    @State private var fetchTask: Task<Void, Never>?  // ✅ Store task
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.blue)
                
                Text("AI Explanation")
                    .font(.headline)
                
                Spacer()
                
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Selected Text:").font(.caption).foregroundStyle(.secondary)
                Text(selectedText).font(.body)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Explanation:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ScrollView {
                    if isLoading {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text(explanation)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text(explanation)
                            .font(.body)
                            .textSelection(.enabled)
                    }
                }
                .frame(maxHeight: 150)
            }
        }
        .padding(20)
        .frame(width: 500)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        )
        .onAppear {
            fetchTask = Task {  // ✅ Store the task
                await fetchExplanation()
            }
        }
        .onDisappear {  // ✅ Cancel when view disappears
            fetchTask?.cancel()
            fetchTask = nil
        }
    }
    
    func fetchExplanation() async {  // ✅ Make this async directly
        let service = OllamaService()
        
        do {
            let result = try await service.explainText(selectedText)
            
            guard !Task.isCancelled else { return }  // ✅ Check cancellation
            
            await MainActor.run {
                self.explanation = result
                self.isLoading = false
            }
        }
        catch {
            guard !Task.isCancelled else { return }  // ✅ Check cancellation
            
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
}
