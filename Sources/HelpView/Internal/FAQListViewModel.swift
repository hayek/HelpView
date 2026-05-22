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
    var topicOrder: [String]?
    var localization: String = "Localizable"

    private let aiHelper = AIHelper()
    private var currentSearchTask: Task<Void, Never>?

    var isAppleIntelligenceAvailable: Bool { aiHelper.isAppleIntelligenceAvailable }

    func configure(with faqs: [FAQ], topicOrder: [String]? = nil, localization: String = "Localizable", appContext: String? = nil) {
        self.topicOrder = topicOrder
        self.localization = localization
        self.topics = FAQLoader.organizeIntoTopics(faqs, topicOrder: topicOrder, localization: localization)
        self.filteredTopics = topics
        aiHelper.configure(with: faqs, appContext: appContext)
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
        // Cancel any in-flight search
        currentSearchTask?.cancel()

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

            let queryAtStart = searchQuery

            let task = Task {
                do {
                    let result = try await aiHelper.generateResponse(for: queryAtStart)

                    // Verify this search is still current before applying results
                    guard !Task.isCancelled, queryAtStart == searchQuery else { return }

                    aiResponse = result.answer
                    relatedFAQs = result.relatedFAQs
                    // Also update filteredTopics with related FAQs for state consistency
                    filteredTopics = FAQLoader.organizeIntoTopics(result.relatedFAQs, topicOrder: topicOrder, localization: localization)
                    isLoadingAI = false
                } catch {
                    guard !Task.isCancelled, queryAtStart == searchQuery else { return }
                    // AI failed — fall back to text-based search so the user still gets results
                    aiResponse = ""
                    relatedFAQs = []
                    let searchResults = aiHelper.searchFAQs(query: queryAtStart)
                    filteredTopics = FAQLoader.organizeIntoTopics(searchResults, topicOrder: topicOrder, localization: localization)
                    isLoadingAI = false
                }
            }
            currentSearchTask = task
            await task.value
        } else {
            // Use search instead
            let searchResults = aiHelper.searchFAQs(query: searchQuery)
            filteredTopics = FAQLoader.organizeIntoTopics(searchResults, topicOrder: topicOrder, localization: localization)
        }
    }

    func clearSearch() {
        currentSearchTask?.cancel()
        searchQuery = ""
        aiResponse = ""
        relatedFAQs = []
        expandedFAQs = []
        isLoadingAI = false
        filteredTopics = topics
    }
}
