import Foundation
import SampleIndex
import Search
import Shared

// MARK: - Markdown Search Result Formatter

/// Formats search results as markdown for MCP tools and CLI --format markdown
public struct MarkdownSearchResultFormatter: ResultFormatter {
    private let query: String
    private let filters: SearchFilters?
    private let config: SearchResultFormatConfig
    private let teasers: TeaserResults?
    private let showPlatformTip: Bool

    public init(
        query: String,
        filters: SearchFilters? = nil,
        config: SearchResultFormatConfig = .mcpDefault,
        teasers: TeaserResults? = nil,
        showPlatformTip: Bool = true
    ) {
        self.query = query
        self.filters = filters
        self.config = config
        self.teasers = teasers
        self.showPlatformTip = showPlatformTip
    }

    public func format(_ results: [Search.Result]) -> String {
        var md = "# Search Results for \"\(query)\"\n\n"

        // Always tell the AI what source was searched
        let searchedSource = filters?.source ?? Shared.Constants.SourcePrefix.appleDocs
        md += "_Source: **\(searchedSource)**_\n\n"

        // Show other filters (not source since we just showed it)
        if let filters, filters.hasActiveFilters {
            if let framework = filters.framework {
                md += "_Filtered to framework: **\(framework)**_\n\n"
            }
            if let language = filters.language {
                md += "_Filtered to language: **\(language)**_\n\n"
            }
            if let minimumiOS = filters.minimumiOS {
                md += "_Filtered to iOS: **\(minimumiOS)+**_\n\n"
            }
            if let minimumMacOS = filters.minimumMacOS {
                md += "_Filtered to macOS: **\(minimumMacOS)+**_\n\n"
            }
            if let minimumTvOS = filters.minimumTvOS {
                md += "_Filtered to tvOS: **\(minimumTvOS)+**_\n\n"
            }
            if let minimumWatchOS = filters.minimumWatchOS {
                md += "_Filtered to watchOS: **\(minimumWatchOS)+**_\n\n"
            }
            if let minimumVisionOS = filters.minimumVisionOS {
                md += "_Filtered to visionOS: **\(minimumVisionOS)+**_\n\n"
            }
        }

        md += "Found **\(results.count)** result\(results.count == 1 ? "" : "s"):\n\n"

        if results.isEmpty {
            md += config.emptyMessage
            md += "\n\n"
            md += Shared.Constants.MCP.tipSearchCapabilities
            return md
        }

        for (index, result) in results.enumerated() {
            md += "## \(index + 1). \(result.title)\n\n"
            md += "- **Framework:** `\(result.framework)`\n"
            md += "- **URI:** `\(result.uri)`\n"

            if config.showAvailability,
               let availability = result.availabilityString, !availability.isEmpty {
                md += "- **Availability:** \(availability)\n"
            }
            if config.showScore {
                md += "- **Score:** \(String(format: "%.2f", result.score))\n"
            }
            if config.showWordCount {
                md += "- **Words:** \(result.wordCount)\n"
            }
            if config.showSource {
                md += "- **Source:** \(result.source)\n"
            }

            if !result.cleanedSummary.isEmpty {
                md += "\n\(result.cleanedSummary)\n\n"
            } else {
                md += "\n"
            }

            if config.showSeparators, index < results.count - 1 {
                md += "---\n\n"
            }
        }

        // Footer: teasers, tips, and guidance
        let footer = SearchFooter.singleSource(
            searchedSource,
            teasers: teasers,
            showPlatformTip: showPlatformTip
        )
        md += footer.formatMarkdown()

        return md
    }
}

// MARK: - HIG Markdown Formatter

/// Formats HIG search results as markdown
public struct HIGMarkdownFormatter: ResultFormatter {
    private let query: HIGQuery
    private let config: SearchResultFormatConfig
    private let teasers: TeaserResults?

    public init(
        query: HIGQuery,
        config: SearchResultFormatConfig = .mcpDefault,
        teasers: TeaserResults? = nil
    ) {
        self.query = query
        self.config = config
        self.teasers = teasers
    }

    public func format(_ results: [Search.Result]) -> String {
        var md = "# HIG Search Results for \"\(query.text)\"\n\n"

        // Tell the AI what source this is
        md += "_Source: **\(Shared.Constants.SourcePrefix.hig)**_\n\n"

        if let platform = query.platform {
            md += "_Platform: **\(platform)**_\n\n"
        }
        if let category = query.category {
            md += "_Category: **\(category)**_\n\n"
        }

        md += "Found **\(results.count)** guideline\(results.count == 1 ? "" : "s"):\n\n"

        if results.isEmpty {
            md += "_No Human Interface Guidelines found matching your query._\n\n"
            md += "**Tips:**\n"
            md += "- Try broader design terms (e.g., 'buttons', 'typography', 'navigation')\n"
            md += "- Specify a platform: iOS, macOS, watchOS, visionOS, tvOS\n"
            md += "- Specify a category: foundations, patterns, components, technologies, inputs\n\n"
            md += Shared.Constants.MCP.tipSearchCapabilities
            return md
        }

        for (index, result) in results.enumerated() {
            md += "## \(index + 1). \(result.title)\n\n"
            md += "- **URI:** `\(result.uri)`\n"

            if config.showAvailability,
               let availability = result.availabilityString, !availability.isEmpty {
                md += "- **Availability:** \(availability)\n"
            }
            if config.showScore {
                md += "- **Score:** \(String(format: "%.2f", result.score))\n"
            }

            if !result.cleanedSummary.isEmpty {
                md += "\n\(result.cleanedSummary)\n\n"
            } else {
                md += "\n"
            }

            if config.showSeparators, index < results.count - 1 {
                md += "---\n\n"
            }
        }

        // Footer: tips and guidance
        let footer = SearchFooter.singleSource(
            Shared.Constants.SourcePrefix.hig,
            teasers: teasers
        )
        md += footer.formatMarkdown()

        return md
    }
}

// MARK: - Frameworks Markdown Formatter

/// Formats framework list as markdown
public struct FrameworksMarkdownFormatter: ResultFormatter {
    private let totalDocs: Int

    public init(totalDocs: Int) {
        self.totalDocs = totalDocs
    }

    public func format(_ frameworks: [String: Int]) -> String {
        var md = "# Available Frameworks\n\n"
        md += "Total documents: **\(totalDocs)**\n\n"

        if frameworks.isEmpty {
            let cmd = "\(Shared.Constants.App.commandName) \(Shared.Constants.Command.buildIndex)"
            md += Shared.Constants.MCP.messageNoFrameworks(buildIndexCommand: cmd)
            return md
        }

        md += "| Framework | Documents |\n"
        md += "|-----------|----------:|\n"

        // Sort by document count (descending)
        for (framework, count) in frameworks.sorted(by: { $0.value > $1.value }) {
            md += "| `\(framework)` | \(count) |\n"
        }

        // Footer: tips and guidance
        let footer = SearchFooter.singleSource(Shared.Constants.SourcePrefix.appleDocs)
        md += footer.formatMarkdown()

        return md
    }
}

// MARK: - Unified Search Markdown Formatter

/// Input data for unified search formatting - includes ALL sources
public struct UnifiedSearchInput: Sendable {
    public let docResults: [Search.Result]
    public let archiveResults: [Search.Result]
    public let sampleResults: [SampleIndex.Project]
    public let higResults: [Search.Result]
    public let swiftEvolutionResults: [Search.Result]
    public let swiftOrgResults: [Search.Result]
    public let swiftBookResults: [Search.Result]
    public let packagesResults: [Search.Result]

    public init(
        docResults: [Search.Result] = [],
        archiveResults: [Search.Result] = [],
        sampleResults: [SampleIndex.Project] = [],
        higResults: [Search.Result] = [],
        swiftEvolutionResults: [Search.Result] = [],
        swiftOrgResults: [Search.Result] = [],
        swiftBookResults: [Search.Result] = [],
        packagesResults: [Search.Result] = []
    ) {
        self.docResults = docResults
        self.archiveResults = archiveResults
        self.sampleResults = sampleResults
        self.higResults = higResults
        self.swiftEvolutionResults = swiftEvolutionResults
        self.swiftOrgResults = swiftOrgResults
        self.swiftBookResults = swiftBookResults
        self.packagesResults = packagesResults
    }

    /// Total number of results across all sources
    public var totalCount: Int {
        docResults.count + archiveResults.count + sampleResults.count +
            higResults.count + swiftEvolutionResults.count + swiftOrgResults.count +
            swiftBookResults.count + packagesResults.count
    }

    /// Represents a doc source section for iteration
    public struct DocSourceSection: Sendable {
        public let displayName: String
        public let emoji: String
        public let results: [Search.Result]

        public var isEmpty: Bool { results.isEmpty }
        public var count: Int { results.count }
    }

    /// Returns all non-empty doc sources for iteration (excludes samples which have different type)
    public var allDocSources: [DocSourceSection] {
        typealias Prefix = Shared.Constants.SourcePrefix
        var sections: [DocSourceSection] = []

        if !docResults.isEmpty {
            sections.append(DocSourceSection(
                displayName: "Apple Documentation",
                emoji: Prefix.emojiAppleDocs,
                results: docResults
            ))
        }
        if !higResults.isEmpty {
            sections.append(DocSourceSection(
                displayName: "Human Interface Guidelines",
                emoji: Prefix.emojiHIG,
                results: higResults
            ))
        }
        if !archiveResults.isEmpty {
            sections.append(DocSourceSection(
                displayName: "Apple Archive",
                emoji: Prefix.emojiArchive,
                results: archiveResults
            ))
        }
        if !swiftEvolutionResults.isEmpty {
            sections.append(DocSourceSection(
                displayName: "Swift Evolution",
                emoji: Prefix.emojiSwiftEvolution,
                results: swiftEvolutionResults
            ))
        }
        if !swiftOrgResults.isEmpty {
            sections.append(DocSourceSection(
                displayName: "Swift.org",
                emoji: Prefix.emojiSwiftOrg,
                results: swiftOrgResults
            ))
        }
        if !swiftBookResults.isEmpty {
            sections.append(DocSourceSection(
                displayName: "Swift Book",
                emoji: Prefix.emojiSwiftBook,
                results: swiftBookResults
            ))
        }
        if !packagesResults.isEmpty {
            sections.append(DocSourceSection(
                displayName: "Swift Packages",
                emoji: Prefix.emojiPackages,
                results: packagesResults
            ))
        }

        return sections
    }
}

/// Formats unified search results (ALL sources) as markdown
public struct UnifiedSearchMarkdownFormatter: ResultFormatter {
    private let query: String
    private let framework: String?
    private let config: SearchResultFormatConfig

    public init(
        query: String,
        framework: String? = nil,
        config: SearchResultFormatConfig = .mcpDefault
    ) {
        self.query = query
        self.framework = framework
        self.config = config
    }

    public func format(_ input: UnifiedSearchInput) -> String {
        var md = "# Unified Search: \"\(query)\"\n\n"

        if let framework {
            md += "_Filtered to framework: **\(framework)**_\n\n"
        }

        // Tell the AI exactly what sources were searched
        md += "_Searched ALL sources: \(Shared.Constants.MCP.availableSources.joined(separator: ", "))_\n\n"

        md += "**Total: \(input.totalCount) results across all sources**\n\n"

        // Sample Code (different type, handled separately)
        if !input.sampleResults.isEmpty {
            md += "## \(Shared.Constants.SourcePrefix.emojiSamples) Sample Code (\(input.sampleResults.count))\n\n"
            md += formatSampleResults(input.sampleResults)
        }

        // All doc sources (unified iteration)
        for section in input.allDocSources {
            md += "## \(section.emoji) \(section.displayName) (\(section.count))\n\n"
            md += formatDocResults(section.results)
        }

        // Show message if no results at all
        if input.totalCount == 0 {
            md += "_No results found across any source._\n\n"
        }

        // Footer: tips and guidance
        let footer = SearchFooter.unified()
        md += footer.formatMarkdown()

        return md
    }

    private func formatDocResults(_ results: [Search.Result]) -> String {
        var md = ""
        for result in results {
            md += "- **\(result.title)**\n"
            let summary = result.cleanedSummary.truncated(to: 150)
            if !summary.isEmpty {
                md += "  - \(summary)\n"
            }
            md += "  - URI: `\(result.uri)`\n"
            if config.showAvailability,
               let availability = result.availabilityString, !availability.isEmpty {
                md += "  - Availability: \(availability)\n"
            }
        }
        md += "\n"
        return md
    }

    private func formatSampleResults(_ projects: [SampleIndex.Project]) -> String {
        var md = ""
        for project in projects {
            md += "- **\(project.title)**\n"
            let desc = project.description.truncated(to: 150)
            if !desc.isEmpty {
                md += "  - \(desc)\n"
            }
            md += "  - ID: `\(project.id)`\n"
            md += "  - Frameworks: \(project.frameworks.joined(separator: ", "))\n"
        }
        md += "\n"
        return md
    }
}
