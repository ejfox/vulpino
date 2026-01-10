import SwiftUI

// MARK: - Design System

/// Vulpino's typographic system
/// "Typography is the feature" - opinionated, minimal, beautiful
enum VulpinoTypography {
    // Primary numbers: large, monospaced, commanding
    static let statLarge = Font.system(size: 42, weight: .medium, design: .monospaced)
    static let statMedium = Font.system(size: 28, weight: .medium, design: .monospaced)
    static let statSmall = Font.system(size: 20, weight: .medium, design: .monospaced)

    // Labels: small caps feel, understated
    static let label = Font.system(size: 11, weight: .regular, design: .default)
    static let labelSmall = Font.system(size: 9, weight: .regular, design: .default)

    // Headlines: readable, not shouty
    static let headline = Font.system(size: 17, weight: .medium, design: .default)
    static let headlineSmall = Font.system(size: 15, weight: .medium, design: .default)

    // Timestamp: quiet, informational
    static let timestamp = Font.system(size: 10, weight: .regular, design: .monospaced)

    // List items
    static let listItem = Font.system(size: 13, weight: .regular, design: .default)
}

/// Color palette - restrained, functional
enum VulpinoColors {
    static let primary = Color.primary
    static let secondary = Color.secondary
    static let tertiary = Color(white: 0.6)
    static let staleIndicator = Color.orange.opacity(0.7)
    static let background = Color(white: 0.98)
}

// MARK: - Base Widget Container

struct WidgetContainer<Content: View>: View {
    let isStale: Bool
    let content: () -> Content

    init(isStale: Bool = false, @ViewBuilder content: @escaping () -> Content) {
        self.isStale = isStale
        self.content = content
    }

    var body: some View {
        ZStack {
            VulpinoColors.background
            content()

            // Stale indicator: subtle top-right dot
            if isStale {
                VStack {
                    HStack {
                        Spacer()
                        Circle()
                            .fill(VulpinoColors.staleIndicator)
                            .frame(width: 6, height: 6)
                            .padding(8)
                    }
                    Spacer()
                }
            }
        }
    }
}

// MARK: - Template 1: Mono Stat

/// Single large number with label beneath
/// "The most important number, nothing else"
struct MonoStatView: View {
    let value: String
    let label: String
    let isStale: Bool

    var body: some View {
        WidgetContainer(isStale: isStale) {
            VStack(spacing: 4) {
                Text(value)
                    .font(VulpinoTypography.statLarge)
                    .foregroundStyle(VulpinoColors.primary)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)

                Text(label.lowercased())
                    .font(VulpinoTypography.label)
                    .foregroundStyle(VulpinoColors.secondary)
                    .tracking(0.5)
            }
            .padding()
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(label): \(value)")
            .accessibilityAddTraits(.isStaticText)
        }
    }
}

// MARK: - Template 2: Dual Stat

/// Two numbers side by side
/// "Compare at a glance"
struct DualStatView: View {
    let values: [(label: String, value: String)]
    let isStale: Bool

    var body: some View {
        WidgetContainer(isStale: isStale) {
            HStack(spacing: 24) {
                ForEach(0..<min(2, values.count), id: \.self) { i in
                    VStack(spacing: 4) {
                        Text(values[i].value)
                            .font(VulpinoTypography.statMedium)
                            .foregroundStyle(VulpinoColors.primary)
                            .minimumScaleFactor(0.6)
                            .lineLimit(1)

                        Text(values[i].label.lowercased())
                            .font(VulpinoTypography.labelSmall)
                            .foregroundStyle(VulpinoColors.secondary)
                            .tracking(0.3)
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Template 3: Stat Stack

/// 3-5 key-value pairs, vertically stacked
/// "The dashboard summary"
struct StatStackView: View {
    let values: [(label: String, value: String)]
    let isStale: Bool

    var body: some View {
        WidgetContainer(isStale: isStale) {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(0..<min(5, values.count), id: \.self) { i in
                    HStack {
                        Text(values[i].label)
                            .font(VulpinoTypography.label)
                            .foregroundStyle(VulpinoColors.secondary)

                        Spacer()

                        Text(values[i].value)
                            .font(VulpinoTypography.statSmall)
                            .foregroundStyle(VulpinoColors.primary)
                            .minimumScaleFactor(0.7)
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Template 4: Headline

/// Large text string, truncates gracefully
/// "What's happening now"
struct HeadlineView: View {
    let text: String
    let isStale: Bool

    var body: some View {
        WidgetContainer(isStale: isStale) {
            VStack {
                Text(text)
                    .font(VulpinoTypography.headline)
                    .foregroundStyle(VulpinoColors.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(4)
                    .minimumScaleFactor(0.8)
            }
            .padding()
        }
    }
}

// MARK: - Template 5: List

/// 3-5 text items
/// "Recent, top, or next"
struct ListView: View {
    let items: [String]
    let isStale: Bool
    let numbered: Bool

    init(items: [String], isStale: Bool = false, numbered: Bool = false) {
        self.items = items
        self.isStale = isStale
        self.numbered = numbered
    }

    var body: some View {
        WidgetContainer(isStale: isStale) {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(0..<min(5, items.count), id: \.self) { i in
                    HStack(alignment: .top, spacing: 8) {
                        if numbered {
                            Text("\(i + 1).")
                                .font(VulpinoTypography.listItem)
                                .foregroundStyle(VulpinoColors.tertiary)
                                .frame(width: 16, alignment: .trailing)
                        } else {
                            Text("•")
                                .font(VulpinoTypography.listItem)
                                .foregroundStyle(VulpinoColors.tertiary)
                        }

                        Text(items[i])
                            .font(VulpinoTypography.listItem)
                            .foregroundStyle(VulpinoColors.primary)
                            .lineLimit(2)
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Template 6: Grid

/// 2x2 or 3x2 grid of small stats
/// "Everything at once"
struct GridView: View {
    let values: [(label: String, value: String)]
    let isStale: Bool

    private var columns: Int {
        values.count <= 4 ? 2 : 3
    }

    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 12), count: columns)
    }

    var body: some View {
        WidgetContainer(isStale: isStale) {
            LazyVGrid(columns: gridColumns, spacing: 12) {
                ForEach(0..<min(6, values.count), id: \.self) { i in
                    VStack(spacing: 2) {
                        Text(values[i].value)
                            .font(VulpinoTypography.statSmall)
                            .foregroundStyle(VulpinoColors.primary)
                            .minimumScaleFactor(0.6)
                            .lineLimit(1)

                        Text(values[i].label.lowercased())
                            .font(VulpinoTypography.labelSmall)
                            .foregroundStyle(VulpinoColors.secondary)
                            .lineLimit(1)
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Template 7: Timestamp

/// Single value with prominent timestamp
/// "When it mattered"
struct TimestampView: View {
    let value: String
    let label: String
    let timestamp: Date?
    let isStale: Bool

    private var timeString: String {
        guard let timestamp = timestamp else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return "as of \(formatter.string(from: timestamp))"
    }

    var body: some View {
        WidgetContainer(isStale: isStale) {
            VStack(spacing: 6) {
                Text(value)
                    .font(VulpinoTypography.statLarge)
                    .foregroundStyle(VulpinoColors.primary)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)

                Text(label.lowercased())
                    .font(VulpinoTypography.label)
                    .foregroundStyle(VulpinoColors.secondary)
                    .tracking(0.5)

                if timestamp != nil {
                    Text(timeString)
                        .font(VulpinoTypography.timestamp)
                        .foregroundStyle(VulpinoColors.tertiary)
                }
            }
            .padding()
        }
    }
}

// MARK: - Error View

struct WidgetErrorView: View {
    let message: String

    var body: some View {
        WidgetContainer {
            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 24))
                    .foregroundStyle(VulpinoColors.tertiary)

                Text(message)
                    .font(VulpinoTypography.label)
                    .foregroundStyle(VulpinoColors.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
    }
}

// MARK: - Template Renderer

/// Renders the appropriate template view based on config and data
struct TemplateRenderer: View {
    let template: WidgetTemplate
    let data: WidgetDisplayData

    var body: some View {
        Group {
            if let error = data.error {
                WidgetErrorView(message: error)
            } else {
                switch template {
                case .monoStat:
                    if let first = data.values.first {
                        MonoStatView(value: first.value, label: first.label, isStale: data.isStale)
                    }

                case .dualStat:
                    DualStatView(values: data.values, isStale: data.isStale)

                case .statStack:
                    StatStackView(values: data.values, isStale: data.isStale)

                case .headline:
                    if let first = data.values.first {
                        HeadlineView(text: first.value, isStale: data.isStale)
                    }

                case .list:
                    ListView(items: data.values.map(\.value), isStale: data.isStale)

                case .grid:
                    GridView(values: data.values, isStale: data.isStale)

                case .timestamp:
                    if let first = data.values.first {
                        TimestampView(
                            value: first.value,
                            label: first.label,
                            timestamp: data.timestamp,
                            isStale: data.isStale
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Mono Stat") {
    MonoStatView(value: "12,847", label: "page views", isStale: false)
        .frame(width: 155, height: 155)
}

#Preview("Dual Stat") {
    DualStatView(
        values: [("today", "847"), ("yesterday", "1,203")],
        isStale: false
    )
    .frame(width: 155, height: 155)
}

#Preview("Stat Stack") {
    StatStackView(
        values: [
            ("visitors", "2.4k"),
            ("bounce", "34%"),
            ("avg time", "2:41"),
            ("pages", "4.7")
        ],
        isStale: true
    )
    .frame(width: 155, height: 155)
}

#Preview("Headline") {
    HeadlineView(text: "Deploy to production", isStale: false)
        .frame(width: 155, height: 155)
}

#Preview("List") {
    ListView(
        items: ["Fix auth bug", "Review PR #42", "Update docs", "Call with Sam"],
        isStale: false
    )
    .frame(width: 155, height: 155)
}

#Preview("Grid") {
    GridView(
        values: [
            ("users", "142"),
            ("cpu", "58%"),
            ("mem", "3.2"),
            ("errors", "24"),
            ("up", "99%"),
            ("req", "847")
        ],
        isStale: false
    )
    .frame(width: 329, height: 155)
}

#Preview("Timestamp") {
    TimestampView(
        value: "$142.58",
        label: "AAPL price",
        timestamp: Date(),
        isStale: false
    )
    .frame(width: 155, height: 155)
}
