import Foundation
import FoundationModels

@MainActor
@Observable
class AIHelper {
    var isAppleIntelligenceAvailable: Bool {
        if case .available = SystemLanguageModel.default.availability {
            return true
        }
        return false
    }

    private var faqs: [FAQ] = []
    private var session: LanguageModelSession?

    func configure(with faqs: [FAQ]) {
        self.faqs = faqs

        // Create session once during configuration for better performance
        guard isAppleIntelligenceAvailable else { return }

        let faqContext = faqs.map { "Q: \($0.title)\nA: \($0.details)" }.joined(separator: "\n\n")

        let systemPrompt = """
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

        self.session = LanguageModelSession {
            systemPrompt
        }
    }

    /// Generates AI response using Apple's Foundation Models
    func generateResponse(for userQuery: String) async throws -> (answer: String, relatedFAQs: [FAQ]) {
        guard isAppleIntelligenceAvailable else {
            throw NSError(domain: "AIHelper", code: 1, userInfo: [NSLocalizedDescriptionKey: "Apple Intelligence is not available"])
        }

        guard let session = session else {
            throw NSError(domain: "AIHelper", code: 2, userInfo: [NSLocalizedDescriptionKey: "Session not initialized. Call configure(with:) first."])
        }

        // Use the pre-created session for better performance
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
    }

    /// Performs text-based search when AI is not available
    func searchFAQs(query: String) -> [FAQ] {
        guard !query.isEmpty else { return faqs }

        let searchTerms = query.lowercased().split(separator: " ").map(String.init)

        let scored = faqs.map { faq -> (faq: FAQ, score: Int) in
            let searchableText = (faq.title + " " + faq.details).lowercased()
            let score = searchTerms.reduce(0) { total, term in
                let count = searchableText.components(separatedBy: term).count - 1
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
