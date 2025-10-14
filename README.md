# HelpView

A SwiftUI framework for adding AI-powered FAQ documentation to iOS and macOS apps using Apple Intelligence.

## Overview

HelpView provides an easy-to-integrate help system that leverages Apple's Foundation Models (Apple Intelligence) to provide intelligent, context-aware answers to user questions. When Apple Intelligence is unavailable, it automatically falls back to traditional text-based search.

## Features

- 🤖 **AI-Powered Search**: Uses Apple Intelligence to understand natural language queries
- 📱 **SwiftUI Native**: Built entirely in SwiftUI for modern iOS/macOS apps
- 🔄 **Automatic Fallback**: Gracefully degrades to text search when AI is unavailable
- 📝 **Markdown Support**: Rich text formatting in FAQ answers
- 🎨 **Customizable**: Two integration options for different use cases
- 📦 **Zero Dependencies**: Pure Swift Package with no external dependencies

## Requirements

- iOS 17+ / macOS 15+
- Swift 6.2+
- Xcode 16+
- Apple Intelligence (optional, for AI features - requires iOS 26+/macOS 26+ and compatible hardware)

## Installation

### Swift Package Manager

Add HelpView to your project via Xcode:

1. In Xcode, select **File → Add Package Dependencies...**
2. Enter the repository URL: `https://github.com/yourusername/HelpView`
3. Select the version or branch
4. Add to your target

Or add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/HelpView", from: "1.0.0")
]
```

## Quick Start

### 1. Create Your FAQ Data

Create a JSON file (e.g., `app_help.json`) and add it to your app bundle:

```json
{
  "faqs": [
    {
      "title": "How do I get started?",
      "details": "Welcome! To get started, simply **tap** the button below...",
      "topic": "Getting Started"
    },
    {
      "title": "How do I export my data?",
      "details": "You can export your data by going to **Settings → Export**...",
      "topic": "Data Management"
    }
  ]
}
```

### 2. Integrate HelpView

HelpView provides two public APIs for different integration needs:

**Option A: `HelpViewButton` - Button with Sheet Presentation** (Quickest)

Use when you want a ready-to-use help button that presents FAQs in a modal sheet:

```swift
import SwiftUI
import HelpView

struct ContentView: View {
    var body: some View {
        NavigationStack {
            Text("Your app content")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        HelpViewButton(named: "app_help")
                    }
                }
        }
    }
}
```

**Option B: `HelpContentView` - Embeddable Content View** (More Control)

Use when you want to embed help content directly in your navigation hierarchy:

```swift
import SwiftUI
import HelpView

struct ContentView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink("Help & Support") {
                    HelpContentView(named: "app_help")
                }
            }
        }
    }
}
```

**Option B - Alternative Uses:**

```swift
// In a TabView
TabView {
    ContentView()
        .tabItem { Label("Home", systemImage: "house") }

    HelpContentView(named: "app_help")
        .tabItem { Label("Help", systemImage: "questionmark.circle") }
}

// With programmatic navigation
NavigationStack {
    Button("Get Help") {
        showHelp = true
    }
    .navigationDestination(isPresented: $showHelp) {
        HelpContentView(named: "app_help")
    }
}
```

### 3. Run Your App

That's it! HelpView will automatically:
- Detect if Apple Intelligence is available
- Provide AI-powered answers when possible
- Fall back to text search otherwise

## API Reference

### `HelpViewButton`

A ready-to-use help button that presents FAQ documentation in a sheet.

```swift
public struct HelpViewButton: View {
    public init(named filename: String)
}
```

**Features:**
- Displays a question mark button
- Automatically presents help in a modal sheet
- Includes a "Done" button for dismissal
- Perfect for toolbar placement

**When to use:** Quick integration, toolbar buttons, or when you want modal presentation.

### `HelpContentView`

An embeddable help content view for custom navigation flows.

```swift
public struct HelpContentView: View {
    public init(named filename: String)
}
```

**Features:**
- No modal presentation wrapper
- Includes navigation title but no "Done" button
- Full control over navigation flow
- Can be embedded anywhere in your view hierarchy

**When to use:** Custom navigation flows, tab bars, NavigationLinks, or when you need more control over presentation.

## Documentation

- [Setup Instructions](SETUP_INSTRUCTIONS.md) - Detailed integration guide
- [AI Features](AI_FEATURES.md) - How Apple Intelligence integration works
- [Plist Support](PLIST_SUPPORT.md) - Using plist format for FAQ data

## Example App

The `Example/` directory contains a complete demo app showing both integration methods. To run it:

```bash
# Open the example project
cd Example
open HelpViewExample.xcodeproj
```

Then build and run the `HelpViewExample` scheme.

## FAQ Data Format

### JSON Format (Recommended)

```json
{
  "faqs": [
    {
      "title": "Question text",
      "details": "Answer with **Markdown** support",
      "topic": "Optional Category Name"
    }
  ]
}
```

### Plist Format

See [PLIST_SUPPORT.md](PLIST_SUPPORT.md) for details on using plist files.

### Important Notes

- The `id` field is auto-generated; don't include it in your JSON/plist
- FAQs without a `topic` are grouped under "General"
- Markdown is fully supported in the `details` field
- File must be added to your app target's "Copy Bundle Resources"

## How It Works

HelpView uses Apple's Foundation Models framework to provide intelligent responses:

1. **Availability Check**: Detects if Apple Intelligence is available on the device
2. **Context Loading**: Loads all FAQ data and provides it as context to the AI
3. **Natural Language Processing**: Understands user questions in natural language
4. **Structured Responses**: Returns typed responses with relevant FAQ suggestions
5. **Privacy First**: All processing happens on-device, no network required

When Apple Intelligence is unavailable, HelpView falls back to text-based search across FAQ titles and content.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
