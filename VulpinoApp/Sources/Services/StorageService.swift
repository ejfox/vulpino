import Foundation

/// Service for persisting widget configurations and cached data
/// Uses App Group container for sharing between app and widget extension
public final class StorageService: @unchecked Sendable {
    public static let shared = StorageService()

    private let appGroupId = "group.com.vulpino.widgets"
    private let configsFileName = "widget_configs.json"
    private let cacheFileName = "widget_cache.json"

    private var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId)
    }

    private var configsURL: URL? {
        containerURL?.appendingPathComponent(configsFileName)
    }

    private var cacheURL: URL? {
        containerURL?.appendingPathComponent(cacheFileName)
    }

    // Fallback to documents directory if app group not available
    private var fallbackConfigsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(configsFileName)
    }

    private var fallbackCacheURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(cacheFileName)
    }

    private init() {}

    // MARK: - Widget Configs

    /// Load all widget configurations
    public func loadConfigs() -> [WidgetConfig] {
        let url = configsURL ?? fallbackConfigsURL

        guard FileManager.default.fileExists(atPath: url.path) else {
            return []
        }

        do {
            let data = try Data(contentsOf: url)
            let configs = try JSONDecoder().decode([WidgetConfig].self, from: data)
            return configs.sorted { $0.updatedAt > $1.updatedAt }
        } catch {
            print("Failed to load configs: \(error)")
            return []
        }
    }

    /// Save all widget configurations
    public func saveConfigs(_ configs: [WidgetConfig]) {
        let url = configsURL ?? fallbackConfigsURL

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(configs)
            try data.write(to: url, options: .atomic)
        } catch {
            print("Failed to save configs: \(error)")
        }
    }

    /// Get a specific config by ID
    public func getConfig(id: UUID) -> WidgetConfig? {
        loadConfigs().first { $0.id == id }
    }

    /// Save or update a single config
    public func saveConfig(_ config: WidgetConfig) {
        var configs = loadConfigs()
        if let index = configs.firstIndex(where: { $0.id == config.id }) {
            configs[index] = config
        } else {
            configs.append(config)
        }
        saveConfigs(configs)
    }

    /// Delete a config by ID
    public func deleteConfig(id: UUID) {
        var configs = loadConfigs()
        configs.removeAll { $0.id == id }
        saveConfigs(configs)

        // Also remove cached data
        deleteCache(configId: id)
    }

    /// Duplicate a config
    public func duplicateConfig(_ config: WidgetConfig) -> WidgetConfig {
        var newConfig = config
        newConfig.id = UUID()
        newConfig.name = "\(config.name) (Copy)"
        newConfig.createdAt = Date()
        newConfig.updatedAt = Date()
        saveConfig(newConfig)
        return newConfig
    }

    // MARK: - Cached Data

    /// Load all cached data
    private func loadAllCache() -> [UUID: CachedWidgetData] {
        let url = cacheURL ?? fallbackCacheURL

        guard FileManager.default.fileExists(atPath: url.path) else {
            return [:]
        }

        do {
            let data = try Data(contentsOf: url)
            let caches = try JSONDecoder().decode([CachedWidgetData].self, from: data)
            return Dictionary(uniqueKeysWithValues: caches.map { ($0.configId, $0) })
        } catch {
            print("Failed to load cache: \(error)")
            return [:]
        }
    }

    /// Save all cached data
    private func saveAllCache(_ cache: [UUID: CachedWidgetData]) {
        let url = cacheURL ?? fallbackCacheURL

        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(Array(cache.values))
            try data.write(to: url, options: .atomic)
        } catch {
            print("Failed to save cache: \(error)")
        }
    }

    /// Get cached data for a config
    public func getCache(configId: UUID) -> CachedWidgetData? {
        loadAllCache()[configId]
    }

    /// Save cached data for a config
    public func saveCache(_ data: CachedWidgetData) {
        var cache = loadAllCache()
        cache[data.configId] = data
        saveAllCache(cache)
    }

    /// Delete cached data for a config
    public func deleteCache(configId: UUID) {
        var cache = loadAllCache()
        cache.removeValue(forKey: configId)
        saveAllCache(cache)
    }

    /// Mark cached data as stale
    public func markStale(configId: UUID) {
        var cache = loadAllCache()
        if var data = cache[configId] {
            data = CachedWidgetData(
                configId: data.configId,
                jsonData: data.jsonData,
                fetchedAt: data.fetchedAt,
                isStale: true
            )
            cache[configId] = data
            saveAllCache(cache)
        }
    }
}

// MARK: - Widget Timeline Support

extension StorageService {
    /// Get display data for a widget (used by widget extension)
    public func getDisplayData(configId: UUID) -> WidgetDisplayData {
        guard let config = getConfig(id: configId) else {
            return WidgetDisplayData(error: "Widget not found")
        }

        let cache = getCache(configId: configId)
        return WidgetDisplayData.from(config: config, cache: cache)
    }

    /// Refresh data for a widget and return display data
    public func refreshWidget(configId: UUID) async -> WidgetDisplayData {
        guard let config = getConfig(id: configId) else {
            return WidgetDisplayData(error: "Widget not found")
        }

        do {
            let json = try await APIService.shared.fetch(
                url: config.endpointURL,
                headers: config.headers
            )

            let cache = CachedWidgetData(
                configId: configId,
                jsonData: json
            )
            saveCache(cache)

            return WidgetDisplayData.from(config: config, cache: cache)
        } catch {
            // On error, return cached data marked as stale
            markStale(configId: configId)

            var displayData = getDisplayData(configId: configId)
            if displayData.values.isEmpty {
                displayData = WidgetDisplayData(error: error.localizedDescription)
            }
            return displayData
        }
    }
}
