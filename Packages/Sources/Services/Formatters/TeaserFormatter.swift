import Foundation
import SampleIndex
import Search
import Shared

// MARK: - Teaser Results

/// Container for teaser results from alternate sources.
/// Used by both MCP and CLI to show hints about other sources.
public struct TeaserResults: Sendable {
    public var appleDocs: [Search.Result]
    public var samples: [SampleIndex.Project]
    public var archive: [Search.Result]
    public var hig: [Search.Result]
    public var swiftEvolution: [Search.Result]
    public var swiftOrg: [Search.Result]
    public var swiftBook: [Search.Result]
    public var packages: [Search.Result]

    public init(
        appleDocs: [Search.Result] = [],
        samples: [SampleIndex.Project] = [],
        archive: [Search.Result] = [],
        hig: [Search.Result] = [],
        swiftEvolution: [Search.Result] = [],
        swiftOrg: [Search.Result] = [],
        swiftBook: [Search.Result] = [],
        packages: [Search.Result] = []
    ) {
        self.appleDocs = appleDocs
        self.samples = samples
        self.archive = archive
        self.hig = hig
        self.swiftEvolution = swiftEvolution
        self.swiftOrg = swiftOrg
        self.swiftBook = swiftBook
        self.packages = packages
    }

    /// Whether there are any teaser results
    public var isEmpty: Bool {
        appleDocs.isEmpty && samples.isEmpty && archive.isEmpty && hig.isEmpty &&
            swiftEvolution.isEmpty && swiftOrg.isEmpty &&
            swiftBook.isEmpty && packages.isEmpty
    }
}

// MARK: - Teaser Markdown Formatter

/// Formats teaser results as markdown.
/// Shared by both MCP and CLI for consistent output.
public struct TeaserMarkdownFormatter {
    public init() {}

    /// Format teaser results as markdown sections
    public func format(_ teasers: TeaserResults) -> String {
        var output = ""

        // Apple Documentation teaser
        if !teasers.appleDocs.isEmpty {
            output += "\n\n---\n\n"
            output += "\(Shared.Constants.SourcePrefix.emojiAppleDocs) **Also in Apple Documentation:**\n"
            for result in teasers.appleDocs {
                output += "- \(result.title)\n"
            }
            output += "\n_→ Use `source: \(Shared.Constants.SourcePrefix.appleDocs)`_"
        }

        // Sample code teaser
        if !teasers.samples.isEmpty {
            output += "\n\n---\n\n"
            output += "\(Shared.Constants.SourcePrefix.emojiSamples) **Also in Sample Code:**\n"
            for project in teasers.samples {
                output += "- \(project.title)\n"
            }
            output += "\n_→ Use `source: \(Shared.Constants.SourcePrefix.samples)`_"
        }

        // Archive teaser
        if !teasers.archive.isEmpty {
            output += "\n\n---\n\n"
            output += "\(Shared.Constants.SourcePrefix.emojiArchive) **Also in Apple Archive:**\n"
            for result in teasers.archive {
                output += "- \(result.title)\n"
            }
            output += "\n_→ Use `source: \(Shared.Constants.SourcePrefix.appleArchive)`_"
        }

        // HIG teaser
        if !teasers.hig.isEmpty {
            output += "\n\n---\n\n"
            output += "\(Shared.Constants.SourcePrefix.emojiHIG) **Also in Human Interface Guidelines:**\n"
            for result in teasers.hig {
                output += "- \(result.title)\n"
            }
            output += "\n_→ Use `source: \(Shared.Constants.SourcePrefix.hig)`_"
        }

        // Swift Evolution teaser
        if !teasers.swiftEvolution.isEmpty {
            output += "\n\n---\n\n"
            output += "\(Shared.Constants.SourcePrefix.emojiSwiftEvolution) **Also in Swift Evolution:**\n"
            for result in teasers.swiftEvolution {
                output += "- \(result.title)\n"
            }
            output += "\n_→ Use `source: \(Shared.Constants.SourcePrefix.swiftEvolution)`_"
        }

        // Swift.org teaser
        if !teasers.swiftOrg.isEmpty {
            output += "\n\n---\n\n"
            output += "\(Shared.Constants.SourcePrefix.emojiSwiftOrg) **Also in Swift.org:**\n"
            for result in teasers.swiftOrg {
                output += "- \(result.title)\n"
            }
            output += "\n_→ Use `source: \(Shared.Constants.SourcePrefix.swiftOrg)`_"
        }

        // Swift Book teaser
        if !teasers.swiftBook.isEmpty {
            output += "\n\n---\n\n"
            output += "\(Shared.Constants.SourcePrefix.emojiSwiftBook) **Also in Swift Book:**\n"
            for result in teasers.swiftBook {
                output += "- \(result.title)\n"
            }
            output += "\n_→ Use `source: \(Shared.Constants.SourcePrefix.swiftBook)`_"
        }

        // Packages teaser
        if !teasers.packages.isEmpty {
            output += "\n\n---\n\n"
            output += "\(Shared.Constants.SourcePrefix.emojiPackages) **Also in Swift Packages:**\n"
            for result in teasers.packages {
                output += "- \(result.title)\n"
            }
            output += "\n_→ Use `source: \(Shared.Constants.SourcePrefix.packages)`_"
        }

        return output
    }
}

// MARK: - Teaser Text Formatter

/// Formats teaser section for CLI text output
public struct TeaserTextFormatter {
    public init() {}

    public func format(_ teasers: TeaserResults) -> String {
        var output = ""

        // Apple Documentation teaser
        if !teasers.appleDocs.isEmpty {
            output += "\n" + String(repeating: "-", count: 40) + "\n"
            output += "Also in Apple Documentation:\n"
            for result in teasers.appleDocs {
                output += "  \u{2022} \(result.title)\n"
            }
            output += "  \u{2192} Use --source \(Shared.Constants.SourcePrefix.appleDocs)\n"
        }

        // Sample code teaser
        if !teasers.samples.isEmpty {
            output += "\n" + String(repeating: "-", count: 40) + "\n"
            output += "Also in Sample Code:\n"
            for project in teasers.samples {
                output += "  \u{2022} \(project.title)\n"
            }
            output += "  \u{2192} Use --source \(Shared.Constants.SourcePrefix.samples)\n"
        }

        // Archive teaser
        if !teasers.archive.isEmpty {
            output += "\n" + String(repeating: "-", count: 40) + "\n"
            output += "Also in Apple Archive:\n"
            for result in teasers.archive {
                output += "  \u{2022} \(result.title)\n"
            }
            output += "  \u{2192} Use --source \(Shared.Constants.SourcePrefix.appleArchive)\n"
        }

        // HIG teaser
        if !teasers.hig.isEmpty {
            output += "\n" + String(repeating: "-", count: 40) + "\n"
            output += "Also in Human Interface Guidelines:\n"
            for result in teasers.hig {
                output += "  \u{2022} \(result.title)\n"
            }
            output += "  \u{2192} Use --source \(Shared.Constants.SourcePrefix.hig)\n"
        }

        // Swift Evolution teaser
        if !teasers.swiftEvolution.isEmpty {
            output += "\n" + String(repeating: "-", count: 40) + "\n"
            output += "Also in Swift Evolution:\n"
            for result in teasers.swiftEvolution {
                output += "  \u{2022} \(result.title)\n"
            }
            output += "  \u{2192} Use --source \(Shared.Constants.SourcePrefix.swiftEvolution)\n"
        }

        // Swift.org teaser
        if !teasers.swiftOrg.isEmpty {
            output += "\n" + String(repeating: "-", count: 40) + "\n"
            output += "Also in Swift.org:\n"
            for result in teasers.swiftOrg {
                output += "  \u{2022} \(result.title)\n"
            }
            output += "  \u{2192} Use --source \(Shared.Constants.SourcePrefix.swiftOrg)\n"
        }

        // Swift Book teaser
        if !teasers.swiftBook.isEmpty {
            output += "\n" + String(repeating: "-", count: 40) + "\n"
            output += "Also in Swift Book:\n"
            for result in teasers.swiftBook {
                output += "  \u{2022} \(result.title)\n"
            }
            output += "  \u{2192} Use --source \(Shared.Constants.SourcePrefix.swiftBook)\n"
        }

        // Packages teaser
        if !teasers.packages.isEmpty {
            output += "\n" + String(repeating: "-", count: 40) + "\n"
            output += "Also in Swift Packages:\n"
            for result in teasers.packages {
                output += "  \u{2022} \(result.title)\n"
            }
            output += "  \u{2192} Use --source \(Shared.Constants.SourcePrefix.packages)\n"
        }

        return output
    }
}
