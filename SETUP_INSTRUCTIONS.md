# HelpView Setup Instructions

## ✅ What's Been Created

The HelpView SPM framework has been successfully created with the following components:

### Framework Structure (`HelpView/`)
- **HelpView.swift** - Main public API with question mark button
- **Models.swift** - FAQ and Topic data models with @Generable macro
- **FAQLoader.swift** - JSON parsing logic
- **FAQListView.swift** - Collapsible FAQ list with search/AI interface
- **AIHelper.swift** - AI chatbot with Foundation Models and search fallback
- **Package.swift** - SPM configuration
- **README.md** - Complete documentation

### Example App
- **ContentView.swift** - Demo showing HelpView integration
- **app_help.json** - Sample FAQ data with 10 questions across 5 topics

## 🔧 Final Setup Step

**IMPORTANT**: Add the JSON file to your Xcode project:

1. In Xcode (already open), select the `HelpViewExample` group in the Project Navigator
2. Right-click and choose "Add Files to 'HelpViewExample'..."
3. Navigate to and select: `HelpViewExample/app_help.json`
4. Make sure "Copy items if needed" is **unchecked** (file is already in place)
5. Make sure the file is added to the `HelpViewExample` target
6. Click "Add"

## 🚀 Running the Example

Once the JSON is added:
1. Select the HelpViewExample scheme
2. Choose a simulator (iPhone or iPad)
3. Press Cmd+R to build and run

## 📱 How It Works

1. **Question Mark Button**: Top-right of the navigation bar
2. **AI/Search**: Uses Apple Intelligence when available, smart search otherwise
3. **Collapsible FAQs**: Tap any question to expand/collapse the answer
4. **Topics**: FAQs are organized by topic (Getting Started, Account Management, etc.)
5. **Markdown**: Answers support full Markdown formatting

## 🔮 iOS 26 Foundation Models - ENABLED ✅

The framework is **fully configured** with Apple's Foundation Models:

### AI Features Active:
- ✅ `FoundationModels` framework integrated
- ✅ `@Generable` macro for structured responses
- ✅ `SystemLanguageModel` availability checking
- ✅ `LanguageModelSession` for AI responses
- ✅ Automatic fallback to search when unavailable

**On Devices with Apple Intelligence:**
- Shows sparkles icon (✨)
- Ask questions in natural language
- AI answers based on FAQ context

**On Other Devices:**
- Shows search icon (🔍)
- Smart text-based search

## 📝 API Usage

```swift
import HelpView

// In your SwiftUI view:
.toolbar {
    ToolbarItem(placement: .topBarTrailing) {
        HelpView(named: "app_help")
    }
}
```

That's it! Just pass the JSON filename (without extension).

## 📦 Package Details

- **Platforms**: iOS 26+, macOS 26+
- **Swift**: 6.2+
- **Dependencies**: None (uses native SwiftUI markdown)
- **Cross-platform**: Works on iPhone, iPad, and Mac

## 🎨 Design Features

- ✨ Modern Apple design language
- 🎯 Simple, clean interface
- 📱 Adaptive for all devices
- ♿️ Accessibility support
- 🌓 Supports Light & Dark mode

## 🧪 Testing the Features

Try these searches in the app:
- "password" - finds password reset FAQ
- "offline" - finds offline mode FAQ
- "dark mode" - finds appearance settings
- "secure" or "privacy" - finds security info
- "export" - finds data export instructions

All searches rank results by keyword frequency.

---

**Next Steps**: Add the JSON file to Xcode (step above), then run the app!
