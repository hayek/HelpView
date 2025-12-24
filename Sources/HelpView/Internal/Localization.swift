import Foundation

/// Handles localization of FAQ content using stable keys
struct FAQLocalizer {
    /// Localizes FAQ content using stable keys from .xcstrings
    /// Falls back to inline content if no translation found
    /// - Parameters:
    ///   - faq: The FAQ to localize
    ///   - bundle: The bundle containing localization files
    ///   - localization: The string catalog name (defaults to "Localizable")
    /// - Returns: A new FAQ with localized content
    static func localize(_ faq: FAQ, bundle: Bundle, localization: String = "Localizable") -> FAQ {
        guard let key = faq.key else { return faq }

        let prefix = "faq.\(key)"
        return FAQ(
            key: key,
            title: localizedString("\(prefix).title", fallback: faq.title, bundle: bundle, localization: localization),
            details: localizedString("\(prefix).details", fallback: faq.details, bundle: bundle, localization: localization),
            topic: faq.topic.map { localizeTopicName($0, bundle: bundle, localization: localization) }
        )
    }

    /// Localizes a topic name using "topic.{slugified-name}" key
    /// - Parameters:
    ///   - topic: The topic name to localize
    ///   - bundle: The bundle containing localization files
    ///   - localization: The string catalog name (defaults to "Localizable")
    /// - Returns: The localized topic name, or original if no translation found
    static func localizeTopicName(_ topic: String, bundle: Bundle, localization: String = "Localizable") -> String {
        let key = "topic.\(topic.slugified)"
        return localizedString(key, fallback: topic, bundle: bundle, localization: localization)
    }

    /// Localizes a UI string key
    /// - Parameters:
    ///   - key: The localization key
    ///   - fallback: The fallback value if no translation found
    ///   - bundle: The bundle containing localization files
    ///   - localization: The string catalog name
    /// - Returns: The localized string, or fallback if no translation found
    static func localizedString(_ key: String, fallback: String, bundle: Bundle, localization: String) -> String {
        let localized = bundle.localizedString(forKey: key, value: key, table: localization)
        // If returned value equals key, translation not found - use fallback
        return localized == key ? fallback : localized
    }
}

// MARK: - String Extension for Slugification

extension String {
    /// Converts a string to a URL-safe slug format for localization keys
    /// Example: "Getting Started" → "getting-started"
    var slugified: String {
        lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .filter { $0.isLetter || $0.isNumber || $0 == "-" }
    }
}
