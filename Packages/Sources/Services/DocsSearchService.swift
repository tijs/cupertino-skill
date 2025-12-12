import Foundation
import Search
import Shared

// MARK: - Documentation Search Service

/// Service for searching Apple documentation, Swift Evolution, and other indexed sources.
/// Wraps Search.Index with a clean interface for both CLI and MCP consumers.
public actor DocsSearchService: SearchService {
    private let index: Search.Index

    /// Initialize with an existing search index
    public init(index: Search.Index) {
        self.index = index
    }

    /// Initialize with a database path, creating a new index connection
    public init(dbPath: URL) async throws {
        index = try await Search.Index(dbPath: dbPath)
    }

    // MARK: - SearchService Protocol

    public func search(_ query: SearchQuery) async throws -> [Search.Result] {
        // Fetch more results if filtering by version (to account for filtering)
        let hasVersionFilter = query.minimumiOS != nil || query.minimumMacOS != nil ||
            query.minimumTvOS != nil || query.minimumWatchOS != nil ||
            query.minimumVisionOS != nil
        let fetchLimit = hasVersionFilter
            ? min(query.limit * 3, Shared.Constants.Limit.maxSearchLimit)
            : query.limit

        var results = try await index.search(
            query: query.text,
            source: query.source,
            framework: query.framework,
            language: query.language,
            limit: fetchLimit,
            includeArchive: query.includeArchive
        )

        // Apply version filters if specified
        if let minimumiOS = query.minimumiOS {
            results = results.filter { result in
                guard let resultVersion = result.minimumiOS else {
                    return false
                }
                return Self.isVersion(resultVersion, lessThanOrEqualTo: minimumiOS)
            }
        }

        if let minimumMacOS = query.minimumMacOS {
            results = results.filter { result in
                guard let resultVersion = result.minimumMacOS else {
                    return false
                }
                return Self.isVersion(resultVersion, lessThanOrEqualTo: minimumMacOS)
            }
        }

        if let minimumTvOS = query.minimumTvOS {
            results = results.filter { result in
                guard let resultVersion = result.minimumTvOS else {
                    return false
                }
                return Self.isVersion(resultVersion, lessThanOrEqualTo: minimumTvOS)
            }
        }

        if let minimumWatchOS = query.minimumWatchOS {
            results = results.filter { result in
                guard let resultVersion = result.minimumWatchOS else {
                    return false
                }
                return Self.isVersion(resultVersion, lessThanOrEqualTo: minimumWatchOS)
            }
        }

        if let minimumVisionOS = query.minimumVisionOS {
            results = results.filter { result in
                guard let resultVersion = result.minimumVisionOS else {
                    return false
                }
                return Self.isVersion(resultVersion, lessThanOrEqualTo: minimumVisionOS)
            }
        }

        // Trim to requested limit after filtering
        return Array(results.prefix(query.limit))
    }

    /// Compare version strings (e.g., "13.0" vs "15.0")
    /// Returns true if lhs <= rhs (API was introduced before or at target version)
    private static func isVersion(_ lhs: String, lessThanOrEqualTo rhs: String) -> Bool {
        let lhsComponents = lhs.split(separator: ".").compactMap { Int($0) }
        let rhsComponents = rhs.split(separator: ".").compactMap { Int($0) }

        // Compare component by component
        for idx in 0..<max(lhsComponents.count, rhsComponents.count) {
            let lhsValue = idx < lhsComponents.count ? lhsComponents[idx] : 0
            let rhsValue = idx < rhsComponents.count ? rhsComponents[idx] : 0

            if lhsValue < rhsValue { return true }
            if lhsValue > rhsValue { return false }
        }
        return true // Equal versions
    }

    public func read(uri: String, format: Search.Index.DocumentFormat) async throws -> String? {
        try await index.getDocumentContent(uri: uri, format: format)
    }

    public func listFrameworks() async throws -> [String: Int] {
        try await index.listFrameworks()
    }

    public func documentCount() async throws -> Int {
        try await index.documentCount()
    }

    public func disconnect() async {
        await index.disconnect()
    }

    // MARK: - Convenience Methods

    /// Search with a simple text query using defaults
    public func search(text: String, limit: Int = Shared.Constants.Limit.defaultSearchLimit) async throws -> [Search.Result] {
        try await search(SearchQuery(text: text, limit: limit))
    }

    /// Search within a specific framework
    public func search(text: String, framework: String, limit: Int = Shared.Constants.Limit.defaultSearchLimit) async throws -> [Search.Result] {
        try await search(SearchQuery(text: text, framework: framework, limit: limit))
    }

    /// Search within a specific source (apple-docs, swift-evolution, etc.)
    public func search(text: String, source: String, limit: Int = Shared.Constants.Limit.defaultSearchLimit) async throws -> [Search.Result] {
        try await search(SearchQuery(text: text, source: source, limit: limit))
    }
}
