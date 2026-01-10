import Foundation

/// Centralized formatting utilities for Vulpino
/// "Numbers should be effortless to read at a glance"
public enum Formatters {

    // MARK: - Number Formatting

    /// Format a number for display, adapting to magnitude
    public static func formatNumber(_ value: Double, compact: Bool = true) -> String {
        let absValue = abs(value)

        // Large numbers get abbreviated
        if compact && absValue >= 1_000_000_000 {
            return formatCompact(value, suffix: "B", divisor: 1_000_000_000)
        } else if compact && absValue >= 1_000_000 {
            return formatCompact(value, suffix: "M", divisor: 1_000_000)
        } else if compact && absValue >= 10_000 {
            return formatCompact(value, suffix: "K", divisor: 1_000)
        }

        // Standard formatting with grouping
        if absValue == floor(absValue) && absValue < 1_000_000 {
            // Integer
            return integerFormatter.string(from: NSNumber(value: value)) ?? String(Int(value))
        } else {
            // Decimal
            return decimalFormatter.string(from: NSNumber(value: value)) ?? String(value)
        }
    }

    private static func formatCompact(_ value: Double, suffix: String, divisor: Double) -> String {
        let divided = value / divisor
        if divided == floor(divided) {
            return "\(Int(divided))\(suffix)"
        } else {
            return String(format: "%.1f%@", divided, suffix)
        }
    }

    private static let integerFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        f.usesGroupingSeparator = true
        return f
    }()

    private static let decimalFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 1
        f.maximumFractionDigits = 2
        f.usesGroupingSeparator = true
        return f
    }()

    // MARK: - Percentage Formatting

    /// Format a number as a percentage
    public static func formatPercentage(_ value: Double, alreadyPercent: Bool = false) -> String {
        let percentValue = alreadyPercent ? value : value * 100
        if percentValue == floor(percentValue) {
            return "\(Int(percentValue))%"
        } else {
            return String(format: "%.1f%%", percentValue)
        }
    }

    // MARK: - Currency Formatting

    /// Format a number as currency
    public static func formatCurrency(_ value: Double, code: String = "USD") -> String {
        currencyFormatter.currencyCode = code
        return currencyFormatter.string(from: NSNumber(value: value)) ?? "$\(value)"
    }

    private static let currencyFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.maximumFractionDigits = 2
        return f
    }()

    // MARK: - Duration Formatting

    /// Format seconds as duration (e.g., "2:41" or "1h 23m")
    public static func formatDuration(_ seconds: Double) -> String {
        let totalSeconds = Int(seconds)

        if totalSeconds < 60 {
            return "\(totalSeconds)s"
        } else if totalSeconds < 3600 {
            let minutes = totalSeconds / 60
            let secs = totalSeconds % 60
            return String(format: "%d:%02d", minutes, secs)
        } else {
            let hours = totalSeconds / 3600
            let minutes = (totalSeconds % 3600) / 60
            return "\(hours)h \(minutes)m"
        }
    }

    // MARK: - Relative Time Formatting

    /// Format a date as relative time (e.g., "2h ago", "just now")
    public static func formatRelativeTime(_ date: Date) -> String {
        let now = Date()
        let interval = now.timeIntervalSince(date)

        if interval < 60 {
            return "just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else if interval < 604800 {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        } else {
            return shortDateFormatter.string(from: date)
        }
    }

    /// Format a date as "as of" time
    public static func formatAsOfTime(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "as of \(timeFormatter.string(from: date))"
        } else if calendar.isDateInYesterday(date) {
            return "yesterday \(timeFormatter.string(from: date))"
        } else {
            return shortDateFormatter.string(from: date)
        }
    }

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f
    }()

    private static let shortDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .none
        return f
    }()

    // MARK: - Smart Value Detection

    /// Attempt to intelligently format a string value
    public static func smartFormat(_ string: String) -> String {
        // Try to parse as number
        if let double = Double(string.replacingOccurrences(of: ",", with: "")) {
            // Check if it looks like a percentage
            if string.hasSuffix("%") {
                return formatPercentage(double, alreadyPercent: true)
            }
            // Check if it looks like currency
            if string.hasPrefix("$") || string.hasPrefix("€") || string.hasPrefix("£") {
                return formatCurrency(double)
            }
            return formatNumber(double)
        }

        // Try to parse as ISO date
        if let date = ISO8601DateFormatter().date(from: string) {
            return formatRelativeTime(date)
        }

        // Return as-is
        return string
    }
}

// MARK: - JSONValue Extension

extension JSONValue {
    /// Get a formatted display string using smart formatting
    public var formattedDisplayString: String {
        switch self {
        case .string(let s):
            return Formatters.smartFormat(s)
        case .number(let n):
            return Formatters.formatNumber(n)
        case .bool(let b):
            return b ? "Yes" : "No"
        case .null:
            return "—"
        case .array(let arr):
            return "[\(arr.count)]"
        case .object(let obj):
            return "{\(obj.count)}"
        }
    }
}
