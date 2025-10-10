import SwiftUI

// MARK: - Internal Sheet Wrapper
/// Internal wrapper for sheet presentation (used by HelpView button)
struct FAQListView: View {
    let filename: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack(alignment: .topTrailing) {
                HelpContentView(named: filename)
                #if os(iOS)
                    .toolbar {
                        ToolbarItem(placement: .primaryAction) {
                            Button {
                                dismiss()
                            } label: {
                                Image(systemName: "xmark")
                            }
                        }
                    }
                #endif
                #if os(macOS)
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                }
                .padding()
                .buttonBorderShape(.circle)
                .buttonStyle(.glass)
                #endif
            }
        }
    }
}

// MARK: - Search Field Component
struct SearchField: View {
    @Bindable var viewModel: FAQListViewModel

    var body: some View {
        HStack {
            if viewModel.isLoadingAI {
                AppleIntelligenceMiniLoader()
            } else {
                Image(systemName: viewModel.aiHelper.isAppleIntelligenceAvailable ? "sparkles" : "magnifyingglass")
                    .foregroundStyle(.primary)
            }

            TextField(
                viewModel.aiHelper.isAppleIntelligenceAvailable ? "Ask a question..." : "Search...",
                text: $viewModel.searchQuery
            )
            .textFieldStyle(.plain)
            .submitLabel(.search)
            .disabled(viewModel.isLoadingAI)
            .onSubmit {
                Task {
                    await viewModel.performSearch()
                }
            }
            #if os(iOS)
            if !viewModel.searchQuery.isEmpty   {
                Button {
                    viewModel.clearSearch()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isLoadingAI)
            }
            #endif
        }
        .frame(maxWidth: .infinity)
        .padding(2.0)
    }
}

// MARK: - AI Response View
struct AIResponseView: View {
    @Bindable var viewModel: FAQListViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if viewModel.isLoadingAI {
                    VStack(spacing: 20) {
                        AppleIntelligenceLoader()

                        Text("Thinking...")
                            .font(.body)
                            .foregroundStyle(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    // AI Answer
                    VStack(alignment: .leading, spacing: 8) {
                        Text(viewModel.aiResponse)
                            .font(.body)
                            .foregroundStyle(.primary)
                    }

                    // Related FAQs
                    if !viewModel.relatedFAQs.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Related Questions")
                                .font(.body.weight(.bold))
                                .foregroundStyle(.primary)
                                .padding(.top, 8)

                            ForEach(viewModel.relatedFAQs) { faq in
                                RelatedFAQCard(faq: faq, viewModel: viewModel)
                            }
                        }
                        .padding(.top, 8)
                    }

                    Button {
                        viewModel.clearSearch()
                    } label: {
                        Label("Browse All FAQs", systemImage: "list.bullet")
                    }
                    .buttonStyle(.bordered)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
    }
}

// MARK: - Related FAQ Card
struct RelatedFAQCard: View {
    let faq: FAQ
    @Bindable var viewModel: FAQListViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.snappy) {
                    viewModel.toggleFAQ(faq.id)
                }
            } label: {
                HStack {
                    Text(faq.title)
                        .font(.body.weight(.bold))
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Image(systemName: viewModel.isFAQExpanded(faq.id) ? "chevron.up" : "chevron.down")
                        .foregroundStyle(.primary)
                        .imageScale(.small)
                }
                .padding()
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if viewModel.isFAQExpanded(faq.id) {
                Text(.init(faq.details))
                    .font(.body)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
                    .padding(.horizontal)
                    .padding(.bottom)
            }

            Divider()
        }
    }
}

// MARK: - FAQ List Scroll View
struct FAQListScrollView: View {
    @Bindable var viewModel: FAQListViewModel

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(viewModel.filteredTopics) { topic in
                    TopicSection(topic: topic, viewModel: viewModel)
                }
            }
        }
    }
}

// MARK: - Topic Section
struct TopicSection: View {
    let topic: Topic
    @Bindable var viewModel: FAQListViewModel

    var body: some View {
        Section {
            ForEach(topic.faqs) { faq in
                FAQRow(faq: faq, viewModel: viewModel)
            }
        } header: {
            Text(topic.title)
                .font(.title2)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top, 20)
                .padding(.bottom, 8)
        }
    }
}

// MARK: - FAQ Row
struct FAQRow: View {
    let faq: FAQ
    @Bindable var viewModel: FAQListViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.snappy) {
                    viewModel.toggleFAQ(faq.id)
                }
            } label: {
                HStack {
                    Text(faq.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Image(systemName: viewModel.isFAQExpanded(faq.id) ? "chevron.up" : "chevron.down")
                        .foregroundStyle(.primary)
                        .imageScale(.small)
                }
                .padding()
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if viewModel.isFAQExpanded(faq.id) {
                Text(.init(faq.details))
                    .font(.body)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
                    .padding(.horizontal)
                    .padding(.bottom)
            }

            Divider()
                .padding(.leading)
        }
    }
}
