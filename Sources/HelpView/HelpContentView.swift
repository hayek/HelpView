import SwiftUI

/// An embeddable help content view for custom navigation flows.
///
/// `HelpContentView` provides the help interface without any presentation wrapper,
/// allowing you to integrate it seamlessly into your app's navigation hierarchy.
/// Unlike ``HelpViewButton``, this view doesn't include a "Done" button, giving you
/// full control over navigation.
///
/// ## Features
///
/// - **AI-Powered Search**: Natural language queries using Apple Intelligence
/// - **Text-Based Fallback**: Works even when Apple Intelligence is unavailable
/// - **Markdown Support**: Rich text formatting in FAQ answers
/// - **Topic Organization**: Browse FAQs grouped by topics
/// - **Platform Adaptive**: Optimized UI for both iOS and macOS
/// - **No Modal Presentation**: Integrates directly into your navigation stack
///
/// ## Usage
///
/// ### Push Navigation
///
/// Embed in a NavigationLink for push-based navigation:
///
/// ```swift
/// import HelpView
///
/// NavigationView {
///     List {
///         NavigationLink("Help & Support") {
///             HelpContentView(named: "app_help")
///         }
///     }
/// }
/// ```
///
/// ### Custom Navigation
///
/// Use with programmatic navigation:
///
/// ```swift
/// struct ContentView: View {
///     @State private var showHelp = false
///
///     var body: some View {
///         NavigationStack {
///             Button("Get Help") {
///                 showHelp = true
///             }
///             .navigationDestination(isPresented: $showHelp) {
///                 HelpContentView(named: "app_help")
///             }
///         }
///     }
/// }
/// ```
///
/// ### Tab Bar Integration
///
/// Add as a dedicated help tab:
///
/// ```swift
/// TabView {
///     ContentView()
///         .tabItem { Label("Home", systemImage: "house") }
///
///     HelpContentView(named: "app_help")
///         .tabItem { Label("Help", systemImage: "questionmark.circle") }
/// }
/// ```
///
/// ## FAQ File Format
///
/// Create a JSON or plist file in your app bundle:
///
/// **JSON Format:**
/// ```json
/// {
///   "topics": ["Getting Started", "Features"],
///   "faqs": [
///     {
///       "title": "How do I use this feature?",
///       "details": "Here's how to use this feature...",
///       "topic": "Features"
///     }
///   ]
/// }
/// ```
///
/// **Plist Format:**
/// ```xml
/// <dict>
///   <key>topics</key>
///   <array>
///     <string>Getting Started</string>
///   </array>
///   <key>faqs</key>
///   <array>
///     <dict>
///       <key>title</key>
///       <string>How do I use this feature?</string>
///       <key>details</key>
///       <string>Here's how to use this feature...</string>
///       <key>topic</key>
///       <string>Getting Started</string>
///     </dict>
///   </array>
/// </dict>
/// ```
///
/// **Build Phase Setup:**
/// Ensure your FAQ file is added to the target's "Copy Bundle Resources" build phase.
///
/// ## Platform Requirements
///
/// - iOS 26.0+ or macOS 26.0+
/// - Apple Intelligence features require A17 Pro/M1+ chip with Apple Intelligence enabled
///
/// ## See Also
///
/// - ``HelpViewButton`` - For a ready-to-use button with modal sheet presentation
public struct HelpContentView: View {
    @State private var viewModel = FAQListViewModel()
    let filename: String

    /// Creates an embeddable help content view for custom navigation flows.
    ///
    /// This initializer creates a view that displays FAQ content with search capabilities.
    /// The view includes its own navigation title but no dismissal button, making it
    /// suitable for integration into navigation stacks, tab bars, or other custom layouts.
    ///
    /// - Parameter named: The name of the FAQ file (without extension) in the bundle.
    ///   Supports both `.json` and `.plist` formats. The loader tries JSON first,
    ///   then falls back to plist if JSON is not found.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // For a file named "app_help.json" or "app_help.plist"
    /// HelpContentView(named: "app_help")
    /// ```
    ///
    /// ## Notes
    ///
    /// - The view automatically loads FAQ data when it appears
    /// - Search field placement adapts to the platform (toolbar on iOS, bottom on macOS)
    /// - AI features activate automatically when Apple Intelligence is available
    public init(named filename: String) {
        self.filename = filename
    }

    public var body: some View {
        #if os(iOS)
        VStack(spacing: 0) {
            // AI Response or FAQ List
            if !viewModel.aiResponse.isEmpty {
                AIResponseView(viewModel: viewModel)
            } else {
                FAQListScrollView(viewModel: viewModel)
            }
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                SearchField(viewModel: viewModel)
            }
            if #available(iOS 26.0, macOS 26.0, *) {
                ToolbarSpacer()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            let (faqs, topicOrder) = FAQLoader.load(named: filename)
            viewModel.configure(with: faqs, topicOrder: topicOrder)
        }
        #else
        VStack(spacing: 0) {
            // AI Response or FAQ List
            if !viewModel.aiResponse.isEmpty {
                AIResponseView(viewModel: viewModel)
            } else {
                FAQListScrollView(viewModel: viewModel)
            }

            // Search field at bottom for macOS
            Divider()
            SearchField(viewModel: viewModel)
                .padding()
        }
        .onAppear {
            let (faqs, topicOrder) = FAQLoader.load(named: filename)
            viewModel.configure(with: faqs, topicOrder: topicOrder)
        }
        #endif
    }
}
