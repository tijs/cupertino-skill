import Foundation
import MCP
import SampleIndex
import Search
import Shared

// MARK: - Unified Cupertino Tool Provider

/// Unified tool provider that exposes both documentation and sample code search tools
public actor CupertinoUnifiedToolProvider: ToolProvider {
    private let searchIndex: Search.Index?
    private let sampleDatabase: SampleIndex.Database?

    public init(searchIndex: Search.Index?, sampleDatabase: SampleIndex.Database?) {
        self.searchIndex = searchIndex
        self.sampleDatabase = sampleDatabase
    }

    // MARK: - ToolProvider

    public func listTools(cursor: String?) async throws -> ListToolsResult {
        var tools: [Tool] = []

        // Add documentation search tools if search index is available
        if searchIndex != nil {
            tools.append(contentsOf: [
                Tool(
                    name: Shared.Constants.MCP.toolSearchDocs,
                    description: Shared.Constants.MCP.toolSearchDocsDescription,
                    inputSchema: JSONSchema(
                        type: Shared.Constants.MCP.schemaTypeObject,
                        properties: nil,
                        required: [Shared.Constants.MCP.schemaParamQuery]
                    )
                ),
                Tool(
                    name: Shared.Constants.MCP.toolListFrameworks,
                    description: Shared.Constants.MCP.toolListFrameworksDescription,
                    inputSchema: JSONSchema(
                        type: Shared.Constants.MCP.schemaTypeObject,
                        properties: [:],
                        required: []
                    )
                ),
                Tool(
                    name: Shared.Constants.MCP.toolReadDocument,
                    description: Shared.Constants.MCP.toolReadDocumentDescription,
                    inputSchema: JSONSchema(
                        type: Shared.Constants.MCP.schemaTypeObject,
                        properties: nil,
                        required: [Shared.Constants.MCP.schemaParamURI]
                    )
                ),
            ])
        }

        // Add sample code search tools if sample database is available
        if sampleDatabase != nil {
            tools.append(contentsOf: [
                Tool(
                    name: Shared.Constants.MCP.toolSearchSamples,
                    description: Shared.Constants.MCP.toolSearchSamplesDescription,
                    inputSchema: JSONSchema(
                        type: Shared.Constants.MCP.schemaTypeObject,
                        properties: nil,
                        required: [Shared.Constants.MCP.schemaParamQuery]
                    )
                ),
                Tool(
                    name: Shared.Constants.MCP.toolListSamples,
                    description: Shared.Constants.MCP.toolListSamplesDescription,
                    inputSchema: JSONSchema(
                        type: Shared.Constants.MCP.schemaTypeObject,
                        properties: [:],
                        required: []
                    )
                ),
                Tool(
                    name: Shared.Constants.MCP.toolReadSample,
                    description: Shared.Constants.MCP.toolReadSampleDescription,
                    inputSchema: JSONSchema(
                        type: Shared.Constants.MCP.schemaTypeObject,
                        properties: nil,
                        required: [Shared.Constants.MCP.schemaParamProjectId]
                    )
                ),
                Tool(
                    name: Shared.Constants.MCP.toolReadSampleFile,
                    description: Shared.Constants.MCP.toolReadSampleFileDescription,
                    inputSchema: JSONSchema(
                        type: Shared.Constants.MCP.schemaTypeObject,
                        properties: nil,
                        required: [
                            Shared.Constants.MCP.schemaParamProjectId,
                            Shared.Constants.MCP.schemaParamFilePath,
                        ]
                    )
                ),
            ])
        }

        return ListToolsResult(tools: tools)
    }

    public func callTool(name: String, arguments: [String: AnyCodable]?) async throws -> CallToolResult {
        // Route to documentation search handlers
        switch name {
        case Shared.Constants.MCP.toolSearchDocs:
            return try await handleSearchDocs(arguments: arguments)
        case Shared.Constants.MCP.toolListFrameworks:
            return try await handleListFrameworks()
        case Shared.Constants.MCP.toolReadDocument:
            return try await handleReadDocument(arguments: arguments)
        case Shared.Constants.MCP.toolSearchSamples:
            return try await handleSearchSamples(arguments: arguments)
        case Shared.Constants.MCP.toolListSamples:
            return try await handleListSamples(arguments: arguments)
        case Shared.Constants.MCP.toolReadSample:
            return try await handleReadSample(arguments: arguments)
        case Shared.Constants.MCP.toolReadSampleFile:
            return try await handleReadSampleFile(arguments: arguments)
        default:
            throw ToolError.unknownTool(name)
        }
    }

    // MARK: - Documentation Search Tool Handlers

    private func handleSearchDocs(arguments: [String: AnyCodable]?) async throws -> CallToolResult {
        guard let searchIndex else {
            throw ToolError.indexNotAvailable("Documentation search index not available. Run 'cupertino data index' to create it.")
        }

        guard let query = arguments?[Shared.Constants.MCP.schemaParamQuery]?.value as? String else {
            throw ToolError.missingArgument(Shared.Constants.MCP.schemaParamQuery)
        }

        let source = arguments?[Shared.Constants.MCP.schemaParamSource]?.value as? String
        let framework = arguments?[Shared.Constants.MCP.schemaParamFramework]?.value as? String
        let language = arguments?[Shared.Constants.MCP.schemaParamLanguage]?.value as? String
        let defaultLimit = Shared.Constants.Limit.defaultSearchLimit
        let requestedLimit = (arguments?[Shared.Constants.MCP.schemaParamLimit]?.value as? Int) ?? defaultLimit
        let limit = min(requestedLimit, Shared.Constants.Limit.maxSearchLimit)

        let includeArchive = (arguments?[Shared.Constants.MCP.schemaParamIncludeArchive]?.value as? Bool) ?? false

        let results = try await searchIndex.search(
            query: query,
            source: source,
            framework: framework,
            language: language,
            limit: limit,
            includeArchive: includeArchive
        )

        var markdown = "# Search Results for \"\(query)\"\n\n"

        if let source {
            markdown += "_Filtered to source: **\(source)**_\n\n"
        }
        if let framework {
            markdown += "_Filtered to framework: **\(framework)**_\n\n"
        }
        if let language {
            markdown += "_Filtered to language: **\(language)**_\n\n"
        }

        markdown += "Found **\(results.count)** result\(results.count == 1 ? "" : "s"):\n\n"

        if results.isEmpty {
            markdown += Shared.Constants.MCP.messageNoResults
        } else {
            for (index, result) in results.enumerated() {
                markdown += "## \(index + 1). \(result.title)\n\n"
                markdown += "- **Framework:** `\(result.framework)`\n"
                markdown += "- **URI:** `\(result.uri)`\n"
                markdown += "- **Score:** \(String(format: Shared.Constants.MCP.formatScore, result.score))\n"
                markdown += "- **Words:** \(result.wordCount)\n\n"

                markdown += result.summary
                markdown += "\n\n"

                if index < results.count - 1 {
                    markdown += "---\n\n"
                }
            }

            markdown += "\n\n"
            markdown += Shared.Constants.MCP.tipUseResourcesRead
            markdown += "\n"
        }

        let content = ContentBlock.text(TextContent(text: markdown))
        return CallToolResult(content: [content])
    }

    private func handleListFrameworks() async throws -> CallToolResult {
        guard let searchIndex else {
            throw ToolError.indexNotAvailable("Documentation search index not available. Run 'cupertino data index' to create it.")
        }

        let frameworks = try await searchIndex.listFrameworks()
        let totalDocs = try await searchIndex.documentCount()

        var markdown = "# Available Frameworks\n\n"
        markdown += "Total documents: **\(totalDocs)**\n\n"

        if frameworks.isEmpty {
            let cmd = "\(Shared.Constants.App.commandName) \(Shared.Constants.Command.buildIndex)"
            markdown += Shared.Constants.MCP.messageNoFrameworks(buildIndexCommand: cmd)
        } else {
            markdown += "| Framework | Documents |\n"
            markdown += "|-----------|----------:|\n"

            for (framework, count) in frameworks.sorted(by: { $0.value > $1.value }) {
                markdown += "| `\(framework)` | \(count) |\n"
            }

            markdown += "\n"
            markdown += Shared.Constants.MCP.tipFilterByFramework
            markdown += "\n"
        }

        let content = ContentBlock.text(TextContent(text: markdown))
        return CallToolResult(content: [content])
    }

    private func handleReadDocument(arguments: [String: AnyCodable]?) async throws -> CallToolResult {
        guard let searchIndex else {
            throw ToolError.indexNotAvailable("Documentation search index not available. Run 'cupertino data index' to create it.")
        }

        guard let uri = arguments?[Shared.Constants.MCP.schemaParamURI]?.value as? String else {
            throw ToolError.missingArgument(Shared.Constants.MCP.schemaParamURI)
        }

        let formatString = (arguments?[Shared.Constants.MCP.schemaParamFormat]?.value as? String)
            ?? Shared.Constants.MCP.formatValueJSON
        let format: Search.Index.DocumentFormat = formatString == Shared.Constants.MCP.formatValueMarkdown
            ? .markdown : .json

        guard let documentContent = try await searchIndex.getDocumentContent(uri: uri, format: format) else {
            throw ToolError.invalidArgument(
                Shared.Constants.MCP.schemaParamURI,
                "Document not found: \(uri)"
            )
        }

        let content = ContentBlock.text(TextContent(text: documentContent))
        return CallToolResult(content: [content])
    }

    // MARK: - Sample Code Tool Handlers

    private func handleSearchSamples(arguments: [String: AnyCodable]?) async throws -> CallToolResult {
        guard let sampleDatabase else {
            throw ToolError.indexNotAvailable("Sample code index not available. Run 'cupertino index' to create it.")
        }

        guard let query = arguments?[Shared.Constants.MCP.schemaParamQuery]?.value as? String else {
            throw ToolError.missingArgument(Shared.Constants.MCP.schemaParamQuery)
        }

        let framework = arguments?[Shared.Constants.MCP.schemaParamFramework]?.value as? String
        let defaultLimit = Shared.Constants.Limit.defaultSearchLimit
        let requestedLimit = (arguments?[Shared.Constants.MCP.schemaParamLimit]?.value as? Int) ?? defaultLimit
        let limit = min(requestedLimit, Shared.Constants.Limit.maxSearchLimit)
        let searchFiles = (arguments?[Shared.Constants.MCP.schemaParamSearchFiles]?.value as? Bool) ?? true

        let projects = try await sampleDatabase.searchProjects(query: query, framework: framework, limit: limit)

        var files: [SampleIndex.Database.FileSearchResult] = []
        if searchFiles {
            files = try await sampleDatabase.searchFiles(query: query, projectId: nil, limit: limit)
        }

        var markdown = "# Sample Code Search: \"\(query)\"\n\n"

        if let framework {
            markdown += "_Filtered to framework: **\(framework)**_\n\n"
        }

        markdown += "## Projects (\(projects.count) found)\n\n"

        if projects.isEmpty {
            markdown += "_No matching projects found._\n\n"
        } else {
            for (index, project) in projects.enumerated() {
                markdown += "### \(index + 1). \(project.title)\n\n"
                markdown += "- **ID:** `\(project.id)`\n"
                markdown += "- **Framework:** `\(project.frameworks.joined(separator: ", "))`\n"
                markdown += "- **Files:** \(project.fileCount)\n\n"

                if !project.description.isEmpty {
                    markdown += project.description + "\n\n"
                }

                if index < projects.count - 1 {
                    markdown += "---\n\n"
                }
            }
        }

        if searchFiles, !files.isEmpty {
            markdown += "\n## Matching Files (\(files.count) found)\n\n"

            for (index, result) in files.prefix(10).enumerated() {
                markdown += "### \(index + 1). \(result.filename)\n\n"
                markdown += "- **Project:** `\(result.projectId)`\n"
                markdown += "- **Path:** `\(result.path)`\n"
                markdown += "- **Score:** \(String(format: "%.2f", result.rank))\n\n"

                let snippet = result.snippet
                    .replacingOccurrences(of: "\n", with: "\n> ")
                markdown += "> \(snippet)\n\n"

                if index < min(files.count, 10) - 1 {
                    markdown += "---\n\n"
                }
            }
        }

        markdown += "\n\n"
        markdown += "💡 **Tip:** Use `read_sample` with project_id to see full README, or `read_sample_file` to view source code."
        markdown += "\n"

        let content = ContentBlock.text(TextContent(text: markdown))
        return CallToolResult(content: [content])
    }

    private func handleListSamples(arguments: [String: AnyCodable]?) async throws -> CallToolResult {
        guard let sampleDatabase else {
            throw ToolError.indexNotAvailable("Sample code index not available. Run 'cupertino index' to create it.")
        }

        let framework = arguments?[Shared.Constants.MCP.schemaParamFramework]?.value as? String
        let defaultLimit = 50
        let requestedLimit = (arguments?[Shared.Constants.MCP.schemaParamLimit]?.value as? Int) ?? defaultLimit
        let limit = min(requestedLimit, 100)

        let projects = try await sampleDatabase.listProjects(framework: framework, limit: limit)
        let totalProjects = try await sampleDatabase.projectCount()
        let totalFiles = try await sampleDatabase.fileCount()

        var markdown = "# Indexed Sample Code Projects\n\n"
        markdown += "Total projects: **\(totalProjects)**\n"
        markdown += "Total files: **\(totalFiles)**\n\n"

        if let framework {
            markdown += "_Filtered to framework: **\(framework)**_\n\n"
        }

        if projects.isEmpty {
            markdown += "_No projects found. Run `cupertino index` to index sample code._\n"
        } else {
            markdown += "| Project | Framework | Files |\n"
            markdown += "|---------|-----------|------:|\n"

            for project in projects {
                let frameworks = project.frameworks.joined(separator: ", ")
                markdown += "| `\(project.id)` | \(frameworks) | \(project.fileCount) |\n"
            }

            markdown += "\n"
            markdown += "💡 **Tip:** Use `search_samples` to find projects by keyword, or `read_sample` to view project details."
            markdown += "\n"
        }

        let content = ContentBlock.text(TextContent(text: markdown))
        return CallToolResult(content: [content])
    }

    private func handleReadSample(arguments: [String: AnyCodable]?) async throws -> CallToolResult {
        guard let sampleDatabase else {
            throw ToolError.indexNotAvailable("Sample code index not available. Run 'cupertino index' to create it.")
        }

        guard let projectId = arguments?[Shared.Constants.MCP.schemaParamProjectId]?.value as? String else {
            throw ToolError.missingArgument(Shared.Constants.MCP.schemaParamProjectId)
        }

        guard let project = try await sampleDatabase.getProject(id: projectId) else {
            throw ToolError.invalidArgument(
                Shared.Constants.MCP.schemaParamProjectId,
                "Project not found: \(projectId)"
            )
        }

        var markdown = "# \(project.title)\n\n"
        markdown += "**Project ID:** `\(project.id)`\n\n"

        if !project.description.isEmpty {
            markdown += "## Description\n\n"
            markdown += project.description + "\n\n"
        }

        markdown += "## Metadata\n\n"
        markdown += "- **Frameworks:** \(project.frameworks.joined(separator: ", "))\n"
        markdown += "- **Files:** \(project.fileCount)\n"
        markdown += "- **Size:** \(formatBytes(project.totalSize))\n"
        if !project.webURL.isEmpty {
            markdown += "- **Apple Developer:** \(project.webURL)\n"
        }
        markdown += "\n"

        if let readme = project.readme, !readme.isEmpty {
            markdown += "## README\n\n"
            markdown += readme
            markdown += "\n\n"
        }

        let files = try await sampleDatabase.listFiles(projectId: projectId)
        if !files.isEmpty {
            markdown += "## Files (\(files.count) total)\n\n"
            for file in files.prefix(30) {
                markdown += "- `\(file.path)`\n"
            }
            if files.count > 30 {
                markdown += "- _... and \(files.count - 30) more files_\n"
            }
            markdown += "\n"
            markdown += "💡 Use `read_sample_file` with project_id and file_path to view source code.\n"
        }

        let content = ContentBlock.text(TextContent(text: markdown))
        return CallToolResult(content: [content])
    }

    private func handleReadSampleFile(arguments: [String: AnyCodable]?) async throws -> CallToolResult {
        guard let sampleDatabase else {
            throw ToolError.indexNotAvailable("Sample code index not available. Run 'cupertino index' to create it.")
        }

        guard let projectId = arguments?[Shared.Constants.MCP.schemaParamProjectId]?.value as? String else {
            throw ToolError.missingArgument(Shared.Constants.MCP.schemaParamProjectId)
        }

        guard let filePath = arguments?[Shared.Constants.MCP.schemaParamFilePath]?.value as? String else {
            throw ToolError.missingArgument(Shared.Constants.MCP.schemaParamFilePath)
        }

        guard let file = try await sampleDatabase.getFile(projectId: projectId, path: filePath) else {
            throw ToolError.invalidArgument(
                Shared.Constants.MCP.schemaParamFilePath,
                "File not found: \(filePath) in project \(projectId)"
            )
        }

        var markdown = "# \(file.filename)\n\n"
        markdown += "**Project:** `\(file.projectId)`\n"
        markdown += "**Path:** `\(file.path)`\n"
        markdown += "**Size:** \(formatBytes(file.size))\n\n"

        let language = languageForExtension(file.fileExtension)

        markdown += "```\(language)\n"
        markdown += file.content
        if !file.content.hasSuffix("\n") {
            markdown += "\n"
        }
        markdown += "```\n"

        let content = ContentBlock.text(TextContent(text: markdown))
        return CallToolResult(content: [content])
    }

    // MARK: - Helpers

    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }

    private func languageForExtension(_ ext: String) -> String {
        switch ext.lowercased() {
        case "swift": return "swift"
        case "h", "m", "mm": return "objc"
        case "c": return "c"
        case "cpp", "hpp": return "cpp"
        case "metal": return "metal"
        case "json": return "json"
        case "plist": return "xml"
        case "md": return "markdown"
        case "strings": return "properties"
        default: return ext
        }
    }
}

// MARK: - Tool Errors

enum ToolError: Error, LocalizedError {
    case unknownTool(String)
    case missingArgument(String)
    case invalidArgument(String, String)
    case indexNotAvailable(String)

    var errorDescription: String? {
        switch self {
        case .unknownTool(let name):
            return "Unknown tool: \(name)"
        case .missingArgument(let arg):
            return "Missing required argument: \(arg)"
        case .invalidArgument(let arg, let reason):
            return "Invalid argument '\(arg)': \(reason)"
        case .indexNotAvailable(let message):
            return message
        }
    }
}
