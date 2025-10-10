import XCTest
@testable import HelpView

@MainActor
final class AIHelperTests: XCTestCase {

    var aiHelper: AIHelper!
    var testFAQs: [FAQ]!

    override func setUp() async throws {
        aiHelper = AIHelper()

        // Create test FAQs
        testFAQs = [
            FAQ(title: "How do I reset my password?", details: "To reset your password, go to Settings and click 'Forgot Password'. You will receive an email with instructions.", topic: "Account"),
            FAQ(title: "How do I contact support?", details: "You can contact support by emailing support@example.com or calling 1-800-SUPPORT.", topic: "Support"),
            FAQ(title: "What are the system requirements?", details: "The app requires iOS 18 or later and macOS 15 or later.", topic: "Technical"),
            FAQ(title: "How do I delete my account?", details: "To delete your account, go to Settings > Account > Delete Account. This action is permanent and cannot be undone.", topic: "Account"),
            FAQ(title: "Is my data encrypted?", details: "Yes, all data is encrypted using AES-256 encryption both in transit and at rest.", topic: "Security"),
            FAQ(title: "Can I export my data?", details: "Yes, you can export your data by going to Settings > Privacy > Export Data.", topic: "Privacy"),
        ]

        aiHelper.configure(with: testFAQs)
    }

    override func tearDown() async throws {
        aiHelper = nil
        testFAQs = nil
    }

    // MARK: - Configuration Tests

    func testConfiguration() {
        let helper = AIHelper()
        let faqs = [FAQ(title: "Test", details: "Answer")]

        helper.configure(with: faqs)

        // Configuration doesn't throw or crash
        XCTAssertTrue(true, "Configuration should complete successfully")
    }

    // MARK: - Search Tests

    func testSearchWithSingleTerm() {
        let results = aiHelper.searchFAQs(query: "password")

        XCTAssertFalse(results.isEmpty, "Should find FAQs containing 'password'")
        XCTAssertTrue(results.contains { $0.title.lowercased().contains("password") },
                      "Results should contain FAQ about password")
    }

    func testSearchWithMultipleTerms() {
        let results = aiHelper.searchFAQs(query: "reset password")

        XCTAssertFalse(results.isEmpty, "Should find FAQs containing 'reset' and 'password'")

        // The first result should be the most relevant (contains both terms)
        let firstResult = results.first
        XCTAssertNotNil(firstResult)
        XCTAssertTrue(firstResult?.title.lowercased().contains("password") ?? false)
        XCTAssertTrue(firstResult?.title.lowercased().contains("reset") ?? false)
    }

    func testSearchInDetails() {
        let results = aiHelper.searchFAQs(query: "email")

        XCTAssertFalse(results.isEmpty, "Should find FAQs with 'email' in details")

        // Should find at least the "contact support" FAQ
        let contactSupportFAQ = results.first { $0.title.lowercased().contains("contact") }
        XCTAssertNotNil(contactSupportFAQ, "Should find FAQ about contacting support")
    }

    func testSearchReturnsResultsSortedByRelevance() {
        // "password" appears multiple times in the reset password FAQ
        let results = aiHelper.searchFAQs(query: "password")

        XCTAssertFalse(results.isEmpty)

        // The first result should be most relevant
        let firstResult = results.first
        XCTAssertEqual(firstResult?.title, "How do I reset my password?",
                       "Most relevant FAQ should be first")
    }

    func testSearchWithNoMatches() {
        let results = aiHelper.searchFAQs(query: "xyzabc123")

        XCTAssertTrue(results.isEmpty, "Should return empty array for no matches")
    }

    func testSearchWithEmptyQuery() {
        let results = aiHelper.searchFAQs(query: "")

        XCTAssertEqual(results.count, testFAQs.count,
                       "Empty query should return all FAQs")
    }

    func testSearchIsCaseInsensitive() {
        let lowercaseResults = aiHelper.searchFAQs(query: "password")
        let uppercaseResults = aiHelper.searchFAQs(query: "PASSWORD")
        let mixedResults = aiHelper.searchFAQs(query: "PaSsWoRd")

        XCTAssertEqual(lowercaseResults.count, uppercaseResults.count)
        XCTAssertEqual(lowercaseResults.count, mixedResults.count)
    }

    func testSearchWithWhitespace() {
        let results = aiHelper.searchFAQs(query: "  reset   password  ")

        XCTAssertFalse(results.isEmpty, "Should handle queries with extra whitespace")
    }

    func testSearchScoring() {
        // Create test FAQs where one clearly matches better
        let scoringFAQs = [
            FAQ(title: "Password", details: "All about passwords", topic: "Test"),
            FAQ(title: "Other topic", details: "Mention password once", topic: "Test"),
        ]

        let helper = AIHelper()
        helper.configure(with: scoringFAQs)

        let results = helper.searchFAQs(query: "password")

        XCTAssertEqual(results.count, 2)
        // First result should be the one with "password" in title and details
        XCTAssertEqual(results[0].title, "Password",
                       "FAQ with more occurrences should rank higher")
    }

    func testSearchWithCommonWords() {
        let results = aiHelper.searchFAQs(query: "my")

        // "my" appears in multiple FAQs
        XCTAssertFalse(results.isEmpty, "Should find FAQs with common words")
    }

    func testSearchPartialMatch() {
        let results = aiHelper.searchFAQs(query: "encrypt")

        // Should match "encrypted", "encryption"
        XCTAssertFalse(results.isEmpty, "Should find FAQs with partial matches")

        let encryptionFAQ = results.first { $0.topic == "Security" }
        XCTAssertNotNil(encryptionFAQ, "Should find encryption FAQ")
    }

    // MARK: - Apple Intelligence Availability Tests

    func testAppleIntelligenceAvailability() {
        // This test documents the behavior, but the actual availability
        // depends on the test environment
        let isAvailable = aiHelper.isAppleIntelligenceAvailable

        // Just verify it returns a boolean without crashing
        XCTAssertNotNil(isAvailable)
    }

    // MARK: - Edge Cases

    func testSearchWithSpecialCharacters() {
        let results = aiHelper.searchFAQs(query: "support@example.com")

        // Should find the contact support FAQ
        XCTAssertFalse(results.isEmpty, "Should handle special characters")
    }

    func testSearchWithNumbers() {
        let results = aiHelper.searchFAQs(query: "1-800")

        // Should find the contact support FAQ
        XCTAssertFalse(results.isEmpty, "Should handle numbers in search")
    }

    func testConfigureWithEmptyFAQs() {
        let helper = AIHelper()
        helper.configure(with: [])

        let results = helper.searchFAQs(query: "test")

        XCTAssertTrue(results.isEmpty, "Should return empty for empty FAQ list")
    }

    func testMultipleConfigurations() {
        let helper = AIHelper()

        let faqs1 = [FAQ(title: "First", details: "Answer1")]
        helper.configure(with: faqs1)

        let results1 = helper.searchFAQs(query: "First")
        XCTAssertEqual(results1.count, 1)

        // Reconfigure with different FAQs
        let faqs2 = [FAQ(title: "Second", details: "Answer2")]
        helper.configure(with: faqs2)

        let results2 = helper.searchFAQs(query: "First")
        XCTAssertTrue(results2.isEmpty, "Should use new configuration")

        let results3 = helper.searchFAQs(query: "Second")
        XCTAssertEqual(results3.count, 1, "Should find FAQ from new configuration")
    }

    // MARK: - Search Performance Tests

    func testSearchWithLargeFAQList() {
        var largeFAQList: [FAQ] = []
        for i in 0..<100 {
            largeFAQList.append(
                FAQ(title: "Question \(i)",
                    details: "Answer \(i) with some additional content",
                    topic: "Topic \(i % 10)")
            )
        }

        let helper = AIHelper()
        helper.configure(with: largeFAQList)

        let results = helper.searchFAQs(query: "Question")

        XCTAssertGreaterThan(results.count, 0, "Should handle large FAQ lists")
    }

    // MARK: - Integration Tests

    func testSearchReturnsCompleteObjects() {
        let results = aiHelper.searchFAQs(query: "password")

        guard let firstResult = results.first else {
            XCTFail("Should have at least one result")
            return
        }

        XCTAssertNotNil(firstResult.id)
        XCTAssertFalse(firstResult.title.isEmpty)
        XCTAssertFalse(firstResult.details.isEmpty)
    }
}
