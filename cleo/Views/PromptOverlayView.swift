import Foundation
import SwiftUI

struct PromptOverlayView: View {
    let selectedText: String
    let onClose: () -> Void

    @State private var customPrompt: String = ""
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Logo on the left
            Image("cleo_logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 18, height: 18)

            // Text input
            TextField("Ask anything about this text...", text: $customPrompt, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .lineLimit(1...5)
                .focused($isTextFieldFocused)
                .onSubmit {
                    submitPrompt()
                }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(Color.cleoAshGray.opacity(0.3), lineWidth: 0.5)
        )
        .cornerRadius(24)
        .frame(width: 450)
        .fixedSize(horizontal: false, vertical: true)
        .task {
            try? await Task.sleep(nanoseconds: 150_000_000)
            isTextFieldFocused = true
        }
    }

    private func submitPrompt() {
        guard !customPrompt.isEmpty else { return }

        // Close the prompt overlay first
        onClose()

        // Use the AI service to get response
        Task {
            do {
                let service = OllamaService()
                let result = try await service.generateCustomText(userPrompt: customPrompt, text: selectedText)

                print("🟢 [PROMPT] Got result - type: \(result.type), response: \(result.response.prefix(50))...")

                if result.type == "question" {
                    // Open overlay to show the response
                    await MainActor.run {
                        AppState.shared.selectedText = selectedText
                        AppState.shared.selectedShortcut = 14 // Use explain shortcut for display
                        AppState.shared.showOverlay(with: selectedText, windowId: "overlay")
                    }
                } else {
                    // Generate type - paste the generated text
                    print("🟢 [PROMPT] Type is generate, pasting text")

                    Task.detached {
                        // Wait a bit for focus to shift back to original app
                        try? await Task.sleep(nanoseconds: 200_000_000) // 200ms

                        await MainActor.run {
                            ClipboardService.pasteGeneratedText(text: result.response)
                            print("🟢 [PROMPT] Paste completed!")
                        }
                    }
                }
            } catch {
                print("🔴 [PROMPT] Error: \(error)")
            }
        }
    }
}
