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

    /// Maximum number of full FAQ Q+A entries to include in the prompt per query.
    /// Apple's on-device SystemLanguageModel has a ~4096-token context window,
    /// so we retrieve only the most relevant FAQs instead of stuffing all of them.
    private static let maxRelevantFAQs = 6

    /// Hard cap on `details` characters per included FAQ — protects against a single
    /// pathologically long FAQ blowing the context window.
    private static let maxDetailsCharacters = 1200

    func configure(with faqs: [FAQ]) {
        self.faqs = faqs
    }

    /// Builds a per-query system prompt containing only the FAQs most relevant
    /// to the user's query, plus the titles of all FAQs so the model can still
    /// suggest related entries from the full set.
    private func buildSystemPrompt(for userQuery: String) -> String {
        let relevant = Array(searchFAQs(query: userQuery).prefix(Self.maxRelevantFAQs))

        let faqContext = relevant.map { faq in
            let trimmed = faq.details.count > Self.maxDetailsCharacters
                ? String(faq.details.prefix(Self.maxDetailsCharacters)) + "…"
                : faq.details
            return "Q: \(faq.title)\nA: \(trimmed)"
        }.joined(separator: "\n\n")

        let allTitles = faqs.map { "- \($0.title)" }.joined(separator: "\n")

        return """
        You are a strict FAQ assistant. You may ONLY answer questions using the FAQ information provided below.

        CRITICAL RULES:
        - ONLY use information from the FAQs below
        - If the question is not related to any FAQ topic, respond with: "I can only answer questions about the topics covered in our FAQs."
        - Do NOT use any external knowledge
        - Do NOT answer general knowledge questions
        - Do NOT make up information
        - Always include 2-4 related FAQ questions the user might find helpful, drawn from the full title list

        Most relevant FAQs (use these to answer):
        \(faqContext)

        All available FAQ titles (use these for the related suggestions field):
        \(allTitles)

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
            guard !faqs.isEmpty else {
                assertionFailure("AIHelper.faqs is empty. Call configure(with:) first.")
                throw AIHelperError.sessionNotInitialized
            }

            let systemPrompt = buildSystemPrompt(for: userQuery)

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

    /// English stop words filtered out of queries before scoring.
    /// Without this, words like "how" / "do" / "make" dominate scores on
    /// short questions and bury the FAQ that actually answers the question.
    private static let stopWords: Set<String> = [
        "a", "an", "and", "are", "as", "at", "be", "by", "can", "do", "does",
        "for", "from", "how", "i", "if", "in", "is", "it", "its", "make",
        "me", "my", "of", "on", "or", "should", "the", "to", "want", "was",
        "what", "when", "where", "which", "who", "why", "will", "with",
        "you", "your"
    ]

    private static func tokenize(_ query: String) -> [String] {
        query.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count >= 2 && !stopWords.contains($0) }
    }

    /// Performs text-based search when AI is not available.
    /// Title matches are weighted ~3x detail matches so the FAQ whose
    /// question best matches the query rises to the top.
    func searchFAQs(query: String) -> [FAQ] {
        guard !query.isEmpty else { return faqs }

        let searchTerms = Self.tokenize(query)
        guard !searchTerms.isEmpty else { return faqs }

        let scored = faqs.map { faq -> (faq: FAQ, score: Int) in
            let title = faq.title.lowercased()
            let details = faq.details.lowercased()
            let score = searchTerms.reduce(0) { total, term in
                total + title.ranges(of: term).count * 3
                      + details.ranges(of: term).count
            }
            return (faq, score)
        }

        return scored
            .filter { $0.score > 0 }
            .sorted { $0.score > $1.score }
            .map { $0.faq }
    }
}
