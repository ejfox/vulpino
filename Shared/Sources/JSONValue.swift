import Foundation

/// A recursive enum representing any JSON value
public enum JSONValue: Codable, Equatable, Sendable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case null
    case array([JSONValue])
    case object([String: JSONValue])

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
        } else if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
        } else if let int = try? container.decode(Int.self) {
            self = .number(Double(int))
        } else if let double = try? container.decode(Double.self) {
            self = .number(double)
        } else if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let array = try? container.decode([JSONValue].self) {
            self = .array(array)
        } else if let object = try? container.decode([String: JSONValue].self) {
            self = .object(object)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unknown JSON type")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value): try container.encode(value)
        case .number(let value): try container.encode(value)
        case .bool(let value): try container.encode(value)
        case .null: try container.encodeNil()
        case .array(let value): try container.encode(value)
        case .object(let value): try container.encode(value)
        }
    }

    /// Get value at a JSONPath (e.g., "data.users[0].name")
    public func value(at path: String) -> JSONValue? {
        let components = JSONPath.parse(path)
        return value(at: components)
    }

    private func value(at components: [JSONPath.Component]) -> JSONValue? {
        guard let first = components.first else { return self }
        let rest = Array(components.dropFirst())

        switch (self, first) {
        case (.object(let dict), .key(let key)):
            return dict[key]?.value(at: rest)
        case (.array(let arr), .index(let idx)) where idx < arr.count:
            return arr[idx].value(at: rest)
        default:
            return nil
        }
    }

    /// Display-friendly string representation
    public var displayString: String {
        switch self {
        case .string(let s): return s
        case .number(let n): return NumberFormatter.adaptive.string(from: n)
        case .bool(let b): return b ? "Yes" : "No"
        case .null: return "—"
        case .array(let arr): return "[\(arr.count) items]"
        case .object(let obj): return "{\(obj.count) keys}"
        }
    }

    /// Check if this is a primitive (displayable as single value)
    public var isPrimitive: Bool {
        switch self {
        case .string, .number, .bool, .null: return true
        case .array, .object: return false
        }
    }

    /// Get all keys if this is an object
    public var keys: [String]? {
        guard case .object(let dict) = self else { return nil }
        return Array(dict.keys).sorted()
    }

    /// Get count if this is an array
    public var arrayCount: Int? {
        guard case .array(let arr) = self else { return nil }
        return arr.count
    }
}

// MARK: - JSONPath

public enum JSONPath {
    public enum Component: Equatable {
        case key(String)
        case index(Int)
    }

    /// Parse a path like "data.users[0].name" into components
    public static func parse(_ path: String) -> [Component] {
        var components: [Component] = []
        var current = ""
        var inBracket = false

        for char in path {
            switch char {
            case "." where !inBracket:
                if !current.isEmpty {
                    components.append(.key(current))
                    current = ""
                }
            case "[":
                if !current.isEmpty {
                    components.append(.key(current))
                    current = ""
                }
                inBracket = true
            case "]":
                if let idx = Int(current) {
                    components.append(.index(idx))
                }
                current = ""
                inBracket = false
            default:
                current.append(char)
            }
        }

        if !current.isEmpty {
            components.append(.key(current))
        }

        return components
    }

    /// Convert components back to string path
    public static func stringify(_ components: [Component]) -> String {
        var result = ""
        for (i, component) in components.enumerated() {
            switch component {
            case .key(let key):
                if i > 0 { result += "." }
                result += key
            case .index(let idx):
                result += "[\(idx)]"
            }
        }
        return result
    }
}

// MARK: - Number Formatting

extension NumberFormatter {
    static let adaptive: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.usesGroupingSeparator = true
        return formatter
    }()

    func string(from double: Double) -> String {
        // Handle large numbers with K/M/B suffix
        let absValue = abs(double)
        if absValue >= 1_000_000_000 {
            return String(format: "%.1fB", double / 1_000_000_000)
        } else if absValue >= 1_000_000 {
            return String(format: "%.1fM", double / 1_000_000)
        } else if absValue >= 10_000 {
            return String(format: "%.1fK", double / 1_000)
        } else if absValue == floor(absValue) {
            return String(format: "%.0f", double)
        } else {
            return string(from: NSNumber(value: double)) ?? String(double)
        }
    }
}
