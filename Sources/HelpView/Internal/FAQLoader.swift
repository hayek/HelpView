import Foundation

/// Supported FAQ file formats
enum FAQFileFormat: String {
    case json
    case plist
}

/// Loads and parses FAQ data from JSON or plist files
class FAQLoader {
    /// Load FAQs from a file, automatically detecting the format
    /// - Parameters:
    ///   - filename: The name of the file without extension (will try .json first, then .plist)
    ///   - bundle: The bundle to search in (defaults to .main)
    /// - Returns: Array of FAQ items
    static func load(named filename: String, bundle: Bundle = .main) -> [FAQ] {
        // Try JSON first
        if let faqs = loadFile(named: filename, format: .json, bundle: bundle) {
            return faqs
        }

        // Fall back to plist
        if let faqs = loadFile(named: filename, format: .plist, bundle: bundle) {
            return faqs
        }

        print("❌ HelpView: Could not find \(filename).json or \(filename).plist in bundle")
        return []
    }

    /// Load FAQs from a specific file format
    /// - Parameters:
    ///   - filename: The name of the file without extension
    ///   - format: The file format (.json or .plist)
    ///   - bundle: The bundle to search in (defaults to .main)
    /// - Returns: Array of FAQ items, or nil if loading fails
    static func loadFile(named filename: String, format: FAQFileFormat, bundle: Bundle = .main) -> [FAQ]? {
        guard let url = bundle.url(forResource: filename, withExtension: format.rawValue) else {
            return nil
        }

        guard let data = try? Data(contentsOf: url) else {
            print("❌ HelpView: Could not load data from \(filename).\(format.rawValue)")
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

            return collection.faqs
        } catch {
            print("❌ HelpView: Could not decode FAQs from \(format.rawValue) - \(error.localizedDescription)")
            return nil
        }
    }

    /// Organizes FAQs into topics
    static func organizeIntoTopics(_ faqs: [FAQ]) -> [Topic] {
        var topicGroups: [String: [FAQ]] = [:]

        for faq in faqs {
            let topicName = faq.topic ?? "General"
            topicGroups[topicName, default: []].append(faq)
        }

        return topicGroups.map { Topic(title: $0.key, faqs: $0.value) }
            .sorted { $0.title < $1.title }
    }
}
