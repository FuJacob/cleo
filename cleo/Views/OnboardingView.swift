import SwiftUI
import AppKit

struct OnboardingView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundColor(.cleoCambridgeBlue)

            Text("Welcome to Cleo")
                .font(.title)
                .fontWeight(.semibold)

            Text("AI-powered text tools, system-wide")
                .font(.subheadline)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 12) {
                FeatureRow(shortcut: "⌘⌃E", title: "Explain text")
                FeatureRow(shortcut: "⌘⌃S", title: "Summarize")
                FeatureRow(shortcut: "⌘⌃T", title: "Translate")
                FeatureRow(shortcut: "⌘⌃R", title: "Revise text")
            }
            .padding(.vertical, 8)

            Text("Requires accessibility permissions")
                .font(.caption)
                .foregroundColor(.secondary)

            Button("Get Started") {
                AppState.shared.markAsLaunched()
                if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "onboarding" }) {
                    window.close()
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(.cleoCambridgeBlue)
        }
        .padding(32)
        .frame(width: 380, height: 420)
        .background(Color.cleoFloralWhite.opacity(0.3))
    }
}

struct FeatureRow: View {
    let shortcut: String
    let title: String

    var body: some View {
        HStack(spacing: 12) {
            Text(shortcut)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 60, alignment: .leading)

            Text(title)
                .font(.body)
        }
    }
}
