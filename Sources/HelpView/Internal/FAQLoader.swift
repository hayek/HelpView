import Foundation
import os

/// Supported FAQ file formats
enum FAQFileFormat: String {
    case json
    case plist
}

/// Loads and parses FAQ data from JSON or plist files
enum FAQLoader {
    private static let logger = Logger(subsystem: "com.helpview", category: "FAQLoader")
    /// Load FAQs from a file, automatically detecting the format
    /// - Parameters:
    ///   - filename: The name of the file without extension (will try .json first, then .plist)
    ///   - bundle: The bundle to search in (defaults to .main)
    ///   - localization: The string catalog name for localization (defaults to "Localizable")
    /// - Returns: A tuple containing the FAQ array and optional topic order
    static func load(named filename: String, bundle: Bundle = .main, localization: String = "Localizable") -> (faqs: [FAQ], topicOrder: [String]?) {
        // Try JSON first, then fall back to plist
        let result = loadFile(named: filename, format: .json, bundle: bundle)
                  ?? loadFile(named: filename, format: .plist, bundle: bundle)

        guard let result else {
            logger.error("Could not find \(filename).json or \(filename).plist in bundle")
            return ([], nil)
        }

        let localizedFAQs = result.faqs.map { FAQLocalizer.localize($0, bundle: bundle, localization: localization) }
        let localizedTopicOrder = result.topicOrder?.map { FAQLocalizer.localizeTopicName($0, bundle: bundle, localization: localization) }
        return (localizedFAQs, localizedTopicOrder)
    }

    /// Load FAQs from a specific file format
    /// - Parameters:
    ///   - filename: The name of the file without extension
    ///   - format: The file format (.json or .plist)
    ///   - bundle: The bundle to search in (defaults to .main)
    /// - Returns: A tuple containing the FAQ array and optional topic order, or nil if loading fails
    static func loadFile(named filename: String, format: FAQFileFormat, bundle: Bundle = .main) -> (faqs: [FAQ], topicOrder: [String]?)? {
        guard let url = bundle.url(forResource: filename, withExtension: format.rawValue) else {
            return nil
        }

        guard let data = try? Data(contentsOf: url) else {
            logger.error("Could not load data from \(filename).\(format.rawValue)")
            return nil
        }

        do {
            let collection: FAQCollection

            switch format {
            case .json:
                let decoder = JSONDecoder()
                collection = try decoder.decode(FAQCollection.self, from: data)

            case .plist:
                let decoder = PropertyListDecoder()
                collection = try decoder.decode(FAQCollection.self, from: data)
            }

            return (collection.faqs, collection.topics)
        } catch {
            logger.error("Could not decode FAQs from \(format.rawValue): \(error.localizedDescription)")
            return nil
        }
    }

    /// Organizes FAQs into topics with optional custom ordering
    /// - Parameters:
    ///   - faqs: Array of FAQ items to organize
    ///   - topicOrder: Optional array of topic names in desired order. Topics not in this list appear after, sorted alphabetically.
    ///   - bundle: The bundle for localization (defaults to .main)
    ///   - localization: The string catalog name for localization (defaults to "Localizable")
    /// - Returns: Array of Topic objects, with "General" (root topic) always first if it exists
    static func organizeIntoTopics(_ faqs: [FAQ], topicOrder: [String]? = nil, bundle: Bundle = .main, localization: String = "Localizable") -> [Topic] {
        // Use Bundle.module for framework-internal UI strings like "General"
        let generalTopicName = FAQLocalizer.localizedString("topic.general", fallback: "General", bundle: .module, localization: "Localizable")

        var topicGroups: [String: [FAQ]] = [:]

        for faq in faqs {
            let topicName = faq.topic ?? generalTopicName
            topicGroups[topicName, default: []].append(faq)
        }

        let topics = topicGroups.map { Topic(title: $0.key, faqs: $0.value) }

        // Sort topics with custom logic
        return topics.sorted { topic1, topic2 in
            let name1 = topic1.title
            let name2 = topic2.title

            // Equal names: strict weak ordering requires false
            if name1 == name2 { return false }

            // "General" (or its localized equivalent) always comes first
            if name1 == generalTopicName { return true }
            if name2 == generalTopicName { return false }

            // If we have a custom order, use it
            if let order = topicOrder {
                let index1 = order.firstIndex(of: name1)
                let index2 = order.firstIndex(of: name2)

                switch (index1, index2) {
                case let (.some(i1), .some(i2)):
                    return i1 < i2 // Both in order list, use order
                case (.some, .none):
                    return true // name1 in list, name2 not - name1 comes first
                case (.none, .some):
                    return false // name2 in list, name1 not - name2 comes first
                case (.none, .none):
                    return name1 < name2 // Neither in list, alphabetical
                }
            }

            // No custom order, use alphabetical
            return name1 < name2
        }
    }
}
