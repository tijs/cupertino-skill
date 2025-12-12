import Foundation
import MCP
import SampleIndex
import Search
import Shared

// MARK: - Unified Cupertino Tool Provider

/// Composite tool provider that delegates to both documentation and sample code providers
public actor CompositeToolProvider: ToolProvider {
    private let documentationTools: DocumentationToolProvider?
    private let sampleCodeTools: SampleCodeToolProvider?
    private let searchIndex: Search.Index?
    private let sampleDatabase: SampleIndex.Database?

    public init(searchIndex: Search.Index?, sampleDatabase: SampleIndex.Database?) {
        self.searchIndex = searchIndex
        self.sampleDatabase = sampleDatabase
        documentationTools = searchIndex.map { DocumentationToolProvider(searchIndex: $0) }
        sampleCodeTools = sampleDatabase.map { SampleCodeToolProvider(database: $0) }
    }

    // MARK: - ToolProvider

    public func listTools(cursor: String?) async throws -> ListToolsResult {
        var allTools: [Tool] = []

        // Add search_all unified tool (always available if we have at least one index)
        if searchIndex != nil || sampleDatabase != nil {
            allTools.append(Tool(
                name: Shared.Constants.MCP.toolSearchAll,
                description: Shared.Constants.MCP.toolSearchAllDescription,
                inputSchema: JSONSchema(
                    type: Shared.Constants.MCP.schemaTypeObject,
                    properties: nil,
                    required: [Shared.Constants.MCP.schemaParamQuery]
                )
            ))
        }

        // Get tools from documentation provider
        if let documentationTools {
            let docTools = try await documentationTools.listTools(cursor: cursor)
            allTools.append(contentsOf: docTools.tools)
        }

        // Get tools from sample code provider
        if let sampleCodeTools {
            let sampleTools = try await sampleCodeTools.listTools(cursor: cursor)
            allTools.append(contentsOf: sampleTools.tools)
        }

        return ListToolsResult(tools: allTools)
    }

    public func callTool(name: String, arguments: [String: AnyCodable]?) async throws -> CallToolResult {
        // Handle search_all directly
        if name == Shared.Constants.MCP.toolSearchAll {
            return try await handleSearchAll(arguments: arguments)
        }

        // Try documentation provider first
        if let documentationTools {
            let docTools = try await documentationTools.listTools(cursor: nil)
            if docTools.tools.contains(where: { $0.name == name }) {
                return try await documentationTools.callTool(name: name, arguments: arguments)
            }
        }

        // Try sample code provider next
        if let sampleCodeTools {
            let sampleTools = try await sampleCodeTools.listTools(cursor: nil)
            if sampleTools.tools.contains(where: { $0.name == name }) {
                return try await sampleCodeTools.callTool(name: name, arguments: arguments)
            }
        }

        // Tool not found in any provider
        throw ToolError.unknownTool(name)
    }

    // MARK: - Unified Search Handler

    private func handleSearchAll(arguments: [String: AnyCodable]?) async throws -> CallToolResult {
        let args = ArgumentExtractor(arguments)
        let query: String = try args.require(Shared.Constants.MCP.schemaParamQuery)
        let framework = args.optional(Shared.Constants.MCP.schemaParamFramework)
        let limit = args.limit(default: 10)

        var markdown = "# Unified Search: \"\(query)\"\n\n"

        if let framework {
            markdown += "_Filtered to framework: **\(framework)**_\n\n"
        }

        // Section 1: Modern Apple Documentation
        if let searchIndex {
            let docsResults = try await searchIndex.search(
                query: query,
                source: nil,
                framework: framework,
                language: nil,
                limit: limit,
                includeArchive: false
            )

            markdown += "## 📚 Apple Documentation (\(docsResults.count) results)\n\n"

            if docsResults.isEmpty {
                markdown += "_No results in modern documentation._\n\n"
            } else {
                for (index, result) in docsResults.enumerated() {
                    markdown += "### \(index + 1). \(result.title)\n"
                    markdown += "- **URI:** `\(result.uri)`\n"
                    markdown += "- **Framework:** `\(result.framework)`\n"
                    if let availability = result.availabilityString, !availability.isEmpty {
                        markdown += "- **Availability:** \(availability)\n"
                    }
                    markdown += "\n\(result.summary)\n\n"
                }
            }
        }

        // Section 2: Apple Archive (Legacy Guides)
        if let searchIndex {
            let archiveResults = try await searchIndex.search(
                query: query,
                source: Shared.Constants.SourcePrefix.appleArchive,
                framework: framework,
                language: nil,
                limit: limit,
                includeArchive: true
            )

            markdown += "## 📜 Apple Archive Legacy Guides (\(archiveResults.count) results)\n\n"

            if archiveResults.isEmpty {
                markdown += "_No results in archive guides._\n\n"
            } else {
                for (index, result) in archiveResults.enumerated() {
                    markdown += "### \(index + 1). \(result.title)\n"
                    markdown += "- **URI:** `\(result.uri)`\n"
                    markdown += "- **Framework:** `\(result.framework)`\n"
                    markdown += "\n\(result.summary)\n\n"
                }
            }
        }

        // Section 3: Sample Code Projects
        if let sampleDatabase {
            let sampleResults = try await sampleDatabase.searchProjects(
                query: query,
                framework: framework,
                limit: limit
            )

            markdown += "## 💻 Sample Code Projects (\(sampleResults.count) results)\n\n"

            if sampleResults.isEmpty {
                markdown += "_No matching sample projects._\n\n"
            } else {
                for (index, project) in sampleResults.enumerated() {
                    markdown += "### \(index + 1). \(project.title)\n"
                    markdown += "- **ID:** `\(project.id)`\n"
                    markdown += "- **Frameworks:** \(project.frameworks.joined(separator: ", "))\n"
                    markdown += "- **Files:** \(project.fileCount)\n"
                    if !project.description.isEmpty {
                        markdown += "\n\(project.description)\n"
                    }
                    markdown += "\n"
                }
            }
        }

        markdown += "---\n\n"
        markdown += "💡 **Tips:**\n"
        markdown += "- Use `read_document` with URI to read full documentation\n"
        markdown += "- Use `read_sample` with project ID to see sample code details\n"
        markdown += "- Use `read_sample_file` to view specific source files\n"

        let content = ContentBlock.text(TextContent(text: markdown))
        return CallToolResult(content: [content])
    }
}
