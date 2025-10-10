import SwiftUI

@MainActor
@Observable
class FAQListViewModel {
    var expandedFAQs: Set<UUID> = []
    var searchQuery: String = ""
    var aiResponse: String = ""
    var relatedFAQs: [FAQ] = []
    var isLoadingAI: Bool = false

    var topics: [Topic] = []
    var filteredTopics: [Topic] = []

    let aiHelper = AIHelper()

    func configure(with faqs: [FAQ]) {
        self.topics = FAQLoader.organizeIntoTopics(faqs)
        self.filteredTopics = topics
        aiHelper.configure(with: faqs)
    }

    func toggleFAQ(_ faqID: UUID) {
        if expandedFAQs.contains(faqID) {
            expandedFAQs.remove(faqID)
        } else {
            expandedFAQs.insert(faqID)
        }
    }

    func isFAQExpanded(_ faqID: UUID) -> Bool {
        expandedFAQs.contains(faqID)
    }

    func performSearch() async {
        guard !searchQuery.isEmpty else {
            filteredTopics = topics
            aiResponse = ""
            relatedFAQs = []
            expandedFAQs = [] // Collapse all FAQs
            isLoadingAI = false
            return
        }

        // Collapse all FAQs when starting a new search
        expandedFAQs = []

        // If AI is available, use it
        if aiHelper.isAppleIntelligenceAvailable {
            isLoadingAI = true
            aiResponse = "" // Clear previous response
            relatedFAQs = [] // Clear previous related FAQs

            do {
                let result = try await aiHelper.generateResponse(for: searchQuery)
                aiResponse = result.answer
                relatedFAQs = result.relatedFAQs
            } catch {
                aiResponse = "Unable to generate response. Please try again."
                relatedFAQs = []
            }
            isLoadingAI = false
        } else {
            // Use search instead
            let searchResults = aiHelper.searchFAQs(query: searchQuery)
            filteredTopics = FAQLoader.organizeIntoTopics(searchResults)
        }
    }

    func clearSearch() {
        searchQuery = ""
        aiResponse = ""
        relatedFAQs = []
        filteredTopics = topics
    }
}
