import Foundation
import Search
import Shared

// MARK: - HIG Text Formatter

/// Formats HIG search results as plain text for CLI output
public struct HIGTextFormatter: ResultFormatter {
    private let query: HIGQuery

    public init(query: HIGQuery) {
        self.query = query
    }

    public func format(_ results: [Search.Result]) -> String {
        var output = "HIG Search Results for \"\(query.text)\"\n"
        output += String(repeating: "=", count: 50) + "\n\n"

        if let platform = query.platform {
            output += "Platform: \(platform)\n"
        }
        if let category = query.category {
            output += "Category: \(category)\n"
        }
        if query.platform != nil || query.category != nil {
            output += "\n"
        }

        output += "Found \(results.count) guideline(s)\n\n"

        if results.isEmpty {
            output += "No Human Interface Guidelines found matching your query.\n\n"
            output += "Tips:\n"
            output += "- Try broader design terms (e.g., 'buttons', 'typography', 'navigation')\n"
            output += "- Specify a platform: iOS, macOS, watchOS, visionOS, tvOS\n"
            output += "- Specify a category: foundations, patterns, components, technologies, inputs\n"
            return output
        }

        for (index, result) in results.enumerated() {
            output += "\(index + 1). \(result.title)\n"
            output += "   URI: \(result.uri)\n"
            if let availability = result.availabilityString, !availability.isEmpty {
                output += "   Availability: \(availability)\n"
            }
            if !result.cleanedSummary.isEmpty {
                output += "\n   \(result.cleanedSummary)\n\n"
            } else {
                output += "\n"
            }
        }

        return output
    }
}

// MARK: - HIG JSON Formatter

/// Formats HIG search results as JSON for programmatic access
public struct HIGJSONFormatter: ResultFormatter {
    private let query: HIGQuery

    public init(query: HIGQuery) {
        self.query = query
    }

    public func format(_ results: [Search.Result]) -> String {
        struct JSONOutput: Encodable {
            let query: String
            let platform: String?
            let category: String?
            let count: Int
            let results: [HIGResult]

            struct HIGResult: Encodable {
                let title: String
                let uri: String
                let availability: String?
                let summary: String
            }
        }

        let output = JSONOutput(
            query: query.text,
            platform: query.platform,
            category: query.category,
            count: results.count,
            results: results.map { result in
                JSONOutput.HIGResult(
                    title: result.title,
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
