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

        // Sample results (different type, handled separately)
        if !input.sampleResults.isEmpty {
            output += "SAMPLE CODE (\(input.sampleResults.count))\n"
            output += String(repeating: "-", count: 40) + "\n"
            for project in input.sampleResults {
                output += "  \(project.title)\n"
                let desc = project.description.truncated(to: 120)
                if !desc.isEmpty {
                    output += "    \(desc)\n"
                }
                output += "    ID: \(project.id)\n"
            }
            output += "\n"
        }

        // All doc sources (unified iteration)
        for section in input.allDocSources {
            output += "\(section.displayName.uppercased()) (\(section.count))\n"
            output += String(repeating: "-", count: 40) + "\n"
            for result in section.results {
                output += "  \(result.title)\n"
                let summary = result.cleanedSummary.truncated(to: 120)
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

        if input.totalCount == 0 {
            output += "No results found across any source.\n\n"
        }

        // Footer: tips and guidance
        let footer = SearchFooter.unified()
        output += footer.formatText()

        return output
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
        let output = JSONOutput(
            query: query,
            framework: framework,
            totalCount: input.totalCount,
            documentation: input.docResults.map(DocJSONOutput.init),
            archive: input.archiveResults.map(DocJSONOutput.init),
            samples: input.sampleResults.map(SampleJSONOutput.init),
            hig: input.higResults.map(DocJSONOutput.init),
            swiftEvolution: input.swiftEvolutionResults.map(DocJSONOutput.init),
            swiftOrg: input.swiftOrgResults.map(DocJSONOutput.init),
            swiftBook: input.swiftBookResults.map(DocJSONOutput.init),
            packages: input.packagesResults.map(DocJSONOutput.init)
        )

        return encodeJSON(output)
    }
}

// MARK: - Unified JSON Output Types

private struct JSONOutput: Encodable {
    let query: String
    let framework: String?
    let totalCount: Int
    let documentation: [DocJSONOutput]
    let archive: [DocJSONOutput]
    let samples: [SampleJSONOutput]
    let hig: [DocJSONOutput]
    let swiftEvolution: [DocJSONOutput]
    let swiftOrg: [DocJSONOutput]
    let swiftBook: [DocJSONOutput]
    let packages: [DocJSONOutput]
}

private struct DocJSONOutput: Encodable {
    let title: String
    let framework: String
    let uri: String
    let availability: String?
    let summary: String

    init(from result: Search.Result) {
        title = result.title
        framework = result.framework
        uri = result.uri
        availability = result.availabilityString
        summary = result.cleanedSummary
    }
}

private struct SampleJSONOutput: Encodable {
    let id: String
    let title: String
    let frameworks: [String]
    let fileCount: Int
    let description: String

    init(from project: SampleIndex.Project) {
        id = project.id
        title = project.title
        frameworks = project.frameworks
        fileCount = project.fileCount
        description = project.description
    }
}

// MARK: - JSON Encoding Helper

private func encodeJSON(_ value: some Encodable) -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

    guard let data = try? encoder.encode(value),
          let json = String(data: data, encoding: .utf8)
    else {
        return "{\"error\": \"Failed to encode results\"}"
    }

    return json
}
