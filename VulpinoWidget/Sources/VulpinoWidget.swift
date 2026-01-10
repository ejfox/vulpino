import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct VulpinoTimelineProvider: IntentTimelineProvider {
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

    func getSnapshot(for configuration: SelectWidgetIntent, in context: Context, completion: @escaping (VulpinoWidgetEntry) -> Void) {
        let entry = placeholder(in: context)
        completion(entry)
    }

    func getTimeline(for configuration: SelectWidgetIntent, in context: Context, completion: @escaping (Timeline<VulpinoWidgetEntry>) -> Void) {
        Task {
            // Get config ID from intent
            guard let configIdString = configuration.widgetConfig?.identifier,
                  let configId = UUID(uuidString: configIdString) else {
                // No config selected - show placeholder
                let entry = VulpinoWidgetEntry(
                    date: Date(),
                    config: nil,
                    displayData: WidgetDisplayData(error: "Tap to configure")
                )
                let timeline = Timeline(entries: [entry], policy: .never)
                completion(timeline)
                return
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

            let timeline = Timeline(entries: [entry], policy: .after(nextRefresh))
            completion(timeline)
        }
    }
}

// MARK: - Widget Entry

struct VulpinoWidgetEntry: TimelineEntry {
    let date: Date
    let config: WidgetConfig?
    let displayData: WidgetDisplayData
}

// MARK: - Widget View

struct VulpinoWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: VulpinoWidgetEntry

    var body: some View {
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
}

// MARK: - Widget Configuration

struct VulpinoWidget: Widget {
    let kind: String = "VulpinoWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(
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
