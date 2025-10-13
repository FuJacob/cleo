import Foundation
import SwiftUI

struct OverlayView: View {
    let selectedText: String
    let onClose: () -> Void

    @State private var explanation: String = "Thinking..."
    @State private var isLoading: Bool = true
    @State private var hasError: Bool = false
    @State private var fetchTask: Task<Void, Never>?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Minimal header with close button (draggable area)
            HStack {
                Text("cleo")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)

                if hasError {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 9))
                        .foregroundColor(.orange)
                        .help("Connection error - check if Ollama is running")
                }

                Spacer()

                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Close")
            }
            .padding(.vertical, 2)
            .contentShape(Rectangle())  // Makes entire header draggable

            Divider()

            // Selected text section
            VStack(alignment: .leading, spacing: 3) {
                Text("Selected")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.tertiary)
                    .textCase(.uppercase)

                Text(selectedText)
                    .font(.system(size: 11))
                    .lineLimit(3)
            }

            Divider()

            // Explanation section
            VStack(alignment: .leading, spacing: 3) {
                Text("Explanation")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.tertiary)
                    .textCase(.uppercase)

                ScrollView {
                    if isLoading {
                        HStack(spacing: 6) {
                            ProgressView()
                                .scaleEffect(0.6)
                                .frame(width: 12, height: 12)
                            Text(explanation)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 2)
                    } else {
                        Text(explanation)
                            .font(.system(size: 11))
                            .textSelection(.enabled)
                    }
                }
                .frame(maxHeight: 300)
            }
        }
        .padding(12)
        .frame(width: 400)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(color: .black.opacity(0.25), radius: 15, x: 0, y: 8)
        )
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
