# Search Code Refactoring Analysis

**Date:** 2025-12-08
**Purpose:** Identify code duplication between CLI commands and MCP tools for potential refactoring.

---

## Executive Summary

The CLI commands and MCP tools implement **the same functionality** through different I/O channels:
- **CLI**: ArgumentParser → stdout/stderr
- **MCP**: JSON-RPC → CallToolResult

Both use the same underlying `Search.Index` but duplicate:
1. Parameter extraction/validation
2. Result formatting (markdown/JSON/text)
3. Error handling
4. Database path resolution

**Recommendation:** Extract shared logic into a `SearchService` layer.

---

## Detailed Analysis

### 1. Functionality Mapping

| Operation | CLI Command | MCP Tool | Shared Logic? |
|-----------|-------------|----------|---------------|
| Search docs | `SearchCommand` | `handleSearchDocs()` | **80% duplicate** |
| Search HIG | *Missing* | `handleSearchHIG()` | N/A |
| Read document | `ReadCommand` | `handleReadDocument()` | **70% duplicate** |
| List frameworks | `ListFrameworksCommand` | `handleListFrameworks()` | **75% duplicate** |

### 2. Code Duplication Details

#### 2.1 Search Operation

**CLI (`SearchCommand.swift:85-92`):**
```swift
let results = try await searchIndex.search(
    query: query,
    source: source,
    framework: framework,
    language: language,
    limit: limit,
    includeArchive: includeArchive
)
```

**MCP (`DocumentationToolProvider.swift:95-102`):**
```swift
let results = try await searchIndex.search(
    query: query,
    source: source,
    framework: framework,
    language: language,
    limit: limit,
    includeArchive: includeArchive
)
```

**Verdict:** Identical call - could share a service method.

---

#### 2.2 Markdown Formatting

**CLI (`SearchCommand.swift:157-178`):**
```swift
private func outputMarkdown(_ results: [Search.Result]) {
    Log.output("# Search Results for '\(query)'\n")
    Log.output("Found \(results.count) result(s).\n")
    for (index, result) in results.enumerated() {
        Log.output("## \(index + 1). \(result.title)\n")
        Log.output("- **Source:** \(result.source)")
        Log.output("- **Framework:** \(result.framework)")
        Log.output("- **URI:** `\(result.uri)`")
        // ...
    }
}
```

**MCP (`DocumentationToolProvider.swift:104-142`):**
```swift
var markdown = "# Search Results for \"\(query)\"\n\n"
markdown += "Found **\(results.count)** result\(results.count == 1 ? "" : "s"):\n\n"
for (index, result) in results.enumerated() {
    markdown += "## \(index + 1). \(result.title)\n\n"
    markdown += "- **Framework:** `\(result.framework)`\n"
    markdown += "- **URI:** `\(result.uri)`\n"
    // ...
}
```

**Differences:**
| Aspect | CLI | MCP |
|--------|-----|-----|
| Quote style | Single `'` | Double `"` |
| Pluralization | `result(s)` | Proper plural check |
| Fields shown | Source, Framework, URI | Framework, URI, Score, Words |
| Output method | `Log.output()` per line | String accumulation |

**Verdict:** Similar logic with different output - extract formatter returning String.

---

#### 2.3 Database Path Resolution

**Duplicated in 3 files:**

```swift
// SearchCommand.swift:107-112
private func resolveSearchDbPath() -> URL {
    if let searchDb {
        return URL(fileURLWithPath: searchDb).expandingTildeInPath
    }
    return Shared.Constants.defaultSearchDatabase
}

// ReadCommand.swift:64-69
private func resolveSearchDbPath() -> URL { /* identical */ }

// ListFrameworksCommand.swift:63-68
private func resolveSearchDbPath() -> URL { /* identical */ }
```

**Verdict:** Extract to `Shared.PathResolver.searchDatabase(custom:)`.

---

#### 2.4 URL Tilde Expansion

**Duplicated in 3 files:**

```swift
private extension URL {
    var expandingTildeInPath: URL {
        if path.hasPrefix("~") {
            let expandedPath = NSString(string: path).expandingTildeInPath
            return URL(fileURLWithPath: expandedPath)
        }
        return self
    }
}
```

**Verdict:** Move to `Shared.Extensions.URL+Tilde.swift`.

---

#### 2.5 OutputFormat Enum

**Duplicated in 3 files:**

```swift
// SearchCommand.swift:184-188
enum OutputFormat: String, ExpressibleByArgument, CaseIterable {
    case text
    case json
    case markdown
}

// ListFrameworksCommand.swift:148-152
enum OutputFormat: String, ExpressibleByArgument, CaseIterable {
    case text
    case json
    case markdown
}

// ReadCommand.swift:75-78
enum OutputFormat: String, ExpressibleByArgument, CaseIterable {
    case json
    case markdown  // Note: no text option
}
```

**Verdict:** Create shared `CLI.OutputFormat` enum.

---

#### 2.6 Database Existence Check

**Duplicated pattern in all CLI commands:**

```swift
guard FileManager.default.fileExists(atPath: dbPath.path) else {
    Log.error("Search database not found at \(dbPath.path)")
    Log.output("Run 'cupertino save' to build the search index first.")
    throw ExitCode.failure
}
```

**Verdict:** Extract to helper: `try CLI.requireSearchDatabase(at: dbPath)`.

---

#### 2.7 Search Index Lifecycle

**Duplicated in all CLI commands:**

```swift
let searchIndex = try await Search.Index(dbPath: dbPath)
defer {
    Task {
        await searchIndex.disconnect()
    }
}
```

**Verdict:** Create `withSearchIndex(at:) async throws` helper or `SearchService`.

---

### 3. Missing CLI Commands

The MCP tool has `search_hig` but CLI has no equivalent:

| MCP Tool | CLI Command | Status |
|----------|-------------|--------|
| `search_docs` | `search` | Exists |
| `search_hig` | - | **Missing** |
| `read_document` | `read` | Exists |
| `list_frameworks` | `list-frameworks` | Exists |

**Recommendation:** Add `cupertino search-hig` command or add `--hig` flag to search.

---

### 4. Inconsistencies

| Aspect | CLI | MCP | Issue |
|--------|-----|-----|-------|
| Score display | Not shown | Shown | CLI should optionally show score |
| Word count | Not shown | Shown | CLI should optionally show word count |
| Filter display | Not shown | Shown in header | CLI should show active filters |
| No results message | Plain text | Styled with tips | Inconsistent UX |
| Separator | None | `---` | MCP has better visual separation |

---

## 5. Proposed Refactoring

### 5.1 New Module: `SearchService`

```
Sources/
├── SearchService/           # NEW
│   ├── SearchService.swift  # Core search operations
│   ├── Formatters/
│   │   ├── SearchResultFormatter.swift
│   │   ├── FrameworkListFormatter.swift
│   │   └── DocumentFormatter.swift
│   └── Models/
│       └── SearchRequest.swift
```

### 5.2 SearchService API

```swift
public actor SearchService {
    private let searchIndex: Search.Index

    // Core operations
    public func search(_ request: SearchRequest) async throws -> [Search.Result]
    public func searchHIG(_ request: HIGSearchRequest) async throws -> [Search.Result]
    public func readDocument(uri: String, format: DocumentFormat) async throws -> String?
    public func listFrameworks() async throws -> [String: Int]

    // Convenience
    public static func withDatabase(
        at path: URL?,
        perform: (SearchService) async throws -> T
    ) async throws -> T
}
```

### 5.3 SearchRequest Model

```swift
public struct SearchRequest {
    public let query: String
    public let source: String?
    public let framework: String?
    public let language: String?
    public let limit: Int
    public let includeArchive: Bool

    public init(
        query: String,
        source: String? = nil,
        framework: String? = nil,
        language: String? = nil,
        limit: Int = 20,
        includeArchive: Bool = false
    )
}
```

### 5.4 Formatter Protocol

```swift
public protocol SearchResultFormatter {
    func format(results: [Search.Result], query: String, filters: SearchFilters) -> String
}

public struct MarkdownSearchResultFormatter: SearchResultFormatter { }
public struct JSONSearchResultFormatter: SearchResultFormatter { }
public struct TextSearchResultFormatter: SearchResultFormatter { }
```

### 5.5 Refactored CLI Command

```swift
struct SearchCommand: AsyncParsableCommand {
    // ... options ...

    mutating func run() async throws {
        try await SearchService.withDatabase(at: searchDbPath) { service in
            let request = SearchRequest(
                query: query,
                source: source,
                framework: framework,
                language: language,
                limit: limit,
                includeArchive: includeArchive
            )

            let results = try await service.search(request)
            let formatter = formatter(for: format)
            let output = formatter.format(results: results, query: query, filters: request.filters)
            Log.output(output)
        }
    }
}
```

### 5.6 Refactored MCP Tool

```swift
private func handleSearchDocs(arguments: [String: AnyCodable]?) async throws -> CallToolResult {
    let request = try SearchRequest(from: arguments)
    let results = try await searchService.search(request)

    let formatter = MarkdownSearchResultFormatter(showScore: true, showWordCount: true)
    let markdown = formatter.format(results: results, query: request.query, filters: request.filters)

    return CallToolResult(content: [.text(TextContent(text: markdown))])
}
```

---

## 6. Shared Utilities to Extract

| Current Location | New Location | Purpose |
|------------------|--------------|---------|
| `URL.expandingTildeInPath` (3 places) | `Shared/Extensions/URL+Tilde.swift` | Tilde expansion |
| `resolveSearchDbPath()` (3 places) | `Shared/PathResolver.swift` | Database path resolution |
| `OutputFormat` enum (3 places) | `CLI/OutputFormat.swift` | Output format selection |
| Database existence check (3 places) | `CLI/DatabaseHelper.swift` | Error handling |
| JSON encoder setup (3 places) | `Shared/JSONCoding.swift` | Consistent JSON formatting |

---

## 7. Priority Order

1. **High Priority:**
   - Extract `URL.expandingTildeInPath` to Shared
   - Extract `resolveSearchDbPath()` to Shared
   - Create shared `OutputFormat` enum

2. **Medium Priority:**
   - Create `SearchService` layer
   - Create formatter protocol and implementations
   - Add `search-hig` CLI command

3. **Low Priority:**
   - Unify markdown formatting between CLI and MCP
   - Add score/wordCount display options to CLI
   - Add filter display to CLI output

---

## 8. Lines of Code Estimate

| Change | Lines Removed | Lines Added | Net |
|--------|---------------|-------------|-----|
| URL extension dedup | -30 | +15 | -15 |
| Path resolver dedup | -24 | +20 | -4 |
| OutputFormat dedup | -18 | +12 | -6 |
| Database check dedup | -12 | +15 | +3 |
| SearchService | -100 | +150 | +50 |
| Formatters | -80 | +120 | +40 |
| **Total** | **-264** | **+332** | **+68** |

Net increase of ~68 lines, but with:
- Single source of truth for each operation
- Easier testing
- Consistent behavior across CLI and MCP
- Reduced maintenance burden

---

## 9. Files to Modify

### Create New:
- `Sources/Shared/Extensions/URL+Tilde.swift`
- `Sources/Shared/PathResolver.swift`
- `Sources/CLI/OutputFormat.swift`
- `Sources/CLI/DatabaseHelper.swift`
- `Sources/SearchService/SearchService.swift`
- `Sources/SearchService/Formatters/*.swift`

### Modify:
- `Sources/CLI/Commands/SearchCommand.swift`
- `Sources/CLI/Commands/ReadCommand.swift`
- `Sources/CLI/Commands/ListFrameworksCommand.swift`
- `Sources/SearchToolProvider/DocumentationToolProvider.swift`
- `Package.swift` (add SearchService target)

---

## 10. Testing Impact

With `SearchService` extraction:
- Test formatters independently
- Test service logic once (not per CLI command)
- Mock `SearchService` in CLI/MCP tests
- Higher test coverage with less code

---

*This file can be deleted after refactoring is complete.*
