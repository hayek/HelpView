import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

/// Represents a single FAQ item
struct FAQ: Codable, Identifiable {
    let id: UUID
    let title: String // The question
    let details: String // The answer in markdown
    let topic: String? // Optional topic grouping

    init(id: UUID = UUID(), title: String, details: String, topic: String? = nil) {
        self.id = id
        self.title = title
        self.details = details
        self.topic = topic
    }

    // Custom decoder to handle empty strings from plist files
    // Note: id is always auto-generated, never decoded from file
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Always generate a new UUID
        self.id = UUID()

        self.title = try container.decode(String.self, forKey: .title)
        self.details = try container.decode(String.self, forKey: .details)

        // Handle optional topic, treating empty strings as nil
        if let topicValue = try? container.decode(String.self, forKey: .topic) {
            self.topic = topicValue.isEmpty ? nil : topicValue
        } else {
            self.topic = nil
        }
    }

    private enum CodingKeys: String, CodingKey {
        case title, details, topic
    }
}

/// Represents a topic group of FAQs
struct Topic: Identifiable {
    let id = UUID()
    let title: String
    let faqs: [FAQ]
}

/// Container for all FAQs loaded from JSON
struct FAQCollection: Codable {
    let faqs: [FAQ]
    let topics: [String]? // Optional ordered list of topic names
}

// MARK: - AI Response Model

#if canImport(FoundationModels)
@available(iOS 26.0, macOS 26.0, *)
@Generable
struct HelpResponse {
    @Guide(description: "Answer ONLY using the FAQ information provided. If the question is not covered in the FAQs, refuse politely and suggest relevant FAQ topics. Do NOT use external knowledge. Do NOT answer general questions.")
    var answer: String

    @Guide(description: "List of FAQ titles that are most relevant to the user's question. Include 2-4 related FAQs from the provided FAQ list.")
    var relatedFAQs: [String]
}
#endif
