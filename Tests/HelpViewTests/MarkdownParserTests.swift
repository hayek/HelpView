import XCTest
@testable import HelpView

@MainActor
final class MarkdownParserTests: XCTestCase {

    // Helper to access the static parseMarkdown method via MarkdownTextView
    private func parse(_ markdown: String) -> [MarkdownBlock] {
        // Use the internal static method via a wrapper
        return MarkdownTextView.testParseMarkdown(markdown)
    }

    // MARK: - Basic Text Parsing

    func testPlainText() {
        let blocks = parse("Hello, world!")

        XCTAssertEqual(blocks.count, 1)
        XCTAssertEqual(blocks[0].type, .text)
        XCTAssertEqual(blocks[0].content, "Hello, world!")
    }

    func testEmptyString() {
        let blocks = parse("")

        // An empty string still splits into one empty line, which produces
        // a text block with empty trimmed content. This is acceptable behavior.
        XCTAssertTrue(blocks.isEmpty || blocks.allSatisfy { $0.content.isEmpty })
    }

    // MARK: - Code Block Parsing

    func testSimpleCodeBlock() {
        let markdown = """
        Some text before
        ```swift
        let x = 1
        ```
        Some text after
        """

        let blocks = parse(markdown)

        XCTAssertEqual(blocks.count, 3)
        XCTAssertEqual(blocks[0].type, .text)
        XCTAssertEqual(blocks[0].content, "Some text before")
        XCTAssertEqual(blocks[1].type, .code)
        XCTAssertEqual(blocks[1].content, "let x = 1")
        XCTAssertEqual(blocks[1].language, "swift")
        XCTAssertEqual(blocks[2].type, .text)
        XCTAssertEqual(blocks[2].content, "Some text after")
    }

    func testCodeBlockWithoutLanguage() {
        let markdown = """
        ```
        some code
        ```
        """

        let blocks = parse(markdown)

        XCTAssertEqual(blocks.count, 1)
        XCTAssertEqual(blocks[0].type, .code)
        XCTAssertNil(blocks[0].language)
        XCTAssertEqual(blocks[0].content, "some code")
    }

    func testUnclosedCodeBlock() {
        let markdown = """
        ```swift
        let x = 1
        let y = 2
        """

        let blocks = parse(markdown)

        XCTAssertEqual(blocks.count, 1)
        XCTAssertEqual(blocks[0].type, .code)
        XCTAssertEqual(blocks[0].language, "swift")
        XCTAssertTrue(blocks[0].content.contains("let x = 1"))
    }

    func testEmptyCodeBlock() {
        let markdown = """
        ```swift
        ```
        """

        let blocks = parse(markdown)

        // Empty code block should not produce a code block entry
        XCTAssertTrue(blocks.isEmpty || blocks.allSatisfy { $0.type == .text })
    }

    func testMultipleCodeBlocks() {
        let markdown = """
        First text
        ```swift
        code1
        ```
        Middle text
        ```python
        code2
        ```
        Last text
        """

        let blocks = parse(markdown)

        XCTAssertEqual(blocks.count, 5)
        XCTAssertEqual(blocks[0].type, .text)
        XCTAssertEqual(blocks[1].type, .code)
        XCTAssertEqual(blocks[1].language, "swift")
        XCTAssertEqual(blocks[2].type, .text)
        XCTAssertEqual(blocks[3].type, .code)
        XCTAssertEqual(blocks[3].language, "python")
        XCTAssertEqual(blocks[4].type, .text)
    }

    // MARK: - Block ID Uniqueness

    func testBlockIDsAreUnique() {
        let markdown = """
        Text block
        ```swift
        code block
        ```
        Another text block
        """

        let blocks = parse(markdown)
        let ids = blocks.map { $0.id }
        let uniqueIds = Set(ids)

        XCTAssertEqual(ids.count, uniqueIds.count, "All block IDs should be unique")
    }

    func testUnclosedCodeBlockWithTrailingText() {
        // Tests the fix for M-5: duplicate IDs with both remaining text and unclosed code
        let markdown = "Some text\n```swift\ncode here"

        let blocks = parse(markdown)
        let ids = blocks.map { $0.id }
        let uniqueIds = Set(ids)

        XCTAssertEqual(ids.count, uniqueIds.count, "Block IDs should be unique even with unclosed code blocks")
    }

    // MARK: - Edge Cases

    func testOnlyCodeFences() {
        let markdown = "```\n```"

        _ = parse(markdown)

        // Should handle gracefully without crash
        XCTAssertTrue(true, "Should not crash with only code fences")
    }

    func testTextWithNewlines() {
        let markdown = "Line 1\n\nLine 3"

        let blocks = parse(markdown)

        XCTAssertEqual(blocks.count, 1)
        XCTAssertEqual(blocks[0].type, .text)
    }
}
