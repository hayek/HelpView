# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

HelpViewExample is a demonstration iOS/macOS app that showcases the **HelpView** Swift Package. HelpView is a SwiftUI framework for adding AI-powered FAQ documentation to apps using Apple's Foundation Models (Apple Intelligence).

## Architecture

### Dual Structure
This project has two distinct parts:
1. **Host App** (`HelpViewExample/`): Xcode iOS app that demonstrates HelpView integration
2. **SPM Package** (`HelpViewExample/HelpView/`): The actual HelpView framework as a Swift Package embedded within the project

### HelpView Framework Components

**Public API:**
- `HelpView.swift` - Button with sheet presentation: displays a question mark button that presents FAQs in a sheet
- `HelpContentView` (in `FAQListView.swift`) - Embeddable content view: the help interface itself for custom navigation flows

**Core Logic:**
- `Models.swift` - Contains `FAQ`, `Topic`, `FAQCollection`, and `HelpResponse` (with `@Generable` macro for Foundation Models)
- `FAQLoader.swift` - Handles loading/parsing of FAQ data from JSON or plist files
- `AIHelper.swift` - Manages Apple Intelligence integration via `SystemLanguageModel` and `LanguageModelSession`
- `FAQListView.swift` - Main UI view model and SwiftUI components for displaying FAQs

**AI Integration Flow:**
1. `AIHelper` detects Apple Intelligence availability via `SystemLanguageModel.default.availability`
2. Creates a `LanguageModelSession` with all FAQ context in the system prompt
3. Uses `@Generable` struct (`HelpResponse`) to generate structured, typed responses
4. Falls back to text-based search when AI unavailable

## Building and Testing

### Build the Example App
```bash
# Build for simulator (iOS)
xcodebuild -scheme HelpViewExample -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16'

# Run in simulator
# Use Xcode or the mcp__XcodeBuildMCP tools
```

### Run Tests
The Swift Package has a test suite in `HelpView/Tests/HelpViewTests/`:
```bash
cd HelpViewExample/HelpView
swift test
```

Test files include:
- `ModelsTests.swift` - Data model tests
- `FAQLoaderTests.swift` - JSON/plist loading tests
- `AIHelperTests.swift` - AI helper functionality tests
- `FAQListViewModelTests.swift` - View model tests

### Clean Build
```bash
# Clean Xcode derived data
rm -rf build/

# Clean Swift Package build
cd HelpViewExample/HelpView
swift package clean
```

## FAQ Data Format

HelpView supports both JSON and plist formats. Files must be in the app bundle.

**Structure:**
```json
{
  "faqs": [
    {
      "id": "uuid-string",
      "title": "Question text",
      "details": "Answer with **Markdown** support",
      "topic": "Optional Topic Name"
    }
  ]
}
```

**Format Detection:** Loader tries `.json` first, then `.plist`. See `PLIST_SUPPORT.md` for plist-specific details.

## Key Technical Details

### Platform Requirements
- iOS 26+, macOS 26+
- Swift 6.2+
- Foundation Models framework (for AI features)

### Apple Intelligence Integration
- **Availability check**: `SystemLanguageModel.default.availability` returns `.available` on supported devices
- **Requirements**: A17 Pro/M1+ chip, Apple Intelligence enabled in Settings, language model downloaded
- **Privacy**: All processing is on-device, no network required
- **Fallback**: Automatically switches to text-based search when unavailable

### Important Implementation Notes
- `FAQ.id` is auto-generated via `init(from:)` custom decoder (never decoded from file)
- Empty strings in plist files are converted to `nil` for optional fields
- FAQs without a `topic` are grouped under "General"
- View uses `@Observable` macro (not `ObservableObject`)
- Markdown rendering via SwiftUI's `Text(.init(markdown))` initializer

## Project Structure

```
HelpViewExample/
├── HelpViewExample.xcodeproj/        # Main Xcode project
├── HelpViewExample/                  # Host app
│   ├── HelpViewExampleApp.swift
│   ├── ContentView.swift             # Demo integration
│   ├── app_help.json                 # Sample FAQ data
│   ├── app_help.plist               # Sample FAQ data (plist format)
│   └── HelpView/                     # Embedded Swift Package
│       ├── Package.swift
│       ├── Sources/HelpView/         # Framework source
│       └── Tests/HelpViewTests/      # Test suite
├── SETUP_INSTRUCTIONS.md             # Setup guide
├── AI_FEATURES.md                    # AI integration details
└── PLIST_SUPPORT.md                  # Plist format documentation
```

## Common Development Workflow

1. **Modify the framework**: Edit files in `HelpViewExample/HelpView/Sources/HelpView/`
2. **Test changes**: Run `swift test` in the `HelpView/` directory
3. **See changes in app**: Build and run the HelpViewExample scheme in Xcode
4. **Update FAQ data**: Modify `app_help.json` or `app_help.plist` in the app target

## Adding HelpView to Other Projects

HelpView provides two public APIs for integration:

### 1. Button with Sheet Presentation (Quick Integration)
Use `HelpView` for a ready-to-use question mark button that presents help in a sheet:

```swift
import HelpView

.toolbar {
    ToolbarItem(placement: .topBarTrailing) {
        HelpView(named: "app_help")  // Filename without extension
    }
}
```

### 2. Embeddable Content View (Custom Navigation)
Use `HelpContentView` to embed the help interface directly in your navigation hierarchy:

```swift
import HelpView

// Push from a list
NavigationLink("Help & Support") {
    HelpContentView(named: "app_help")
}

// Or use with custom buttons
Button("Get Help") {
    // Navigate to help view
}
.navigationDestination(isPresented: $showHelp) {
    HelpContentView(named: "app_help")
}

// Or embed directly in a TabView
TabView {
    ContentView()
        .tabItem { Label("Home", systemImage: "house") }

    HelpContentView(named: "app_help")
        .tabItem { Label("Help", systemImage: "questionmark.circle") }
}
```

**Note:** `HelpContentView` includes its own navigation title but not the "Done" button, giving you full control over navigation flow.

Ensure the FAQ JSON/plist file is added to the target's "Copy Bundle Resources" build phase.
