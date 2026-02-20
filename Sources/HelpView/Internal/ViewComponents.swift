import SwiftUI
#if os(iOS) || os(visionOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// MARK: - Markdown Renderer with Code Support
struct MarkdownTextView: View {
    let markdown: String
    @State private var parsedBlocks: [MarkdownBlock] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(parsedBlocks) { block in
                switch block.type {
                case .code:
                    CodeBlockView(code: block.content, language: block.language)
                case .text:
                    Text(.init(block.content))
                        .font(.body)
                        .foregroundStyle(.primary)
                        .textSelection(.enabled)
                }
            }
        }
        .onAppear {
            parsedBlocks = Self.parseMarkdown(markdown)
        }
        .onChange(of: markdown) { _, newValue in
            parsedBlocks = Self.parseMarkdown(newValue)
        }
    }

    private static func parseMarkdown(_ markdown: String) -> [MarkdownBlock] {
        var blocks: [MarkdownBlock] = []
        let lines = markdown.split(separator: "\n", omittingEmptySubsequences: false)
        var currentText = ""
        var currentCode = ""
        var inCodeBlock = false
        var codeLanguage: String?
        var blockId = 0

        for line in lines {
            let lineStr = String(line)

            // Check for code fence
            if lineStr.hasPrefix("```") {
                if inCodeBlock {
                    // End of code block
                    if !currentCode.isEmpty {
                        blocks.append(MarkdownBlock(
                            id: blockId,
                            type: .code,
                            content: currentCode.trimmingCharacters(in: .whitespacesAndNewlines),
                            language: codeLanguage
                        ))
                        blockId += 1
                        currentCode = ""
                        codeLanguage = nil
                    }
                    inCodeBlock = false
                } else {
                    // Start of code block
                    if !currentText.isEmpty {
                        blocks.append(MarkdownBlock(
                            id: blockId,
                            type: .text,
                            content: currentText.trimmingCharacters(in: .whitespacesAndNewlines)
                        ))
                        blockId += 1
                        currentText = ""
                    }
                    // Extract language hint
                    let language = lineStr.dropFirst(3).trimmingCharacters(in: .whitespaces)
                    codeLanguage = language.isEmpty ? nil : language
                    inCodeBlock = true
                }
            } else {
                if inCodeBlock {
                    currentCode += lineStr + "\n"
                } else {
                    currentText += lineStr + "\n"
                }
            }
        }

        // Add remaining text
        if !currentText.isEmpty {
            blocks.append(MarkdownBlock(
                id: blockId,
                type: .text,
                content: currentText.trimmingCharacters(in: .whitespacesAndNewlines)
            ))
            blockId += 1
        }

        // Handle unclosed code block
        if !currentCode.isEmpty {
            blocks.append(MarkdownBlock(
                id: blockId,
                type: .code,
                content: currentCode.trimmingCharacters(in: .whitespacesAndNewlines),
                language: codeLanguage
            ))
        }

        return blocks
    }
}

#if DEBUG
extension MarkdownTextView {
    /// Test-only access to the markdown parser
    static func testParseMarkdown(_ markdown: String) -> [MarkdownBlock] {
        parseMarkdown(markdown)
    }
}
#endif

struct MarkdownBlock: Identifiable {
    let id: Int
    let type: BlockType
    let content: String
    var language: String?

    enum BlockType {
        case text
        case code
    }
}

struct CodeBlockView: View {
    let code: String
    let language: String?
    @State private var showCopiedFeedback = false
    @State private var feedbackTask: Task<Void, Never>?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with language label and copy button
            HStack {
                if let lang = language, !lang.isEmpty {
                    Text(lang.uppercased())
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    copyToClipboard()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: showCopiedFeedback ? "checkmark" : "doc.on.doc")
                            .font(.caption)
                        Text(showCopiedFeedback ? "code.copied" : "code.copy", bundle: .module)
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(showCopiedFeedback ? .green : .secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("Copy code"))
                .animation(.easeInOut(duration: 0.2), value: showCopiedFeedback)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.secondary.opacity(0.1))

            ScrollView(.horizontal, showsIndicators: true) {
                SyntaxHighlightedText(code: code, language: language)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .padding(12)
            }
        }
        .background(Color.secondary.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1)
        )
        .onDisappear {
            feedbackTask?.cancel()
        }
    }

    private func copyToClipboard() {
        #if os(iOS) || os(visionOS)
        UIPasteboard.general.string = code
        showCopiedFeedback = true
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(code, forType: .string)
        showCopiedFeedback = true
        #endif

        // Reset feedback after 2 seconds
        feedbackTask?.cancel()
        feedbackTask = Task {
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            showCopiedFeedback = false
        }
    }
}

// MARK: - Syntax Highlighter
struct SyntaxHighlightedText: View {
    let code: String
    let language: String?
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Cached Regex Patterns
    private static let swiftKeywords = ["import", "func", "var", "let", "class", "struct", "enum", "protocol", "extension",
                   "if", "else", "switch", "case", "default", "for", "while", "repeat", "return",
                   "guard", "defer", "break", "continue", "fallthrough", "throw", "throws", "try",
                   "catch", "async", "await", "public", "private", "internal", "fileprivate",
                   "static", "final", "override", "mutating", "init", "deinit", "self", "Self",
                   "true", "false", "nil", "in", "where", "as", "is", "some", "any"]

    private static let swiftRegex: NSRegularExpression? = {
        let pattern = "(@\\w+|\"[^\"]*\"|//.*|/\\*[\\s\\S]*?\\*/|\\b\\d+\\.?\\d*\\b|\\b(?:" + swiftKeywords.joined(separator: "|") + ")\\b|\\w+)"
        return try? NSRegularExpression(pattern: pattern)
    }()

    private static let jsonRegex: NSRegularExpression? = {
        let pattern = "(\"[^\"]*\"\\s*:)|(:?\\s*\"[^\"]*\")|(:?\\s*\\b(?:true|false|null)\\b)|(:?\\s*-?\\d+\\.?\\d*)|([\\[\\]{},:}])"
        return try? NSRegularExpression(pattern: pattern)
    }()

    private static let xmlRegex: NSRegularExpression? = {
        let pattern = "(<!--[\\s\\S]*?-->)|(</?\\w+)|([\\w-]+)=|(\"[^\"]*\")|([/>])"
        return try? NSRegularExpression(pattern: pattern)
    }()

    private static let pythonKeywords = ["def", "class", "if", "else", "elif", "for", "while", "return", "import", "from",
                   "try", "except", "finally", "with", "as", "raise", "pass", "break", "continue",
                   "True", "False", "None", "and", "or", "not", "in", "is", "lambda", "yield",
                   "async", "await", "self"]

    private static let pythonRegex: NSRegularExpression? = {
        let pattern = "(#.*|\"\"\"[\\s\\S]*?\"\"\"|'''[\\s\\S]*?'''|\"[^\"]*\"|'[^']*'|\\b\\d+\\.?\\d*\\b|\\b(?:" + pythonKeywords.joined(separator: "|") + ")\\b|\\w+)"
        return try? NSRegularExpression(pattern: pattern)
    }()

    private static let jsKeywords = ["function", "const", "let", "var", "if", "else", "for", "while", "return",
                   "class", "extends", "import", "export", "from", "default", "async", "await",
                   "try", "catch", "finally", "throw", "new", "this", "true", "false", "null",
                   "undefined", "typeof", "instanceof", "break", "continue", "switch", "case"]

    private static let jsRegex: NSRegularExpression? = {
        let pattern = "(//.*|/\\*[\\s\\S]*?\\*/|\"[^\"]*\"|'[^']*'|`[^`]*`|\\b\\d+\\.?\\d*\\b|\\b(?:" + jsKeywords.joined(separator: "|") + ")\\b|\\w+)"
        return try? NSRegularExpression(pattern: pattern)
    }()

    private static let numberCheckRegex: NSRegularExpression? = {
        try? NSRegularExpression(pattern: "^\\d+\\.?\\d*$")
    }()

    var body: some View {
        Text(highlightedCode())
    }

    private func highlightedCode() -> AttributedString {
        let normalizedLang = language?.lowercased() ?? ""

        switch normalizedLang {
        case "swift":
            return highlightSwift(code)
        case "json":
            return highlightJSON(code)
        case "xml", "plist":
            return highlightXML(code)
        case "python", "py":
            return highlightPython(code)
        case "javascript", "js", "typescript", "ts":
            return highlightJavaScript(code)
        default:
            // No syntax highlighting
            var attributed = AttributedString(code)
            attributed.foregroundColor = .primary
            return attributed
        }
    }

    private func isNumber(_ string: String) -> Bool {
        guard let regex = Self.numberCheckRegex else { return false }
        return regex.firstMatch(in: string, range: NSRange(location: 0, length: (string as NSString).length)) != nil
    }

    // MARK: - Color Palette
    // Following principles from Craig Motlin's article on syntax highlighting colors
    // Using adaptive colors that work in both light and dark modes

    private var keywordColor: Color {
        // Keywords: Blue - classic and familiar
        colorScheme == .dark
            ? Color(red: 0.51, green: 0.69, blue: 1.0)      // #83B0FF - lighter, saturated blue
            : Color(red: 0.0, green: 0.2, blue: 0.7)        // #0033B3 - dark blue
    }

    private var stringColor: Color {
        // Strings: Green - traditional choice
        colorScheme == .dark
            ? Color(red: 0.42, green: 0.82, blue: 0.45)     // #6BD172 - bright green
            : Color(red: 0.0, green: 0.5, blue: 0.0)        // #008000 - forest green
    }

    private var commentColor: Color {
        // Comments: Gray/muted - less important
        colorScheme == .dark
            ? Color(red: 0.5, green: 0.6, blue: 0.5)        // #80997F - muted green-gray
            : Color(red: 0.42, green: 0.5, blue: 0.42)      // #6B806B - darker muted green
    }

    private var numberColor: Color {
        // Numbers: Light blue - distinct from keyword blue
        colorScheme == .dark
            ? Color(red: 0.65, green: 0.85, blue: 1.0)      // #A6D9FF - very light blue
            : Color(red: 0.09, green: 0.31, blue: 0.92)     // #1750EB - bright blue
    }

    private var attributeColor: Color {
        // Attributes/Annotations: Orange
        colorScheme == .dark
            ? Color(red: 1.0, green: 0.67, blue: 0.4)       // #FFAB66 - light orange
            : Color(red: 0.67, green: 0.4, blue: 0.0)       // #AA6600 - dark orange
    }

    private var typeColor: Color {
        // Types/Classes: Teal/Cyan
        colorScheme == .dark
            ? Color(red: 0.0, green: 1.0, blue: 1.0)        // #00FFFF - bright cyan
            : Color(red: 0.0, green: 0.67, blue: 0.67)      // #00AAAA - teal
    }

    private var propertyColor: Color {
        // Property names (JSON keys, XML attributes): Purple
        colorScheme == .dark
            ? Color(red: 0.78, green: 0.63, blue: 1.0)      // #C8A0FF - light purple
            : Color(red: 0.5, green: 0.0, blue: 0.67)       // #8000AA - dark purple
    }

    // MARK: - Common Highlight Helper

    /// Applies syntax highlighting using a regex and a colorizer closure.
    /// Applies syntax highlighting using a regex and a colorizer closure.
    /// - Parameters:
    ///   - regex: The compiled regex pattern for tokenizing. If nil, returns plain text.
    ///   - code: The source code string to highlight.
    ///   - unmatchedColor: Color for text between regex matches (default: `.primary`).
    ///   - colorizer: Closure that maps a matched token string to its color.
    private func highlightWithRegex(_ regex: NSRegularExpression?, code: String, unmatchedColor: Color = .primary, colorizer: (String) -> Color) -> AttributedString {
        guard let regex else {
            var attributed = AttributedString(code)
            attributed.foregroundColor = .primary
            return attributed
        }

        var result = AttributedString()
        let nsString = code as NSString
        let matches = regex.matches(in: code, range: NSRange(location: 0, length: nsString.length))
        var lastIndex = 0

        for match in matches {
            let matchRange = match.range
            let matchString = nsString.substring(with: matchRange)

            if lastIndex < matchRange.location {
                let beforeRange = NSRange(location: lastIndex, length: matchRange.location - lastIndex)
                var beforeText = AttributedString(nsString.substring(with: beforeRange))
                beforeText.foregroundColor = unmatchedColor
                result.append(beforeText)
            }

            var matchText = AttributedString(matchString)
            matchText.foregroundColor = colorizer(matchString)
            result.append(matchText)
            lastIndex = matchRange.location + matchRange.length
        }

        if lastIndex < nsString.length {
            let remainingRange = NSRange(location: lastIndex, length: nsString.length - lastIndex)
            var remainingText = AttributedString(nsString.substring(with: remainingRange))
            remainingText.foregroundColor = unmatchedColor
            result.append(remainingText)
        }

        return result
    }

    private static let jsonLiterals: Set<String> = ["true", "false", "null"]

    // MARK: - Language-Specific Highlighting

    private func highlightSwift(_ code: String) -> AttributedString {
        highlightWithRegex(Self.swiftRegex, code: code) { token in
            if token.hasPrefix("@") { return attributeColor }
            if token.hasPrefix("\"") { return stringColor }
            if token.hasPrefix("//") || token.hasPrefix("/*") { return commentColor }
            if isNumber(token) { return numberColor }
            if Self.swiftKeywords.contains(token) { return keywordColor }
            return .primary
        }
    }

    private func highlightJSON(_ code: String) -> AttributedString {
        highlightWithRegex(Self.jsonRegex, code: code, unmatchedColor: .secondary) { token in
            if token.contains(":") && token.hasPrefix("\"") { return propertyColor }
            if token.hasPrefix("\"") || (token.contains("\"") && token.contains(":")) { return stringColor }
            let trimmed = token.trimmingCharacters(in: .whitespaces)
            if Self.jsonLiterals.contains(trimmed) { return keywordColor }
            if isNumber(trimmed) { return numberColor }
            return .secondary
        }
    }

    private func highlightXML(_ code: String) -> AttributedString {
        highlightWithRegex(Self.xmlRegex, code: code) { token in
            if token.hasPrefix("<!--") { return commentColor }
            if token.hasPrefix("<") { return keywordColor }
            if token.hasSuffix("=") { return propertyColor }
            if token.hasPrefix("\"") { return stringColor }
            return .secondary
        }
    }

    private func highlightPython(_ code: String) -> AttributedString {
        highlightWithRegex(Self.pythonRegex, code: code) { token in
            if token.hasPrefix("#") { return commentColor }
            if token.hasPrefix("\"") || token.hasPrefix("'") { return stringColor }
            if isNumber(token) { return numberColor }
            if Self.pythonKeywords.contains(token) { return keywordColor }
            return .primary
        }
    }

    private func highlightJavaScript(_ code: String) -> AttributedString {
        highlightWithRegex(Self.jsRegex, code: code) { token in
            if token.hasPrefix("//") || token.hasPrefix("/*") { return commentColor }
            if token.hasPrefix("\"") || token.hasPrefix("'") || token.hasPrefix("`") { return stringColor }
            if isNumber(token) { return numberColor }
            if Self.jsKeywords.contains(token) { return keywordColor }
            return .primary
        }
    }
}

// MARK: - Internal Sheet Wrapper
/// Internal wrapper for sheet presentation (used by HelpView button)
struct FAQListView: View {
    let filename: String
    let bundle: Bundle
    let localization: String

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack(alignment: .topTrailing) {
                HelpContentView(named: filename, bundle: bundle, localization: localization)
                #if os(iOS) || os(visionOS)
                    .toolbar {
                        ToolbarItem(placement: .primaryAction) {
                            Button {
                                dismiss()
                            } label: {
                                Image(systemName: "xmark")
                            }
                            .accessibilityLabel(Text("Dismiss"))
                        }
                    }
                #endif
                #if os(macOS)
                Group {
                    if #available(macOS 26.0, *) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                        }
                        .padding()
                        .buttonBorderShape(.circle)
                        .buttonStyle(.glass)
                    } else {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                        }
                        .padding()
                        .buttonBorderShape(.circle)
                        .buttonStyle(.bordered)
                    }
                }
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
                Image(systemName: viewModel.isAppleIntelligenceAvailable ? "sparkles" : "magnifyingglass")
                    .foregroundStyle(.primary)
            }

            TextField(
                viewModel.isAppleIntelligenceAvailable
                    ? String(localized: "search.placeholder.ai", defaultValue: "Ask a question...", bundle: .module)
                    : String(localized: "search.placeholder.text", defaultValue: "Search...", bundle: .module),
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
            #if os(iOS) || os(visionOS)
            if !viewModel.searchQuery.isEmpty {
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

                        Text("ai.thinking", bundle: .module)
                            .font(.body)
                            .foregroundStyle(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    // AI Answer
                    VStack(alignment: .leading, spacing: 8) {
                        MarkdownTextView(markdown: viewModel.aiResponse)
                    }

                    // Related FAQs
                    if !viewModel.relatedFAQs.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("ai.relatedQuestions", bundle: .module)
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
                        Label {
                            Text("browse.allFAQs", bundle: .module)
                        } icon: {
                            Image(systemName: "list.bullet")
                        }
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
                    Image(systemName: viewModel.isFAQExpanded(faq.id) ? "chevron.up" : "chevron.down")
                        .foregroundStyle(.primary)
                        .imageScale(.small)
                    Text(faq.title)
                        .font(.body.weight(.bold))
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                }
                .padding()
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(viewModel.isFAQExpanded(faq.id) ? "Collapse \(faq.title)" : "Expand \(faq.title)"))

            if viewModel.isFAQExpanded(faq.id) {
                MarkdownTextView(markdown: faq.details)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.bottom)
            }

            Divider()
                .padding(.leading)
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
                    Image(systemName: viewModel.isFAQExpanded(faq.id) ? "chevron.up" : "chevron.down")
                        .foregroundStyle(.primary)
                        .imageScale(.small)
                    Text(faq.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                }
                .padding()
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(viewModel.isFAQExpanded(faq.id) ? "Collapse \(faq.title)" : "Expand \(faq.title)"))

            if viewModel.isFAQExpanded(faq.id) {
                MarkdownTextView(markdown: faq.details)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.bottom)
            }

            Divider()
                .padding(.leading)
        }
    }
}
