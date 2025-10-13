import Foundation
import SwiftUI

struct OverlayView: View {
    let selectedText: String
    let onClose: () -> Void

    @State private var explanation: String = "Thinking..."
    @State private var isLoading: Bool = true
    @State private var hasError: Bool = false
    @State private var fetchTask: Task<Void, Never>?
    @Namespace private var glassNamespace
    
    var body: some View {
        if #available(macOS 26.0, *) {
            GlassEffectContainer(spacing: 16) {
                VStack(alignment: .leading, spacing: 14) {
                    // Header with close button using interactive glass
                    HStack {
                        Text("cleo")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.primary)
                        
                        if hasError {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.orange)
                                .help("Connection error - check if Ollama is running")
                                .glassEffect(.regular.tint(.orange).interactive())
                        }
                        
                        Spacer()
                        
                        Button(action: onClose) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 20))
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.glass)
                        .help("Close")
                    }
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                    
                    // Selected text section with glass effect
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Selected")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                        
                        Text(selectedText)
                            .font(.system(size: 13))
                            .lineLimit(3)
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .glassEffect(.regular, in: .rect(cornerRadius: 14))
                            .glassEffectID("selected-text", in: glassNamespace)
                    }
                    
                    // Explanation section with glass effect
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Explanation")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                        
                        ScrollView {
                            if isLoading {
                                HStack(spacing: 10) {
                                    ProgressView()
                                        .scaleEffect(0.75)
                                    Text(explanation)
                                        .font(.system(size: 13))
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(14)
                            } else {
                                Text(explanation)
                                    .font(.system(size: 13))
                                    .textSelection(.enabled)
                                    .padding(14)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .frame(maxHeight: 340)
                        .glassEffect(.regular, in: .rect(cornerRadius: 14))
                        .glassEffectID("explanation", in: glassNamespace)
                    }
                }
                .padding(22)
                .frame(width: 460)
                .glassEffect(.regular.tint(.blue).interactive(), in: .rect(cornerRadius: 26))
                .glassEffectID("main-container", in: glassNamespace)
            }
            .onAppear {
                startFetching()
            }
            .onChange(of: selectedText) { _, _ in
                startFetching()
            }
            .onDisappear {
                fetchTask?.cancel()
                fetchTask = nil
            }
        } else {
            // Fallback on earlier versions
        }
    }

    private func startFetching() {
        fetchTask?.cancel()

        explanation = "Thinking..."
        isLoading = true

        fetchTask = Task {
            await fetchExplanation()
        }
    }

    func fetchExplanation() async {
        let service = OllamaService()

        do {
            if Config.stream {
                // Clear "Thinking..." before streaming starts
        


                // Streaming: update UI as each chunk arrives
                try await service.explainTextWithStreaming(selectedText) { chunk in
                    if self.isLoading {
                        self.isLoading = false
                        self.explanation = chunk
                    }
                    else {
                        self.explanation += chunk}
                }
            } else {
                // Non-streaming: get complete response
                let result = try await service.explainText(selectedText)

                guard !Task.isCancelled else { return }

                await MainActor.run {
                    self.explanation = result
                    self.isLoading = false
                }
            }
        }
        catch {
            guard !Task.isCancelled else { return }

            await MainActor.run {
                self.hasError = true
                self.explanation = "Unable to connect. Make sure Ollama is running:\n• ollama serve\n• ollama pull \(Config.model)"
                self.isLoading = false
            }
        }
    }
}
