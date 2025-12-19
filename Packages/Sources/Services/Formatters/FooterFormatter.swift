import Foundation
import SampleIndex
import Search
import Shared

// MARK: - Footer Types

/// Types of footer content in search results
public enum FooterKind: String, Sendable, CaseIterable {
    case sourceTip // Tip about other sources
    case semanticTip // Tip about semantic search tools
    case teaser // Preview results from other sources
    case platformTip // Tip about platform filters
    case custom // Custom footer content
}

/// A single footer item
public struct FooterItem: Sendable {
    public let kind: FooterKind
    public let title: String?
    public let content: String
    public let emoji: String?

    public init(
        kind: FooterKind,
        title: String? = nil,
        content: String,
        emoji: String? = nil
    ) {
        self.kind = kind
        self.title = title
        self.content = content
        self.emoji = emoji
    }
}

// MARK: - Footer Protocol

/// Protocol for types that can provide footer content
public protocol FooterProvider: Sendable {
    /// Generate footer items for this context
    func makeFooter() -> [FooterItem]
}

// MARK: - Search Footer

/// Collects all footer content for search results
public struct SearchFooter: Sendable, FooterProvider {
    /// Current source being searched (nil = all sources)
    public let currentSource: String?

    /// Teaser results from other sources
    public let teasers: TeaserResults?

    /// Whether to show semantic search tip
    public let showSemanticTip: Bool

    /// Whether to show platform filter tip
    public let showPlatformTip: Bool

    /// Custom footer items
    public let customItems: [FooterItem]

    public init(
        currentSource: String? = nil,
        teasers: TeaserResults? = nil,
        showSemanticTip: Bool = true,
        showPlatformTip: Bool = true,
        customItems: [FooterItem] = []
    ) {
        self.currentSource = currentSource
        self.teasers = teasers
        self.showSemanticTip = showSemanticTip
        self.showPlatformTip = showPlatformTip
        self.customItems = customItems
    }

    public func makeFooter() -> [FooterItem] {
        var items: [FooterItem] = []

        // 1. Source tip (always show)
        let sourceTip = if currentSource == nil {
            // Unified search - show how to narrow
            "_To narrow results, use `source` parameter: \(Shared.Constants.MCP.availableSources.joined(separator: ", "))_"
        } else {
            // Single source - show other sources
            Shared.Constants.MCP.tipOtherSources(excluding: currentSource)
        }
        items.append(FooterItem(
            kind: .sourceTip,
            content: sourceTip,
            emoji: "💡"
        ))

        // 2. Teasers (if available and not searching all)
        if let teasers, !teasers.isEmpty {
            items.append(contentsOf: makeTeaserItems(teasers))
        }

        // 3. Semantic search tip
        if showSemanticTip {
            items.append(FooterItem(
                kind: .semanticTip,
                content: Shared.Constants.MCP.tipSemanticSearch,
                emoji: "🔍"
            ))
        }

        // 4. Platform filter tip
        if showPlatformTip {
            items.append(FooterItem(
                kind: .platformTip,
                content: Shared.Constants.MCP.tipPlatformFilters,
                emoji: "📱"
            ))
        }

        // 5. Custom items
        items.append(contentsOf: customItems)

        return items
    }

    private func makeTeaserItems(_ teasers: TeaserResults) -> [FooterItem] {
        var items: [FooterItem] = []
        typealias Prefix = Shared.Constants.SourcePrefix

        if !teasers.appleDocs.isEmpty {
            let titles = teasers.appleDocs.map { "- \($0.title)" }.joined(separator: "\n")
            items.append(FooterItem(
                kind: .teaser,
                title: "Also in Apple Documentation",
                content: "\(titles)\n_→ Use `source: \(Prefix.appleDocs)`_",
                emoji: Prefix.emojiAppleDocs
            ))
        }

        if !teasers.samples.isEmpty {
            let titles = teasers.samples.map { "- \($0.title)" }.joined(separator: "\n")
            items.append(FooterItem(
                kind: .teaser,
                title: "Also in Sample Code",
                content: "\(titles)\n_→ Use `source: \(Prefix.samples)`_",
                emoji: Prefix.emojiSamples
            ))
        }

        if !teasers.archive.isEmpty {
            let titles = teasers.archive.map { "- \($0.title)" }.joined(separator: "\n")
            items.append(FooterItem(
                kind: .teaser,
                title: "Also in Apple Archive",
                content: "\(titles)\n_→ Use `source: \(Prefix.appleArchive)`_",
                emoji: Prefix.emojiArchive
            ))
        }

        if !teasers.hig.isEmpty {
            let titles = teasers.hig.map { "- \($0.title)" }.joined(separator: "\n")
            items.append(FooterItem(
                kind: .teaser,
                title: "Also in Human Interface Guidelines",
                content: "\(titles)\n_→ Use `source: \(Prefix.hig)`_",
                emoji: Prefix.emojiHIG
            ))
        }

        if !teasers.swiftEvolution.isEmpty {
            let titles = teasers.swiftEvolution.map { "- \($0.title)" }.joined(separator: "\n")
            items.append(FooterItem(
                kind: .teaser,
                title: "Also in Swift Evolution",
                content: "\(titles)\n_→ Use `source: \(Prefix.swiftEvolution)`_",
                emoji: Prefix.emojiSwiftEvolution
            ))
        }

        if !teasers.swiftOrg.isEmpty {
            let titles = teasers.swiftOrg.map { "- \($0.title)" }.joined(separator: "\n")
            items.append(FooterItem(
                kind: .teaser,
                title: "Also in Swift.org",
                content: "\(titles)\n_→ Use `source: \(Prefix.swiftOrg)`_",
                emoji: Prefix.emojiSwiftOrg
            ))
        }

        if !teasers.swiftBook.isEmpty {
            let titles = teasers.swiftBook.map { "- \($0.title)" }.joined(separator: "\n")
            items.append(FooterItem(
                kind: .teaser,
                title: "Also in Swift Book",
                content: "\(titles)\n_→ Use `source: \(Prefix.swiftBook)`_",
                emoji: Prefix.emojiSwiftBook
            ))
        }

        if !teasers.packages.isEmpty {
            let titles = teasers.packages.map { "- \($0.title)" }.joined(separator: "\n")
            items.append(FooterItem(
                kind: .teaser,
                title: "Also in Swift Packages",
                content: "\(titles)\n_→ Use `source: \(Prefix.packages)`_",
                emoji: Prefix.emojiPackages
            ))
        }

        return items
    }
}

// MARK: - Footer Formatter Protocol

/// Protocol for formatting footer content
public protocol FooterFormattable {
    func format(_ items: [FooterItem]) -> String
}

// MARK: - Markdown Footer Formatter

/// Formats footer items as markdown
public struct MarkdownFooterFormatter: FooterFormattable {
    public init() {}

    public func format(_ items: [FooterItem]) -> String {
        guard !items.isEmpty else { return "" }

        var output = "\n---\n\n"

        for item in items {
            switch item.kind {
            case .teaser:
                if let emoji = item.emoji, let title = item.title {
                    output += "\(emoji) **\(title):**\n"
                }
                output += item.content + "\n\n"

            case .sourceTip, .semanticTip, .platformTip:
                output += item.content + "\n\n"

            case .custom:
                if let title = item.title {
                    output += "**\(title):** "
                }
                output += item.content + "\n\n"
            }
        }

        return output.trimmingCharacters(in: .newlines) + "\n"
    }
}

// MARK: - Text Footer Formatter

/// Formats footer items as plain text (CLI)
public struct TextFooterFormatter: FooterFormattable {
    public init() {}

    public func format(_ items: [FooterItem]) -> String {
        guard !items.isEmpty else { return "" }

        var output = "\n" + String(repeating: "-", count: 40) + "\n"

        for item in items {
            switch item.kind {
            case .teaser:
                if let title = item.title {
                    output += "\(title):\n"
                }
                // Convert markdown list to text
                let textContent = item.content
                    .replacingOccurrences(of: "_→", with: "→")
                    .replacingOccurrences(of: "_", with: "")
                    .replacingOccurrences(of: "`", with: "")
                output += textContent + "\n\n"

            case .sourceTip, .semanticTip, .platformTip:
                // Strip markdown formatting for text
                let textContent = item.content
                    .replacingOccurrences(of: "_", with: "")
                    .replacingOccurrences(of: "`", with: "")
                    .replacingOccurrences(of: "**", with: "")
                output += textContent + "\n\n"

            case .custom:
                if let title = item.title {
                    output += "\(title): "
                }
                output += item.content + "\n\n"
            }
        }

        return output.trimmingCharacters(in: .newlines) + "\n"
    }
}

// MARK: - Convenience Extensions

public extension SearchFooter {
    /// Create footer for unified search (all sources)
    static func unified(showSemanticTip: Bool = true, showPlatformTip: Bool = true) -> SearchFooter {
        SearchFooter(
            currentSource: nil,
            teasers: nil,
            showSemanticTip: showSemanticTip,
            showPlatformTip: showPlatformTip
        )
    }

    /// Create footer for single-source search
    static func singleSource(
        _ source: String,
        teasers: TeaserResults? = nil,
        showSemanticTip: Bool = true,
        showPlatformTip: Bool = true
    ) -> SearchFooter {
        SearchFooter(
            currentSource: source,
            teasers: teasers,
            showSemanticTip: showSemanticTip,
            showPlatformTip: showPlatformTip
        )
    }

    /// Format as markdown
    func formatMarkdown() -> String {
        MarkdownFooterFormatter().format(makeFooter())
    }

    /// Format as plain text
    func formatText() -> String {
        TextFooterFormatter().format(makeFooter())
    }
}
