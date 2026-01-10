import Foundation

/// A single data binding from JSON path to display label
public struct DataBinding: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var jsonPath: String
    public var label: String
    public var order: Int

    public init(id: UUID = UUID(), jsonPath: String, label: String, order: Int = 0) {
        self.id = id
        self.jsonPath = jsonPath
        self.label = label
        self.order = order
    }
}

/// HTTP header for authenticated requests
public struct HTTPHeader: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var key: String
    public var value: String

    public init(id: UUID = UUID(), key: String, value: String) {
        self.id = id
        self.key = key
        self.value = value
    }
}

/// Refresh interval options
public enum RefreshInterval: Int, Codable, CaseIterable, Identifiable, Sendable {
    case fifteenMinutes = 15
    case thirtyMinutes = 30
    case oneHour = 60
    case fourHours = 240
    case manual = 0

    public var id: Int { rawValue }

    public var displayName: String {
        switch self {
        case .fifteenMinutes: return "15 minutes"
        case .thirtyMinutes: return "30 minutes"
        case .oneHour: return "1 hour"
        case .fourHours: return "4 hours"
        case .manual: return "Manual only"
        }
    }

    public var timeInterval: TimeInterval? {
        guard rawValue > 0 else { return nil }
        return TimeInterval(rawValue * 60)
    }
}

/// Complete widget configuration
public struct WidgetConfig: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var name: String
    public var endpointURL: String
    public var headers: [HTTPHeader]
    public var bindings: [DataBinding]
    public var template: WidgetTemplate
    public var size: WidgetSize
    public var refreshInterval: RefreshInterval
    public var tapURL: String?
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        name: String = "New Widget",
        endpointURL: String = "",
        headers: [HTTPHeader] = [],
        bindings: [DataBinding] = [],
        template: WidgetTemplate = .monoStat,
        size: WidgetSize = .small,
        refreshInterval: RefreshInterval = .thirtyMinutes,
        tapURL: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.endpointURL = endpointURL
        self.headers = headers
        self.bindings = bindings
        self.template = template
        self.size = size
        self.refreshInterval = refreshInterval
        self.tapURL = tapURL
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Validate the configuration
    public var isValid: Bool {
        guard let url = URL(string: endpointURL), url.scheme != nil else {
            return false
        }
        guard !bindings.isEmpty else { return false }
        guard bindings.count >= template.minBindings else { return false }
        guard bindings.count <= template.maxBindings else { return false }
        return true
    }

    /// Get sorted bindings
    public var sortedBindings: [DataBinding] {
        bindings.sorted { $0.order < $1.order }
    }
}

/// Cached widget data for offline display
public struct CachedWidgetData: Codable, Sendable {
    public var configId: UUID
    public var jsonData: JSONValue
    public var fetchedAt: Date
    public var isStale: Bool

    public init(configId: UUID, jsonData: JSONValue, fetchedAt: Date = Date(), isStale: Bool = false) {
        self.configId = configId
        self.jsonData = jsonData
        self.fetchedAt = fetchedAt
        self.isStale = isStale
    }

    /// How old the data is
    public var age: TimeInterval {
        Date().timeIntervalSince(fetchedAt)
    }

    /// Human-readable age string
    public var ageString: String {
        let minutes = Int(age / 60)
        if minutes < 1 {
            return "just now"
        } else if minutes < 60 {
            return "\(minutes)m ago"
        } else {
            let hours = minutes / 60
            if hours < 24 {
                return "\(hours)h ago"
            } else {
                let days = hours / 24
                return "\(days)d ago"
            }
        }
    }
}

/// Widget display data ready for rendering
public struct WidgetDisplayData: Sendable {
    public var values: [(label: String, value: String)]
    public var timestamp: Date?
    public var isStale: Bool
    public var error: String?

    public init(
        values: [(label: String, value: String)] = [],
        timestamp: Date? = nil,
        isStale: Bool = false,
        error: String? = nil
    ) {
        self.values = values
        self.timestamp = timestamp
        self.isStale = isStale
        self.error = error
    }

    /// Create display data from config and cached JSON
    public static func from(config: WidgetConfig, cache: CachedWidgetData?) -> WidgetDisplayData {
        guard let cache = cache else {
            return WidgetDisplayData(error: "No data")
        }

        var values: [(String, String)] = []
        for binding in config.sortedBindings {
            let value = cache.jsonData.value(at: binding.jsonPath)
            values.append((binding.label, value?.displayString ?? "—"))
        }

        return WidgetDisplayData(
            values: values,
            timestamp: cache.fetchedAt,
            isStale: cache.isStale
        )
    }
}
