import Foundation
import SwiftUI

/// The available widget templates
public enum WidgetTemplate: String, Codable, CaseIterable, Identifiable, Sendable {
    case monoStat = "mono_stat"
    case dualStat = "dual_stat"
    case statStack = "stat_stack"
    case headline = "headline"
    case list = "list"
    case grid = "grid"
    case timestamp = "timestamp"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .monoStat: return "Mono Stat"
        case .dualStat: return "Dual Stat"
        case .statStack: return "Stat Stack"
        case .headline: return "Headline"
        case .list: return "List"
        case .grid: return "Grid"
        case .timestamp: return "Timestamp"
        }
    }

    public var description: String {
        switch self {
        case .monoStat: return "Single large number with label"
        case .dualStat: return "Two numbers side by side"
        case .statStack: return "3-5 key-value pairs stacked"
        case .headline: return "Large text string"
        case .list: return "3-5 text items"
        case .grid: return "2x2 or 3x2 grid of stats"
        case .timestamp: return "Value with prominent timestamp"
        }
    }

    /// Minimum number of data bindings required
    public var minBindings: Int {
        switch self {
        case .monoStat: return 1
        case .dualStat: return 2
        case .statStack: return 2
        case .headline: return 1
        case .list: return 1
        case .grid: return 4
        case .timestamp: return 1
        }
    }

    /// Maximum number of data bindings supported
    public var maxBindings: Int {
        switch self {
        case .monoStat: return 1
        case .dualStat: return 2
        case .statStack: return 5
        case .headline: return 1
        case .list: return 5
        case .grid: return 6
        case .timestamp: return 1
        }
    }

    /// Whether this template works well with the given data type
    public func isCompatible(with value: JSONValue) -> Bool {
        switch self {
        case .monoStat, .timestamp:
            if case .number = value { return true }
            if case .string = value { return true }
            return false
        case .dualStat, .grid:
            if case .number = value { return true }
            return false
        case .statStack:
            return value.isPrimitive
        case .headline:
            if case .string = value { return true }
            return false
        case .list:
            if case .array = value { return true }
            if case .string = value { return true }
            return false
        }
    }

    /// Supported widget sizes for this template
    public var supportedSizes: [WidgetSize] {
        switch self {
        case .monoStat: return [.small, .medium]
        case .dualStat: return [.small, .medium]
        case .statStack: return [.small, .medium, .large]
        case .headline: return [.small, .medium]
        case .list: return [.small, .medium, .large]
        case .grid: return [.medium, .large]
        case .timestamp: return [.small, .medium]
        }
    }
}

/// Widget sizes matching iOS WidgetKit families
public enum WidgetSize: String, Codable, CaseIterable, Identifiable, Sendable {
    case small
    case medium
    case large

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        }
    }

    public var gridDescription: String {
        switch self {
        case .small: return "2×2"
        case .medium: return "4×2"
        case .large: return "4×4"
        }
    }
}
