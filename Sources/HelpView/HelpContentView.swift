import SwiftUI

/// A view that displays the FAQ content with AI-powered search
/// This view can be embedded directly in your app's navigation hierarchy
public struct HelpContentView: View {
    @State private var viewModel = FAQListViewModel()
    let filename: String

    /// Creates a help content view for embedding in your own navigation flow
    /// - Parameter named: The name of the FAQ file (without extension) in the bundle. Supports both JSON and plist formats.
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
            let loadedFAQs = FAQLoader.load(named: filename)
            viewModel.configure(with: loadedFAQs)
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
            let loadedFAQs = FAQLoader.load(named: filename)
            viewModel.configure(with: loadedFAQs)
        }
        #endif
    }
}
