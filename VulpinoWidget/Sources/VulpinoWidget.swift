import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct VulpinoTimelineProvider: AppIntentTimelineProvider {
    typealias Entry = VulpinoWidgetEntry
    typealias Intent = SelectWidgetIntent

    func placeholder(in context: Context) -> VulpinoWidgetEntry {
        VulpinoWidgetEntry(
            date: Date(),
            config: nil,
            displayData: WidgetDisplayData(
                values: [("sample", "1,234")],
                timestamp: Date()
            )
        )
    }

    func snapshot(for configuration: SelectWidgetIntent, in context: Context) async -> VulpinoWidgetEntry {
        placeholder(in: context)
    }

    func timeline(for configuration: SelectWidgetIntent, in context: Context) async -> Timeline<VulpinoWidgetEntry> {
        // Get config ID from intent
        guard let configIdString = configuration.widgetConfig?.id,
              let configId = UUID(uuidString: configIdString) else {
            // No config selected - show placeholder
            let entry = VulpinoWidgetEntry(
                date: Date(),
                config: nil,
                displayData: WidgetDisplayData(error: "Tap to configure")
            )
            return Timeline(entries: [entry], policy: .never)
        }

        // Fetch fresh data
        let displayData = await StorageService.shared.refreshWidget(configId: configId)
        let config = StorageService.shared.getConfig(id: configId)

        let entry = VulpinoWidgetEntry(
            date: Date(),
            config: config,
            displayData: displayData
        )

        // Calculate next refresh
        let refreshInterval = config?.refreshInterval.timeInterval ?? 1800
        let nextRefresh = Date().addingTimeInterval(refreshInterval)

        return Timeline(entries: [entry], policy: .after(nextRefresh))
    }
}

// MARK: - Widget Entry

struct VulpinoWidgetEntry: TimelineEntry {
    let date: Date
    let config: WidgetConfig?
    let displayData: WidgetDisplayData

    /// The URL to open when the widget is tapped
    var widgetURL: URL? {
        // If config has a custom tap URL, use that
        if let config = config, let tapURL = config.tapURL, let url = URL(string: tapURL) {
            return url
        }

        // Otherwise, deep link to the widget's edit screen in the app
        if let config = config {
            return URL(string: "vulpino://widget/\(config.id.uuidString)")
        }

        // Fallback to just opening the app
        return URL(string: "vulpino://")
    }
}

// MARK: - Widget View

struct VulpinoWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: VulpinoWidgetEntry

    var body: some View {
        Group {
            if let config = entry.config {
                TemplateRenderer(template: config.template, data: entry.displayData)
            } else {
                // Placeholder for unconfigured widget
                VStack(spacing: 8) {
                    Image(systemName: "square.grid.2x2")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)

                    if let error = entry.displayData.error {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(VulpinoColors.background)
            }
        }
        .widgetURL(entry.widgetURL)
    }
}

// MARK: - Widget Configuration

struct VulpinoWidget: Widget {
    let kind: String = "VulpinoWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: SelectWidgetIntent.self,
            provider: VulpinoTimelineProvider()
        ) { entry in
            VulpinoWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    VulpinoColors.background
                }
        }
        .configurationDisplayName("Vulpino")
        .description("Display data from any JSON endpoint")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}

// MARK: - Widget Bundle

@main
struct VulpinoWidgetBundle: WidgetBundle {
    var body: some Widget {
        VulpinoWidget()
    }
}

// MARK: - Previews

#Preview("Small", as: .systemSmall) {
    VulpinoWidget()
} timeline: {
    VulpinoWidgetEntry(
        date: Date(),
        config: WidgetConfig(
            name: "Page Views",
            template: .monoStat
        ),
        displayData: WidgetDisplayData(
            values: [("page views", "12,847")],
            timestamp: Date()
        )
    )
}

#Preview("Medium", as: .systemMedium) {
    VulpinoWidget()
} timeline: {
    VulpinoWidgetEntry(
        date: Date(),
        config: WidgetConfig(
            name: "Stats",
            template: .statStack
        ),
        displayData: WidgetDisplayData(
            values: [
                ("visitors", "2.4k"),
                ("bounce", "34%"),
                ("avg time", "2:41")
            ],
            timestamp: Date()
        )
    )
}

#Preview("Large", as: .systemLarge) {
    VulpinoWidget()
} timeline: {
    VulpinoWidgetEntry(
        date: Date(),
        config: WidgetConfig(
            name: "Dashboard",
            template: .grid
        ),
        displayData: WidgetDisplayData(
            values: [
                ("users", "142"),
                ("cpu", "58%"),
                ("memory", "3.2GB"),
                ("errors", "24"),
                ("uptime", "99.9%"),
                ("requests", "847/s")
            ],
            timestamp: Date()
        )
    )
}
