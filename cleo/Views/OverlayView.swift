import Foundation
import SwiftUI
import MarkdownUI
struct OverlayView: View {
    let selectedText: String
    let selectedShortcut: Int
    let onClose: () -> Void

    @State private var explanation: String = ""
    @State private var isLoading: Bool = true
    @State private var hasError: Bool = false
    @State private var fetchTask: Task<Void, Never>?
    @Namespace private var glassNamespace

    private var maxScreenHeight: CGFloat {
        if let screen = NSScreen.main {
            return screen.visibleFrame.height / 2
        }
        return 400
    }

    var body: some View {
        if #available(macOS 26.0, *) {
            GlassEffectContainer(spacing: 8) {
                VStack(alignment: .leading, spacing: 0) {
                    // Header with close button
                    HStack {
                        Text("cleo")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.primary)

                        if hasError {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 9))
                                .foregroundColor(.orange)
                                .help("Connection error - check if Ollama is running")
                        }

                        Spacer()

                        Button(action: onClose) {
                            Image(systemName: "xmark")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.borderless)
                        .help("Close")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)

                    // Selected text
                    Text(selectedText)
                        .font(.system(size: 12))
                        .lineLimit(3)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // Divider
                    Divider()
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)

                    // Explanation
                    if isLoading {
                        HStack(spacing: 6) {
                            ProgressView()
                                .scaleEffect(0.6)
                            Text("Thinking...")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                    } else {
                        Markdown(explanation)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(10)
                .frame(width: 400)
                .fixedSize(horizontal: true, vertical: false)
                .overlay(
                    RoundedRectangle(cornerRadius: 32)
                        .strokeBorder(.gray.opacity(0.9), lineWidth: 0.5)
                )
                .glassEffect(.regular.tint(Color.black.opacity(0.9)), in: .rect(cornerRadius: 32))
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

        isLoading = true
        explanation = ""
        fetchTask = Task {
            await fetchExplanation()
        }
    }

    func fetchExplanation() async {
        let service = OllamaService()

        do {
            if Config.stream {
                // Clear "Thinking..." before streaming starts
                
                print(self.isLoading)
                print(self.explanation)


                // Streaming: update UI as each chunk arrives
                try await service.generateTextWithStreaming(selectedText,selectedShortcut, onStreamStart: { self.isLoading = false}) { chunk in
                    print(self.explanation);
                    self.explanation += chunk};
                
            } else {
                // Non-streaming: get complete response
                let result = try await service.explainText(selectedText)

                guard !Task.isCancelled else { return }

                await MainActor.run {
                    self.explanation = result
                    self.isLoading = false
                }
            }
            print("FINAL EXPLANATION:", self.explanation)
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
