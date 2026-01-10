import Foundation
import SwiftUI

/// View model for the widget creation/editing flow
@MainActor
final class WidgetEditorViewModel: ObservableObject {
    // MARK: - State

    enum Step: Int, CaseIterable {
        case url = 0
        case selectData = 1
        case chooseTemplate = 2
        case customize = 3

        var title: String {
            switch self {
            case .url: return "Endpoint"
            case .selectData: return "Data"
            case .chooseTemplate: return "Template"
            case .customize: return "Customize"
            }
        }
    }

    @Published var currentStep: Step = .url

    // Step 1: URL
    @Published var urlString: String = ""
    @Published var headers: [HTTPHeader] = []
    @Published var isLoading: Bool = false
    @Published var error: String?

    // Step 2: Data Selection
    @Published var fetchedJSON: JSONValue?
    @Published var jsonNodes: [APIService.JSONNode] = []
    @Published var selectedPaths: Set<String> = []

    // Step 3: Template
    @Published var selectedTemplate: WidgetTemplate = .monoStat
    @Published var selectedSize: WidgetSize = .small

    // Step 4: Customize
    @Published var widgetName: String = "New Widget"
    @Published var bindings: [DataBinding] = []
    @Published var tapURL: String = ""
    @Published var refreshInterval: RefreshInterval = .thirtyMinutes

    // Editing mode
    private var existingConfig: WidgetConfig?

    var isEditing: Bool {
        existingConfig != nil
    }

    // MARK: - Computed

    var canProceedFromURL: Bool {
        guard let url = URL(string: urlString) else { return false }
        return url.scheme == "http" || url.scheme == "https"
    }

    var canProceedFromData: Bool {
        !selectedPaths.isEmpty && selectedPaths.count <= selectedTemplate.maxBindings
    }

    var canProceedFromTemplate: Bool {
        selectedPaths.count >= selectedTemplate.minBindings &&
        selectedTemplate.supportedSizes.contains(selectedSize)
    }

    var previewData: WidgetDisplayData {
        guard let json = fetchedJSON else {
            return WidgetDisplayData(values: [("sample", "123")])
        }

        var values: [(String, String)] = []
        for path in selectedPaths.sorted() {
            let value = json.value(at: path)
            let label = bindings.first(where: { $0.jsonPath == path })?.label ?? path.components(separatedBy: ".").last ?? path
            values.append((label, value?.displayString ?? "—"))
        }

        return WidgetDisplayData(values: values)
    }

    // MARK: - Initialization

    init(config: WidgetConfig? = nil) {
        if let config = config {
            self.existingConfig = config
            loadFromConfig(config)
        }
    }

    private func loadFromConfig(_ config: WidgetConfig) {
        urlString = config.endpointURL
        headers = config.headers
        selectedTemplate = config.template
        selectedSize = config.size
        widgetName = config.name
        bindings = config.bindings
        selectedPaths = Set(config.bindings.map(\.jsonPath))
        tapURL = config.tapURL ?? ""
        refreshInterval = config.refreshInterval
    }

    // MARK: - Actions

    func fetchJSON() async {
        guard canProceedFromURL else { return }

        isLoading = true
        error = nil

        do {
            let json = try await APIService.shared.fetch(url: urlString, headers: headers)
            fetchedJSON = json
            jsonNodes = APIService.shared.buildStructure(from: json)
            currentStep = .selectData
        } catch let apiError as APIError {
            error = apiError.errorDescription
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func addHeader() {
        headers.append(HTTPHeader(key: "", value: ""))
    }

    func removeHeader(at index: Int) {
        guard headers.indices.contains(index) else { return }
        headers.remove(at: index)
    }

    func proceedToTemplate() {
        // Create initial bindings from selected paths
        bindings = selectedPaths.enumerated().map { index, path in
            let existingLabel = self.bindings.first(where: { $0.jsonPath == path })?.label
            let defaultLabel = path.components(separatedBy: ".").last ?? path
            return DataBinding(
                jsonPath: path,
                label: existingLabel ?? defaultLabel,
                order: index
            )
        }
        currentStep = .chooseTemplate
    }

    func proceedToCustomize() {
        // Update bindings to match template requirements
        let sortedPaths = Array(selectedPaths.sorted().prefix(selectedTemplate.maxBindings))
        bindings = sortedPaths.enumerated().map { index, path in
            let existingLabel = self.bindings.first(where: { $0.jsonPath == path })?.label
            let defaultLabel = path.components(separatedBy: ".").last ?? path
            return DataBinding(
                jsonPath: path,
                label: existingLabel ?? defaultLabel,
                order: index
            )
        }
        currentStep = .customize
    }

    func goBack() {
        guard let currentIndex = Step.allCases.firstIndex(of: currentStep), currentIndex > 0 else { return }
        currentStep = Step.allCases[currentIndex - 1]
    }

    func save() -> WidgetConfig {
        var config = existingConfig ?? WidgetConfig()

        config.name = widgetName.isEmpty ? "Widget" : widgetName
        config.endpointURL = urlString
        config.headers = headers.filter { !$0.key.isEmpty }
        config.bindings = bindings
        config.template = selectedTemplate
        config.size = selectedSize
        config.tapURL = tapURL.isEmpty ? nil : tapURL
        config.refreshInterval = refreshInterval
        config.updatedAt = Date()

        // Save headers securely
        if !config.headers.isEmpty {
            try? KeychainService.shared.saveHeaders(config.headers, for: config.id)
        }

        // Save config
        StorageService.shared.saveConfig(config)

        // Pre-cache the data
        if let json = fetchedJSON {
            let cache = CachedWidgetData(configId: config.id, jsonData: json)
            StorageService.shared.saveCache(cache)
        }

        return config
    }
}
