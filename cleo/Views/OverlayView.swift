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
            return screen.visibleFrame.height
        }
        return 1000
    }

    var body: some View {
        if #available(macOS 26.0, *) {
            GlassEffectContainer(spacing: 8) {
                VStack(alignment: .leading, spacing: 0) {
                    // Header with close button
                    HStack {
                        Image("cleo_logo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 14)

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
                        ScrollView {
                            Markdown(explanation)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                
                        }.frame(maxHeight: maxScreenHeight)}
                }
                .padding(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 32)
                        .strokeBorder(Color.cleoAshGray.opacity(0.3), lineWidth: 0.5)
                )
                .glassEffect(.regular.tint(Color.cleoFloralWhite.opacity(0.7)), in: .rect(cornerRadius: 32))
                .glassEffectID("main-container", in: glassNamespace)
                .animation(.easeInOut, value: explanation)
                .fixedSize(horizontal: false, vertical: true)
            }
            .frame(width: 400)
            .frame(maxHeight: maxScreenHeight)
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

    private func fetchExplanation() async {
        let service = OllamaService()

        do {
            
            // Streaming: update UI as each chunk arrives
            if selectedShortcut == 13
            {
                print("🔵 [OVERLAY] Starting revision workflow for shortcut 13")
                do {
                    print("🔵 [OVERLAY] Calling reviseText...")
                    let result = try await service.reviseText(selectedText)
                    print("🔵 [OVERLAY] Got result: \(result.prefix(50))...")

                    // Create a detached task that won't be cancelled when window closes
                    Task.detached {
                        print("🔵 [DETACHED] Starting paste workflow")

                        // Close the overlay first to restore focus
                        await MainActor.run {
                            print("🔵 [DETACHED] Closing overlay window")
                            self.onClose()
                        }

                        // Wait for window to close and focus to shift
                        print("🔵 [DETACHED] Waiting 200ms for focus shift...")
                        try? await Task.sleep(nanoseconds: 200_000_000) // 200ms

                        // Now paste on main thread
                        await MainActor.run {
                            print("🔵 [DETACHED] Calling pasteGeneratedText")
                            ClipboardService.pasteGeneratedText(text: result)
                            print("🔵 [DETACHED] Paste completed!")
                        }
                    }
                }
                catch {
                    print("🔴 [OVERLAY] Error in revision workflow: \(error)")
                    await MainActor.run {
                        self.hasError = true
                        self.explanation = "Failed to paste generated text: \(error.localizedDescription)"
                        self.isLoading = false
                    }
                }
                return
            }
            
            
            if Config.stream {
                // Clear "Thinking..." before streaming starts
                
                print(self.isLoading)
                print(self.explanation)


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
