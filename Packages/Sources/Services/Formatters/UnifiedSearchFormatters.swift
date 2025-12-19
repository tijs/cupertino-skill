import Foundation
import SampleIndex
import Search
import Shared

// MARK: - Text Formatter for Unified Search

/// Formats unified search results as plain text for CLI output
public struct UnifiedSearchTextFormatter: ResultFormatter {
    private let query: String
    private let framework: String?
    private let config: SearchResultFormatConfig

    public init(query: String, framework: String?, config: SearchResultFormatConfig = .cliDefault) {
        self.query = query
        self.framework = framework
        self.config = config
    }

    public func format(_ input: UnifiedSearchInput) -> String {
        var output = "Unified Search Results for \"\(query)\"\n"
        output += String(repeating: "=", count: 50) + "\n\n"

        if let framework {
            output += "Filtered to framework: \(framework)\n\n"
        }

        output += "Total: \(input.totalCount) results across all sources\n\n"

        // Only show sections with results
        if !input.docResults.isEmpty {
            output += "APPLE DOCUMENTATION (\(input.docResults.count))\n"
            output += String(repeating: "-", count: 40) + "\n"
            for result in input.docResults {
                output += "  \(result.title)\n"
                let summary = truncate(result.cleanedSummary)
                if !summary.isEmpty {
                    output += "    \(summary)\n"
                }
                output += "    URI: \(result.uri)\n"
                if config.showAvailability,
                   let availability = result.availabilityString, !availability.isEmpty {
                    output += "    Availability: \(availability)\n"
                }
            }
            output += "\n"
        }

        if !input.sampleResults.isEmpty {
            output += "SAMPLE CODE (\(input.sampleResults.count))\n"
            output += String(repeating: "-", count: 40) + "\n"
            for project in input.sampleResults {
                output += "  \(project.title)\n"
                let desc = truncate(project.description)
                if !desc.isEmpty {
                    output += "    \(desc)\n"
                }
                output += "    ID: \(project.id)\n"
            }
            output += "\n"
        }

        if !input.higResults.isEmpty {
            output += "HUMAN INTERFACE GUIDELINES (\(input.higResults.count))\n"
            output += String(repeating: "-", count: 40) + "\n"
            for result in input.higResults {
                output += "  \(result.title)\n"
                let summary = truncate(result.cleanedSummary)
                if !summary.isEmpty {
                    output += "    \(summary)\n"
                }
                output += "    URI: \(result.uri)\n"
            }
            output += "\n"
        }

        if !input.archiveResults.isEmpty {
            output += "APPLE ARCHIVE (\(input.archiveResults.count))\n"
            output += String(repeating: "-", count: 40) + "\n"
            for result in input.archiveResults {
                output += "  \(result.title)\n"
                let summary = truncate(result.cleanedSummary)
                if !summary.isEmpty {
                    output += "    \(summary)\n"
                }
                output += "    URI: \(result.uri)\n"
            }
            output += "\n"
        }

        if !input.swiftEvolutionResults.isEmpty {
            output += "SWIFT EVOLUTION (\(input.swiftEvolutionResults.count))\n"
            output += String(repeating: "-", count: 40) + "\n"
            for result in input.swiftEvolutionResults {
                output += "  \(result.title)\n"
                let summary = truncate(result.cleanedSummary)
                if !summary.isEmpty {
                    output += "    \(summary)\n"
                }
                output += "    URI: \(result.uri)\n"
            }
            output += "\n"
        }

        if !input.swiftOrgResults.isEmpty {
            output += "SWIFT.ORG (\(input.swiftOrgResults.count))\n"
            output += String(repeating: "-", count: 40) + "\n"
            for result in input.swiftOrgResults {
                output += "  \(result.title)\n"
                let summary = truncate(result.cleanedSummary)
                if !summary.isEmpty {
                    output += "    \(summary)\n"
                }
                output += "    URI: \(result.uri)\n"
            }
            output += "\n"
        }

        if !input.swiftBookResults.isEmpty {
            output += "SWIFT BOOK (\(input.swiftBookResults.count))\n"
            output += String(repeating: "-", count: 40) + "\n"
            for result in input.swiftBookResults {
                output += "  \(result.title)\n"
                let summary = truncate(result.cleanedSummary)
                if !summary.isEmpty {
                    output += "    \(summary)\n"
                }
                output += "    URI: \(result.uri)\n"
            }
            output += "\n"
        }

        if !input.packagesResults.isEmpty {
            output += "SWIFT PACKAGES (\(input.packagesResults.count))\n"
            output += String(repeating: "-", count: 40) + "\n"
            for result in input.packagesResults {
                output += "  \(result.title)\n"
                let summary = truncate(result.cleanedSummary)
                if !summary.isEmpty {
                    output += "    \(summary)\n"
                }
                output += "    URI: \(result.uri)\n"
            }
            output += "\n"
        }

        if input.totalCount == 0 {
            output += "No results found across any source.\n\n"
        }

        // Footer: tips and guidance
        let footer = SearchFooter.unified()
        output += footer.formatText()

        return output
    }

    private func truncate(_ text: String, max: Int = 120) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count > max ? String(trimmed.prefix(max)) + "..." : trimmed
    }
}

// MARK: - JSON Formatter for Unified Search

/// Formats unified search results as JSON for programmatic access
public struct UnifiedSearchJSONFormatter: ResultFormatter {
    private let query: String
    private let framework: String?

    public init(query: String, framework: String?) {
        self.query = query
        self.framework = framework
    }

    public func format(_ input: UnifiedSearchInput) -> String {
        struct JSONOutput: Encodable {
            let query: String
            let framework: String?
            let totalCount: Int
            let documentation: [DocResult]
            let archive: [DocResult]
            let samples: [SampleResult]
            let hig: [DocResult]
            let swiftEvolution: [DocResult]
            let swiftOrg: [DocResult]
            let swiftBook: [DocResult]
            let packages: [DocResult]

            struct DocResult: Encodable {
                let title: String
                let framework: String
                let uri: String
                let availability: String?
                let summary: String
            }

            struct SampleResult: Encodable {
                let id: String
                let title: String
                let frameworks: [String]
                let fileCount: Int
                let description: String
            }
        }

        let output = JSONOutput(
            query: query,
            framework: framework,
            totalCount: input.totalCount,
            documentation: input.docResults.map { result in
                JSONOutput.DocResult(
                    title: result.title,
                    framework: result.framework,
                    uri: result.uri,
                    availability: result.availabilityString,
                    summary: result.cleanedSummary
                )
            },
            archive: input.archiveResults.map { result in
                JSONOutput.DocResult(
                    title: result.title,
                    framework: result.framework,
                    uri: result.uri,
                    availability: result.availabilityString,
                    summary: result.cleanedSummary
                )
            },
            samples: input.sampleResults.map { project in
                JSONOutput.SampleResult(
                    id: project.id,
                    title: project.title,
                    frameworks: project.frameworks,
                    fileCount: project.fileCount,
                    description: project.description
                )
            },
            hig: input.higResults.map { result in
                JSONOutput.DocResult(
                    title: result.title,
                    framework: result.framework,
                    uri: result.uri,
                    availability: result.availabilityString,
                    summary: result.cleanedSummary
                )
            },
            swiftEvolution: input.swiftEvolutionResults.map { result in
                JSONOutput.DocResult(
                    title: result.title,
                    framework: result.framework,
                    uri: result.uri,
                    availability: result.availabilityString,
                    summary: result.cleanedSummary
                )
            },
            swiftOrg: input.swiftOrgResults.map { result in
                JSONOutput.DocResult(
                    title: result.title,
                    framework: result.framework,
                    uri: result.uri,
                    availability: result.availabilityString,
                    summary: result.cleanedSummary
                )
            },
            swiftBook: input.swiftBookResults.map { result in
                JSONOutput.DocResult(
                    title: result.title,
                    framework: result.framework,
                    uri: result.uri,
                    availability: result.availabilityString,
                    summary: result.cleanedSummary
                )
            },
            packages: input.packagesResults.map { result in
                JSONOutput.DocResult(
                    title: result.title,
                    framework: result.framework,
                    uri: result.uri,
                    availability: result.availabilityString,
                    summary: result.cleanedSummary
                )
            }
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        guard let data = try? encoder.encode(output),
              let json = String(data: data, encoding: .utf8)
        else {
            return "{\"error\": \"Failed to encode results\"}"
        }

        return json
    }
}
