import SwiftUI

/// The main HelpView that displays a question mark button
/// Tapping the button presents an FAQ view with AI-powered assistance
public struct HelpViewButton: View {
    private let filename: String
    @State private var showingHelp = false

    /// Creates a help button that presents FAQs in a sheet
    /// - Parameter named: The name of the FAQ file (without extension) in the bundle. Supports both JSON and plist formats.
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
