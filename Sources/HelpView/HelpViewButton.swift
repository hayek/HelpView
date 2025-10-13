import SwiftUI

/// A ready-to-use help button that presents FAQ documentation in a sheet.
///
/// `HelpViewButton` provides the quickest way to add help documentation to your app.
/// It displays a question mark button that, when tapped, presents a full-screen sheet
/// with AI-powered FAQ search and browsing capabilities.
///
/// ## Features
///
/// - **AI-Powered Search**: Automatically uses Apple Intelligence when available for natural language queries
/// - **Fallback Search**: Text-based search when Apple Intelligence is unavailable
/// - **Sheet Presentation**: Handles presentation and dismissal automatically
/// - **Markdown Support**: FAQ answers support full markdown formatting
/// - **Topic Organization**: FAQs are grouped by topics for easy browsing
///
/// ## Usage
///
/// Add the button to a toolbar or anywhere in your view hierarchy:
///
/// ```swift
/// import HelpView
///
/// struct ContentView: View {
///     var body: some View {
///         NavigationView {
///             Text("Your app content")
///                 .toolbar {
///                     ToolbarItem(placement: .topBarTrailing) {
///                         HelpViewButton(named: "app_help")
///                     }
///                 }
///         }
///     }
/// }
/// ```
///
/// ## FAQ File Format
///
/// Create a JSON or plist file in your app bundle with this structure:
///
/// **JSON Format:**
/// ```json
/// {
///   "topics": ["Getting Started", "Features"],
///   "faqs": [
///     {
///       "title": "How do I get started?",
///       "details": "Getting started is easy! Just follow these steps...",
///       "topic": "Getting Started"
///     }
///   ]
/// }
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
/// - ``HelpContentView`` - For embedding help content in custom navigation flows
public struct HelpViewButton: View {
    private let filename: String
    @State private var showingHelp = false

    /// Creates a help button that presents FAQs in a modal sheet.
    ///
    /// The button displays a question mark icon and automatically handles
    /// presentation of the help interface when tapped.
    ///
    /// - Parameter named: The name of the FAQ file (without extension) in the bundle.
    ///   Supports both `.json` and `.plist` formats. The loader tries JSON first,
    ///   then falls back to plist.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // For a file named "app_help.json" or "app_help.plist"
    /// HelpViewButton(named: "app_help")
    /// ```
    public init(named filename: String) {
        self.filename = filename
    }

    public var body: some View {
        Button {
            showingHelp = true
        } label: {
            Image(systemName: "questionmark.circle")
                .imageScale(.large)
        }
        .accessibilityLabel("Help")
        .sheet(isPresented: $showingHelp) {
            FAQListView(filename: filename)
        }
    }
}
