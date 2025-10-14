# Cleo

Cleo is a macOS app that provides AI-powered text analysis and revision using local Ollama models. Select any text system-wide and instantly get explanations, summaries, or intelligent revisions.

## Features

- **Text Explanation**: Select text and get clear, concise explanations
- **Text Summarization**: Generate quick summaries of selected content
- **Text Revision**: Automatically improve grammar, clarity, and flow of selected text
- **Streaming Support**: Real-time response streaming for faster feedback
- **Floating Overlay**: Clean, modern UI with glass effect (macOS 15.0+)
- **System-Wide**: Works in any application with keyboard shortcuts

## Requirements

- macOS 15.0 or later
- Xcode 16.0 or later
- [Ollama](https://ollama.ai/) installed and running locally

## Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd cleo
```

2. Install and start Ollama:
```bash
brew install ollama
ollama serve
ollama pull phi3.5
```

3. Open `cleo.xcodeproj` in Xcode

4. Build and run the project

5. Grant accessibility permissions when prompted (required for keyboard shortcuts)

## Usage

### Keyboard Shortcuts

- **Cmd+Ctrl+E** (keycode 14): Explain selected text
- **Cmd+Ctrl+S** (keycode 1): Summarize selected text
- **Cmd+Ctrl+R** (keycode 13): Revise and paste corrected text

### How It Works

1. Select text in any application
2. Press the appropriate keyboard shortcut
3. Cleo captures the selected text and sends it to your local Ollama instance
4. For explanations/summaries: View results in the floating overlay window
5. For revisions: The corrected text is automatically pasted back

## Configuration

Edit `cleo/Models/Config.swift` to customize:

```swift
struct Config {
    static let ollamaURL = "http://localhost:11435/api/generate"
    static let model = "phi3.5"
    static let stream = true
}
```

### Available Settings

- `ollamaURL`: URL of your Ollama API endpoint
- `model`: Ollama model to use (phi3.5, llama2, mistral, etc.)
- `stream`: Enable/disable response streaming

## Project Structure

```
cleo/
├── Models/
│   ├── AppState.swift          # Main application state and keyboard handling
│   └── Config.swift             # Configuration and prompts
├── Services/
│   ├── ClipboardService.swift  # Clipboard and keyboard event handling
│   └── OllamaService.swift     # Ollama API integration
└── Views/
    └── OverlayView.swift        # Floating overlay UI
```

## Prompts

Cleo uses three different prompts for different tasks:

- **Explanation Prompt**: Explains text clearly with Markdown formatting
- **Summarization Prompt**: Provides concise summaries
- **Revision Prompt**: Improves grammar and clarity while preserving formatting

Customize these prompts in `Config.swift` to match your needs.

## Permissions

Cleo requires the following permissions:

- **Accessibility Access**: Required to capture keyboard shortcuts and simulate Cmd+C/Cmd+V for text capture and pasting

Grant permissions in System Settings > Privacy & Security > Accessibility

## Troubleshooting

### "Connection refused" error
- Ensure Ollama is running: `ollama serve`
- Verify the correct port in `Config.swift`

### Keyboard shortcuts not working
- Check that accessibility permissions are granted
- Restart the app after granting permissions

### Text not being captured
- Ensure text is selected before pressing the shortcut
- Verify accessibility permissions are enabled

### Model not found
- Pull the model: `ollama pull phi3.5`
- Check the model name in `Config.swift` matches installed models

## License

MIT License

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.
