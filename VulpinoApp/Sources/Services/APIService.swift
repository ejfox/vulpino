import Foundation

/// Errors that can occur during API operations
public enum APIError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case timeout
    case httpError(Int)
    case authError
    case parseError(String)
    case noData

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .timeout:
            return "Request timed out"
        case .httpError(let code):
            return "HTTP error \(code)"
        case .authError:
            return "Access denied — check your headers"
        case .parseError(let message):
            return "Couldn't parse response: \(message)"
        case .noData:
            return "No data received"
        }
    }
}

/// Service for fetching and parsing JSON from endpoints
@MainActor
public final class APIService: ObservableObject {
    public static let shared = APIService()

    private let session: URLSession
    private let timeout: TimeInterval = 10

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeout
        config.timeoutIntervalForResource = timeout
        config.waitsForConnectivity = false
        self.session = URLSession(configuration: config)
    }

    /// Fetch JSON from a URL with optional headers
    public func fetch(
        url urlString: String,
        headers: [HTTPHeader] = []
    ) async throws -> JSONValue {
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // Add custom headers
        for header in headers {
            request.setValue(header.value, forHTTPHeaderField: header.key)
        }

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError where error.code == .timedOut {
            throw APIError.timeout
        } catch {
            throw APIError.networkError(error)
        }

        // Check HTTP status
        if let httpResponse = response as? HTTPURLResponse {
            switch httpResponse.statusCode {
            case 200..<300:
                break // Success
            case 401, 403:
                throw APIError.authError
            default:
                throw APIError.httpError(httpResponse.statusCode)
            }
        }

        guard !data.isEmpty else {
            throw APIError.noData
        }

        // Parse JSON
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(JSONValue.self, from: data)
        } catch {
            throw APIError.parseError(error.localizedDescription)
        }
    }

    /// Test a URL and return timing info
    public func testEndpoint(
        url: String,
        headers: [HTTPHeader] = []
    ) async -> (success: Bool, latency: TimeInterval?, error: APIError?) {
        let start = Date()

        do {
            _ = try await fetch(url: url, headers: headers)
            let latency = Date().timeIntervalSince(start)
            return (true, latency, nil)
        } catch let error as APIError {
            return (false, nil, error)
        } catch {
            return (false, nil, .networkError(error))
        }
    }
}

// MARK: - JSON Structure Discovery

extension APIService {
    /// Represents a node in the JSON structure tree
    public struct JSONNode: Identifiable {
        public let id = UUID()
        public let path: String
        public let key: String
        public let value: JSONValue
        public let depth: Int

        public var children: [JSONNode]? {
            switch value {
            case .object(let dict):
                return dict.keys.sorted().map { childKey in
                    JSONNode(
                        path: path.isEmpty ? childKey : "\(path).\(childKey)",
                        key: childKey,
                        value: dict[childKey]!,
                        depth: depth + 1
                    )
                }
            case .array(let arr) where !arr.isEmpty:
                // Show first item as example
                return [JSONNode(
                    path: "\(path)[0]",
                    key: "[0]",
                    value: arr[0],
                    depth: depth + 1
                )]
            default:
                return nil
            }
        }

        public var displayValue: String {
            switch value {
            case .string(let s):
                let truncated = s.count > 30 ? String(s.prefix(27)) + "..." : s
                return "\"\(truncated)\""
            case .number(let n):
                return NumberFormatter.adaptive.string(from: n)
            case .bool(let b):
                return b ? "true" : "false"
            case .null:
                return "null"
            case .array(let arr):
                return "[\(arr.count) items]"
            case .object(let obj):
                return "{\(obj.count) keys}"
            }
        }

        public var typeIcon: String {
            switch value {
            case .string: return "text.quote"
            case .number: return "number"
            case .bool: return "checkmark.circle"
            case .null: return "minus.circle"
            case .array: return "list.bullet"
            case .object: return "folder"
            }
        }
    }

    /// Build a tree structure from JSON for display
    public func buildStructure(from json: JSONValue) -> [JSONNode] {
        switch json {
        case .object(let dict):
            return dict.keys.sorted().map { key in
                JSONNode(path: key, key: key, value: dict[key]!, depth: 0)
            }
        case .array(let arr) where !arr.isEmpty:
            return [JSONNode(path: "[0]", key: "[0]", value: arr[0], depth: 0)]
        default:
            return [JSONNode(path: "", key: "root", value: json, depth: 0)]
        }
    }
}
