import Foundation

// MARK: - GitHub Fetcher

/// Actor for fetching documentation from GitHub.
/// Uses raw.githubusercontent.com for content (no rate limits) and GitHub API for directory listings.
public actor GitHubFetcher {
    /// Repository in format "owner/repo"
    public let repository: String

    /// Branch name
    public let branch: String

    /// URL session for HTTP requests
    private let session: URLSession

    // MARK: - Initialization

    public init(
        repository: String = RemoteSync.defaultRepository,
        branch: String = RemoteSync.defaultBranch,
        session: URLSession = .shared
    ) {
        self.repository = repository
        self.branch = branch
        self.session = session
    }

    // MARK: - Directory Listing (GitHub API)

    /// Fetch list of directories in a path (e.g., frameworks in /docs)
    public func fetchDirectoryList(path: String) async throws -> [String] {
        let url = buildAPIURL(path: path)
        let (data, response) = try await session.data(from: url)

        try validateResponse(response, for: url)

        let items = try JSONDecoder().decode([GitHubContentItem].self, from: data)
        return items
            .filter { $0.type == "dir" }
            .map(\.name)
            .sorted()
    }

    /// Fetch list of files in a directory
    public func fetchFileList(path: String) async throws -> [GitHubFileInfo] {
        let url = buildAPIURL(path: path)
        let (data, response) = try await session.data(from: url)

        try validateResponse(response, for: url)

        let items = try JSONDecoder().decode([GitHubContentItem].self, from: data)
        return items
            .filter { $0.type == "file" }
            .map { GitHubFileInfo(name: $0.name, path: $0.path, size: $0.size ?? 0) }
            .sorted { $0.name < $1.name }
    }

    // MARK: - File Content (Raw GitHub)

    /// Fetch raw file content
    public func fetchFileContent(path: String) async throws -> Data {
        let url = buildRawURL(path: path)
        let (data, response) = try await session.data(from: url)

        try validateResponse(response, for: url)

        return data
    }

    /// Fetch and decode JSON file
    public func fetchJSON<T: Decodable>(path: String, as type: T.Type) async throws -> T {
        let data = try await fetchFileContent(path: path)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(type, from: data)
    }

    /// Fetch file as string
    public func fetchString(path: String) async throws -> String {
        let data = try await fetchFileContent(path: path)
        guard let string = String(data: data, encoding: .utf8) else {
            throw GitHubFetcherError.invalidEncoding(path: path)
        }
        return string
    }

    // MARK: - URL Building

    private func buildAPIURL(path: String) -> URL {
        let cleanPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        let urlString = "\(RemoteSync.gitHubAPIBaseURL)/repos/\(repository)/contents/\(cleanPath)?ref=\(branch)"
        return URL(string: urlString)!
    }

    private func buildRawURL(path: String) -> URL {
        let cleanPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        let urlString = "\(RemoteSync.rawGitHubBaseURL)/\(repository)/\(branch)/\(cleanPath)"
        return URL(string: urlString)!
    }

    // MARK: - Response Validation

    private func validateResponse(_ response: URLResponse, for url: URL) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GitHubFetcherError.invalidResponse(url: url)
        }

        switch httpResponse.statusCode {
        case 200...299:
            return
        case 403:
            throw GitHubFetcherError.rateLimited
        case 404:
            throw GitHubFetcherError.notFound(url: url)
        default:
            throw GitHubFetcherError.httpError(statusCode: httpResponse.statusCode, url: url)
        }
    }
}

// MARK: - Supporting Types

/// Information about a file in the repository
public struct GitHubFileInfo: Sendable, Equatable {
    public let name: String
    public let path: String
    public let size: Int

    public init(name: String, path: String, size: Int) {
        self.name = name
        self.path = path
        self.size = size
    }
}

/// GitHub API content item response
private struct GitHubContentItem: Decodable {
    let name: String
    let path: String
    let type: String
    let size: Int?
}

// MARK: - Errors

/// Errors from GitHub fetcher
public enum GitHubFetcherError: Error, Sendable, CustomStringConvertible {
    case invalidResponse(url: URL)
    case notFound(url: URL)
    case rateLimited
    case httpError(statusCode: Int, url: URL)
    case invalidEncoding(path: String)

    public var description: String {
        switch self {
        case let .invalidResponse(url):
            return "Invalid response from \(url)"
        case let .notFound(url):
            return "Not found: \(url)"
        case .rateLimited:
            return "GitHub API rate limit exceeded. Try again later or use authentication."
        case let .httpError(statusCode, url):
            return "HTTP \(statusCode) from \(url)"
        case let .invalidEncoding(path):
            return "Invalid UTF-8 encoding in file: \(path)"
        }
    }
}
