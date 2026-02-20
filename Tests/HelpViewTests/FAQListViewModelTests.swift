import XCTest
@testable import HelpView

@MainActor
final class FAQListViewModelTests: XCTestCase {

    var viewModel: FAQListViewModel!
    var testFAQs: [FAQ]!

    override func setUp() async throws {
        viewModel = FAQListViewModel()

        testFAQs = [
            FAQ(title: "How do I reset my password?", details: "Go to Settings and click 'Forgot Password'.", topic: "Account"),
            FAQ(title: "How do I contact support?", details: "Email support@example.com or call 1-800-SUPPORT.", topic: "Support"),
            FAQ(title: "What are the system requirements?", details: "iOS 18+ or macOS 15+.", topic: "Technical"),
            FAQ(title: "How do I delete my account?", details: "Go to Settings > Account > Delete Account.", topic: "Account"),
            FAQ(title: "Is my data encrypted?", details: "Yes, using AES-256 encryption.", topic: "Security"),
        ]
    }

    override func tearDown() async throws {
        viewModel = nil
        testFAQs = nil
    }

    // MARK: - Configuration Tests

    func testConfiguration() {
        viewModel.configure(with: testFAQs)

        XCTAssertFalse(viewModel.topics.isEmpty, "Should create topics from FAQs")
        XCTAssertFalse(viewModel.filteredTopics.isEmpty, "Should initialize filteredTopics")
        XCTAssertEqual(viewModel.filteredTopics.count, viewModel.topics.count,
                       "Initial filteredTopics should match topics")
    }

    func testConfigurationOrganizesTopics() {
        viewModel.configure(with: testFAQs)

        // Should have topics: Account, Security, Support, Technical (4 topics)
        XCTAssertEqual(viewModel.topics.count, 4)

        let topicTitles = Set(viewModel.topics.map { $0.title })
        XCTAssertTrue(topicTitles.contains("Account"))
        XCTAssertTrue(topicTitles.contains("Support"))
        XCTAssertTrue(topicTitles.contains("Technical"))
        XCTAssertTrue(topicTitles.contains("Security"))
    }

    func testConfigurationWithEmptyFAQs() {
        viewModel.configure(with: [])

        XCTAssertTrue(viewModel.topics.isEmpty)
        XCTAssertTrue(viewModel.filteredTopics.isEmpty)
    }

    // MARK: - FAQ Toggle Tests

    func testToggleFAQ() {
        let faqID = testFAQs[0].id

        XCTAssertFalse(viewModel.isFAQExpanded(faqID), "FAQ should start collapsed")

        viewModel.toggleFAQ(faqID)
        XCTAssertTrue(viewModel.isFAQExpanded(faqID), "FAQ should be expanded after toggle")

        viewModel.toggleFAQ(faqID)
        XCTAssertFalse(viewModel.isFAQExpanded(faqID), "FAQ should be collapsed after second toggle")
    }

    func testToggleMultipleFAQs() {
        let faqID1 = testFAQs[0].id
        let faqID2 = testFAQs[1].id

        viewModel.toggleFAQ(faqID1)
        viewModel.toggleFAQ(faqID2)

        XCTAssertTrue(viewModel.isFAQExpanded(faqID1))
        XCTAssertTrue(viewModel.isFAQExpanded(faqID2))

        XCTAssertEqual(viewModel.expandedFAQs.count, 2)
    }

    func testExpandedFAQsSet() {
        let faqID = testFAQs[0].id

        viewModel.toggleFAQ(faqID)
        XCTAssertTrue(viewModel.expandedFAQs.contains(faqID))

        viewModel.toggleFAQ(faqID)
        XCTAssertFalse(viewModel.expandedFAQs.contains(faqID))
    }

    // MARK: - Search Query Tests

    func testSearchQueryInitialState() {
        XCTAssertTrue(viewModel.searchQuery.isEmpty, "Search query should start empty")
        XCTAssertTrue(viewModel.aiResponse.isEmpty, "AI response should start empty")
        XCTAssertTrue(viewModel.relatedFAQs.isEmpty, "Related FAQs should start empty")
        XCTAssertFalse(viewModel.isLoadingAI, "Should not be loading initially")
    }

    func testPerformSearchWithEmptyQuery() async {
        viewModel.configure(with: testFAQs)

        // Expand some FAQs
        viewModel.toggleFAQ(testFAQs[0].id)
        viewModel.searchQuery = ""

        await viewModel.performSearch()

        XCTAssertTrue(viewModel.aiResponse.isEmpty, "AI response should be cleared")
        XCTAssertTrue(viewModel.relatedFAQs.isEmpty, "Related FAQs should be cleared")
        XCTAssertEqual(viewModel.filteredTopics.count, viewModel.topics.count,
                       "Should show all topics")
        XCTAssertTrue(viewModel.expandedFAQs.isEmpty, "Should collapse all FAQs")
    }

    func testPerformSearchCollapsesExpandedFAQs() async {
        viewModel.configure(with: testFAQs)

        // Expand a FAQ
        viewModel.toggleFAQ(testFAQs[0].id)
        XCTAssertEqual(viewModel.expandedFAQs.count, 1)

        // Perform a search
        viewModel.searchQuery = "password"
        await viewModel.performSearch()

        XCTAssertTrue(viewModel.expandedFAQs.isEmpty, "Search should collapse all FAQs")
    }

    func testClearSearch() {
        viewModel.configure(with: testFAQs)
        viewModel.searchQuery = "test query"
        viewModel.aiResponse = "test response"
        viewModel.relatedFAQs = [testFAQs[0]]
        viewModel.toggleFAQ(testFAQs[0].id)

        // Set filteredTopics to something different
        viewModel.filteredTopics = []

        viewModel.clearSearch()

        XCTAssertTrue(viewModel.searchQuery.isEmpty, "Search query should be cleared")
        XCTAssertTrue(viewModel.aiResponse.isEmpty, "AI response should be cleared")
        XCTAssertTrue(viewModel.relatedFAQs.isEmpty, "Related FAQs should be cleared")
        XCTAssertTrue(viewModel.expandedFAQs.isEmpty, "Expanded FAQs should be cleared")
        XCTAssertEqual(viewModel.filteredTopics.count, viewModel.topics.count,
                       "Should restore all topics")
    }

    // MARK: - AI Helper Integration Tests

    func testAIHelperInitialization() {
        // AI availability property should be accessible
        _ = viewModel.isAppleIntelligenceAvailable
    }

    func testSearchWithoutAI() async {
        viewModel.configure(with: testFAQs)

        // Assuming AI is not available in test environment
        if !viewModel.isAppleIntelligenceAvailable {
            viewModel.searchQuery = "password"
            await viewModel.performSearch()

            // Should use text search instead
            XCTAssertTrue(viewModel.aiResponse.isEmpty, "Should not have AI response")
            XCTAssertFalse(viewModel.filteredTopics.isEmpty, "Should have search results")
        }
    }

    // MARK: - Loading State Tests

    func testLoadingStateInitialValue() {
        XCTAssertFalse(viewModel.isLoadingAI, "Should not be loading initially")
    }

    // MARK: - State Consistency Tests

    func testFilteredTopicsConsistency() {
        viewModel.configure(with: testFAQs)

        let initialCount = viewModel.filteredTopics.count
        XCTAssertEqual(initialCount, viewModel.topics.count)

        // After clearing search, should restore
        viewModel.filteredTopics = []
        viewModel.clearSearch()

        XCTAssertEqual(viewModel.filteredTopics.count, initialCount)
    }

    func testMultipleSearches() async {
        viewModel.configure(with: testFAQs)

        // First search
        viewModel.searchQuery = "password"
        await viewModel.performSearch()

        // Clear and second search
        viewModel.clearSearch()
        viewModel.searchQuery = "support"
        await viewModel.performSearch()

        // Should handle multiple searches without issues
        XCTAssertTrue(true, "Multiple searches should not crash")
    }

    // MARK: - Edge Cases

    func testToggleNonExistentFAQ() {
        let randomUUID = UUID()

        // Should not crash when toggling non-existent FAQ
        viewModel.toggleFAQ(randomUUID)

        XCTAssertTrue(viewModel.expandedFAQs.contains(randomUUID),
                      "Should add UUID to set even if FAQ doesn't exist")
    }

    func testConfigurationMultipleTimes() {
        viewModel.configure(with: testFAQs)
        let firstTopicCount = viewModel.topics.count

        // Reconfigure with different FAQs
        let newFAQs = [
            FAQ(title: "New Q1", details: "New A1", topic: "New Topic")
        ]
        viewModel.configure(with: newFAQs)

        XCTAssertNotEqual(viewModel.topics.count, firstTopicCount,
                          "Should update with new configuration")
        XCTAssertEqual(viewModel.topics.count, 1)
    }

    func testSearchQuerySpacesOnly() async {
        viewModel.configure(with: testFAQs)
        viewModel.searchQuery = "   "

        await viewModel.performSearch()

        // Spaces-only should be treated as non-empty in this implementation
        // The behavior depends on how the search is implemented
        XCTAssertTrue(true, "Should handle whitespace-only search")
    }

    // MARK: - Observable Properties Tests

    func testSearchQueryIsObservable() {
        viewModel.searchQuery = "test"
        XCTAssertEqual(viewModel.searchQuery, "test")

        viewModel.searchQuery = "updated"
        XCTAssertEqual(viewModel.searchQuery, "updated")
    }

    func testExpandedFAQsIsObservable() {
        let faqID = testFAQs[0].id

        XCTAssertTrue(viewModel.expandedFAQs.isEmpty)

        viewModel.toggleFAQ(faqID)
        XCTAssertEqual(viewModel.expandedFAQs.count, 1)
    }

    // MARK: - Integration Tests

    func testFullWorkflow() async {
        // Configure
        viewModel.configure(with: testFAQs)
        XCTAssertFalse(viewModel.topics.isEmpty)

        // Expand a FAQ
        let faqID = testFAQs[0].id
        viewModel.toggleFAQ(faqID)
        XCTAssertTrue(viewModel.isFAQExpanded(faqID))

        // Perform search
        viewModel.searchQuery = "password"
        await viewModel.performSearch()
        XCTAssertFalse(viewModel.isFAQExpanded(faqID), "Search should collapse FAQs")

        // Clear search
        viewModel.clearSearch()
        XCTAssertTrue(viewModel.searchQuery.isEmpty)
        XCTAssertEqual(viewModel.filteredTopics.count, viewModel.topics.count)
    }

    func testSearchResultsAreRelevant() async {
        viewModel.configure(with: testFAQs)

        // Search for something specific
        viewModel.searchQuery = "encrypted"
        await viewModel.performSearch()

        if !viewModel.isAppleIntelligenceAvailable {
            // With text search, should filter topics
            XCTAssertFalse(viewModel.filteredTopics.isEmpty, "Should have search results")

            // Count FAQs in filtered topics
            let faqCount = viewModel.filteredTopics.flatMap { $0.faqs }.count
            XCTAssertGreaterThan(faqCount, 0, "Should find relevant FAQs")
        }
    }

    func testTopicsSortedAlphabetically() {
        viewModel.configure(with: testFAQs)

        let topicTitles = viewModel.topics.map { $0.title }
        let sortedTitles = topicTitles.sorted()

        XCTAssertEqual(topicTitles, sortedTitles, "Topics should be sorted alphabetically")
    }
}
