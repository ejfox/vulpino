import AppIntents
import WidgetKit

/// Intent for selecting which widget configuration to display
struct SelectWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Select Widget"
    static var description = IntentDescription("Choose which widget to display")

    @Parameter(title: "Widget")
    var widgetConfig: WidgetConfigEntity?

    init() {}

    init(widgetConfig: WidgetConfigEntity?) {
        self.widgetConfig = widgetConfig
    }
}

/// Entity representing a widget configuration for the intent system
struct WidgetConfigEntity: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Widget")
    static var defaultQuery = WidgetConfigQuery()

    var id: String
    var name: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }

    init(id: String, name: String) {
        self.id = id
        self.name = name
    }

    init(from config: WidgetConfig) {
        self.id = config.id.uuidString
        self.name = config.name
    }
}

/// Query for fetching available widget configurations
struct WidgetConfigQuery: EntityQuery {
    func entities(for identifiers: [WidgetConfigEntity.ID]) async throws -> [WidgetConfigEntity] {
        let configs = StorageService.shared.loadConfigs()
        return configs
            .filter { identifiers.contains($0.id.uuidString) }
            .map { WidgetConfigEntity(from: $0) }
    }

    func suggestedEntities() async throws -> [WidgetConfigEntity] {
        let configs = StorageService.shared.loadConfigs()
        return configs.map { WidgetConfigEntity(from: $0) }
    }

    func defaultResult() async -> WidgetConfigEntity? {
        let configs = StorageService.shared.loadConfigs()
        return configs.first.map { WidgetConfigEntity(from: $0) }
    }
}
