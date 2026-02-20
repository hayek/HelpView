import Foundation
import os
#if canImport(FoundationModels)
import FoundationModels
#endif

/// Errors thrown by AIHelper operations
enum AIHelperError: LocalizedError {
    case aiUnavailable
    case sessionNotInitialized
    case generationFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .aiUnavailable:
            return "Apple Intelligence is not available"
        case .sessionNotInitialized:
            return "Session not initialized. Call configure(with:) first."
        case .generationFailed(let underlying):
            return "Failed to generate response: \(underlying.localizedDescription)"
        }
    }
}

@MainActor
@Observable
class AIHelper {
    private static let logger = Logger(subsystem: "com.helpview", category: "AIHelper")

    var isAppleIntelligenceAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, *) {
            if case .available = SystemLanguageModel.default.availability {
                return true
            }
        }
        #endif
        return false
    }

    private var faqs: [FAQ] = []
    // Cached system prompt for creating fresh sessions per query.
    // Stored as Any? to avoid @available issues with @Observable macro.
    private var _systemPrompt: String?

    func configure(with faqs: [FAQ]) {
        self.faqs = faqs

        guard isAppleIntelligenceAvailable else { return }

        let faqContext = faqs.map { "Q: \($0.title)\nA: \($0.details)" }.joined(separator: "\n\n")

        _systemPrompt = """
        You are a strict FAQ assistant. You may ONLY answer questions using the FAQ information provided below.

        CRITICAL RULES:
        - ONLY use information from the FAQs below
        - If the question is not related to any FAQ topic, respond with: "I can only answer questions about the topics covered in our FAQs."
        - Do NOT use any external knowledge
        - Do NOT answer general knowledge questions
        - Do NOT make up information
        - Always include 2-4 related FAQ questions the user might find helpful

        Available FAQ Topics and Questions:
        \(faqContext)

        Remember: You must REFUSE to answer anything not covered in the FAQs above.
        """
    }

    /// Generates AI response using Apple's Foundation Models.
    /// Creates a fresh session per query to prevent conversation history accumulation.
    func generateResponse(for userQuery: String) async throws -> (answer: String, relatedFAQs: [FAQ]) {
        guard isAppleIntelligenceAvailable else {
            throw AIHelperError.aiUnavailable
        }

        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, *) {
            guard let systemPrompt = _systemPrompt else {
                assertionFailure("AIHelper._systemPrompt is nil. Call configure(with:) first.")
                throw AIHelperError.sessionNotInitialized
            }

            // Create a fresh session per query to avoid conversation history
            // accumulating and degrading response quality over time.
            let session = LanguageModelSession {
                systemPrompt
            }

            do {
                let response = try await session.respond(
                    to: userQuery,
                    generating: HelpResponse.self
                )

                // Find the actual FAQ objects that match the related titles
                let relatedFAQs = response.content.relatedFAQs.compactMap { relatedTitle in
                    faqs.first { faq in
                        faq.title.lowercased().contains(relatedTitle.lowercased()) ||
                        relatedTitle.lowercased().contains(faq.title.lowercased())
                    }
                }

                return (response.content.answer, relatedFAQs)
            } catch let error as AIHelperError {
                throw error
            } catch {
                throw AIHelperError.generationFailed(underlying: error)
            }
        }
        #endif

        throw AIHelperError.aiUnavailable
    }

    /// Performs text-based search when AI is not available
    func searchFAQs(query: String) -> [FAQ] {
        guard !query.isEmpty else { return faqs }

        let searchTerms = query.lowercased().split(separator: " ").map(String.init)
            .filter { $0.count >= 2 } // Skip single-character terms to reduce noise

        guard !searchTerms.isEmpty else { return faqs }

        let scored = faqs.map { faq -> (faq: FAQ, score: Int) in
            let searchableText = (faq.title + " " + faq.details).lowercased()
            let score = searchTerms.reduce(0) { total, term in
                var count = 0
                var searchRange = searchableText.startIndex..<searchableText.endIndex
                while let range = searchableText.range(of: term, range: searchRange) {
                    count += 1
                    searchRange = range.upperBound..<searchableText.endIndex
                }
                return total + count
            }
            return (faq, score)
        }

        return scored
            .filter { $0.score > 0 }
            .sorted { $0.score > $1.score }
            .map { $0.faq }
    }
}
