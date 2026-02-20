import XCTest
@testable import HelpView

final class LocalizationTests: XCTestCase {

    // MARK: - String.slugified Tests

    func testSlugifySimpleString() {
        XCTAssertEqual("Getting Started".slugified, "getting-started")
    }

    func testSlugifyAlreadySlugified() {
        XCTAssertEqual("already-slugified".slugified, "already-slugified")
    }

    func testSlugifyWithSpecialCharacters() {
        XCTAssertEqual("Hello, World!".slugified, "hello-world")
    }

    func testSlugifyWithNumbers() {
        XCTAssertEqual("Step 1: Setup".slugified, "step-1-setup")
    }

    func testSlugifyEmptyString() {
        XCTAssertEqual("".slugified, "")
    }

    func testSlugifyWithMultipleSpaces() {
        XCTAssertEqual("too   many   spaces".slugified, "too---many---spaces")
    }

    func testSlugifySingleWord() {
        XCTAssertEqual("General".slugified, "general")
    }

    // MARK: - FAQLocalizer Tests

    func testLocalizeFAQWithoutKey() {
        let faq = FAQ(title: "Test", details: "Answer", topic: "Topic")

        let localized = FAQLocalizer.localize(faq, bundle: .module)

        // Without a key, FAQ should be returned unchanged
        XCTAssertEqual(localized.title, "Test")
        XCTAssertEqual(localized.details, "Answer")
        XCTAssertEqual(localized.topic, "Topic")
    }

    func testLocalizeFAQWithUnknownKey() {
        let faq = FAQ(key: "nonexistent-key", title: "Fallback Title", details: "Fallback Details", topic: "Topic")

        let localized = FAQLocalizer.localize(faq, bundle: .module)

        // With a key that has no translation, should fall back to original content
        XCTAssertEqual(localized.title, "Fallback Title")
        XCTAssertEqual(localized.details, "Fallback Details")
    }

    func testLocalizedStringFallback() {
        let result = FAQLocalizer.localizedString("nonexistent.key", fallback: "My Fallback", bundle: .module, localization: "Localizable")

        XCTAssertEqual(result, "My Fallback", "Should return fallback when key not found")
    }

    func testLocalizeTopicNameUnknown() {
        let result = FAQLocalizer.localizeTopicName("Unknown Topic", bundle: .module)

        XCTAssertEqual(result, "Unknown Topic", "Should return original name when no translation found")
    }

    func testLocalizeFAQPreservesKey() {
        let faq = FAQ(key: "test-key", title: "Title", details: "Details")

        let localized = FAQLocalizer.localize(faq, bundle: .module)

        XCTAssertEqual(localized.key, "test-key", "Key should be preserved after localization")
    }

    func testLocalizeFAQWithNilTopic() {
        let faq = FAQ(key: "some-key", title: "Title", details: "Details", topic: nil)

        let localized = FAQLocalizer.localize(faq, bundle: .module)

        XCTAssertNil(localized.topic, "Nil topic should remain nil after localization")
    }
}
