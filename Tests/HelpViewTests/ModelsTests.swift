import XCTest
@testable import HelpView

final class ModelsTests: XCTestCase {

    // MARK: - FAQ Tests

    func testFAQInitialization() {
        let faq = FAQ(
            title: "Test Question",
            details: "Test Answer",
            topic: "Testing"
        )

        XCTAssertEqual(faq.title, "Test Question")
        XCTAssertEqual(faq.details, "Test Answer")
        XCTAssertEqual(faq.topic, "Testing")
        XCTAssertNotNil(faq.id)
    }

    func testFAQInitializationWithoutTopic() {
        let faq = FAQ(
            title: "Test Question",
            details: "Test Answer"
        )

        XCTAssertEqual(faq.title, "Test Question")
        XCTAssertEqual(faq.details, "Test Answer")
        XCTAssertNil(faq.topic)
    }

    func testFAQDecodingFromJSON() throws {
        let json = """
        {
            "title": "How do I reset my password?",
            "details": "Click forgot password",
            "topic": "Account"
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let faq = try decoder.decode(FAQ.self, from: data)

        XCTAssertEqual(faq.title, "How do I reset my password?")
        XCTAssertEqual(faq.details, "Click forgot password")
        XCTAssertEqual(faq.topic, "Account")
        XCTAssertNotNil(faq.id)
    }

    func testFAQDecodingWithEmptyTopic() throws {
        let json = """
        {
            "title": "Test",
            "details": "Answer",
            "topic": ""
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let faq = try decoder.decode(FAQ.self, from: data)

        XCTAssertEqual(faq.title, "Test")
        XCTAssertEqual(faq.details, "Answer")
        XCTAssertNil(faq.topic, "Empty topic string should be converted to nil")
    }

    func testFAQDecodingWithoutTopic() throws {
        let json = """
        {
            "title": "Test",
            "details": "Answer"
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let faq = try decoder.decode(FAQ.self, from: data)

        XCTAssertEqual(faq.title, "Test")
        XCTAssertEqual(faq.details, "Answer")
        XCTAssertNil(faq.topic)
    }

    func testFAQEncodingAndDecoding() throws {
        let originalFAQ = FAQ(
            title: "Original Question",
            details: "Original Answer",
            topic: "Testing"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(originalFAQ)

        let decoder = JSONDecoder()
        let decodedFAQ = try decoder.decode(FAQ.self, from: data)

        XCTAssertEqual(originalFAQ.title, decodedFAQ.title)
        XCTAssertEqual(originalFAQ.details, decodedFAQ.details)
        XCTAssertEqual(originalFAQ.topic, decodedFAQ.topic)
        // Note: ID will be different after decoding as it's always generated
        XCTAssertNotEqual(originalFAQ.id, decodedFAQ.id)
    }

    func testFAQIdentifiable() {
        let faq1 = FAQ(title: "Q1", details: "A1")
        let faq2 = FAQ(title: "Q2", details: "A2")

        XCTAssertNotEqual(faq1.id, faq2.id, "Each FAQ should have a unique ID")
    }

    // MARK: - Topic Tests

    func testTopicCreation() {
        let faqs = [
            FAQ(title: "Q1", details: "A1"),
            FAQ(title: "Q2", details: "A2")
        ]

        let topic = Topic(title: "Test Topic", faqs: faqs)

        XCTAssertEqual(topic.title, "Test Topic")
        XCTAssertEqual(topic.faqs.count, 2)
        XCTAssertNotNil(topic.id)
    }

    func testTopicIdentifiable() {
        let faqs = [FAQ(title: "Q1", details: "A1")]

        let topic1 = Topic(title: "Topic 1", faqs: faqs)
        let topic2 = Topic(title: "Topic 2", faqs: faqs)

        XCTAssertNotEqual(topic1.id, topic2.id, "Each topic should have a unique ID")
    }

    // MARK: - FAQCollection Tests

    func testFAQCollectionDecoding() throws {
        let json = """
        {
            "faqs": [
                {
                    "title": "Question 1",
                    "details": "Answer 1",
                    "topic": "Topic A"
                },
                {
                    "title": "Question 2",
                    "details": "Answer 2",
                    "topic": "Topic B"
                }
            ]
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let collection = try decoder.decode(FAQCollection.self, from: data)

        XCTAssertEqual(collection.faqs.count, 2)
        XCTAssertEqual(collection.faqs[0].title, "Question 1")
        XCTAssertEqual(collection.faqs[1].title, "Question 2")
    }

    func testFAQCollectionEncodingAndDecoding() throws {
        let faqs = [
            FAQ(title: "Q1", details: "A1", topic: "Topic 1"),
            FAQ(title: "Q2", details: "A2", topic: "Topic 2")
        ]

        let originalCollection = FAQCollection(faqs: faqs)

        let encoder = JSONEncoder()
        let data = try encoder.encode(originalCollection)

        let decoder = JSONDecoder()
        let decodedCollection = try decoder.decode(FAQCollection.self, from: data)

        XCTAssertEqual(originalCollection.faqs.count, decodedCollection.faqs.count)
        XCTAssertEqual(originalCollection.faqs[0].title, decodedCollection.faqs[0].title)
        XCTAssertEqual(originalCollection.faqs[1].title, decodedCollection.faqs[1].title)
    }

    func testEmptyFAQCollection() throws {
        let json = """
        {
            "faqs": []
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let collection = try decoder.decode(FAQCollection.self, from: data)

        XCTAssertEqual(collection.faqs.count, 0)
    }
}
