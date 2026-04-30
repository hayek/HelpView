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
    private let filename: String
    private let bundle: Bundle
    private let localization: String

    /// Creates an embeddable help content view for custom navigation flows.
    ///
    /// This initializer creates a view that displays FAQ content with search capabilities.
    /// The view includes its own navigation title but no dismissal button, making it
    /// suitable for integration into navigation stacks, tab bars, or other custom layouts.
    ///
    /// - Parameters:
    ///   - named: The name of the FAQ file (without extension) in the bundle.
    ///     Supports both `.json` and `.plist` formats. The loader tries JSON first,
    ///     then falls back to plist if JSON is not found.
    ///   - bundle: The bundle containing the FAQ file. Defaults to `.main`.
    ///     Use this when the FAQ file is in an app extension or framework bundle.
    ///   - localization: The name of the `.xcstrings` file for translations (without extension).
    ///     Defaults to `"Localizable"`. Use this to specify a custom string catalog for FAQ translations.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Using default Localizable.xcstrings
    /// HelpContentView(named: "app_help")
    ///
    /// // Using a custom HelpStrings.xcstrings file
    /// HelpContentView(named: "app_help", localization: "HelpStrings")
    ///
    /// // Specifying a custom bundle (e.g., for app extensions)
    /// HelpContentView(named: "app_help", bundle: .myExtensionBundle)
    /// ```
    ///
    /// ## Notes
    ///
    /// - The view automatically loads FAQ data when it appears
    /// - Search field placement adapts to the platform (toolbar on iOS, bottom on macOS)
    /// - AI features activate automatically when Apple Intelligence is available
    public init(named filename: String, bundle: Bundle = .main, localization: String = "Localizable") {
        self.filename = filename
        self.bundle = bundle
        self.localization = localization
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            backgroundColor.ignoresSafeArea()

            Group {
                if !viewModel.aiResponse.isEmpty {
                    AIResponseView(viewModel: viewModel)
                } else {
                    FAQListScrollView(viewModel: viewModel)
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Color.clear.frame(height: 72)
            }

            SearchField(viewModel: viewModel)
                .shadow(color: .black.opacity(0.18), radius: 18, x: 0, y: 6)
                .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 1)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
        }
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .onAppear {
            let (faqs, topicOrder) = FAQLoader.load(named: filename, bundle: bundle, localization: localization)
            viewModel.configure(with: faqs, topicOrder: topicOrder, localization: localization)
        }
    }

    private var backgroundColor: Color {
        #if os(iOS) || os(visionOS)
        Color(.systemGroupedBackground)
        #else
        Color(nsColor: .windowBackgroundColor)
        #endif
    }
}
