import SwiftUI

/// The main widget creation/editing flow
struct WidgetEditorView: View {
    @StateObject private var viewModel: WidgetEditorViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showingSuccess = false
    @State private var savedConfig: WidgetConfig?

    var onSave: ((WidgetConfig) -> Void)?

    init(config: WidgetConfig? = nil, onSave: ((WidgetConfig) -> Void)? = nil) {
        self._viewModel = StateObject(wrappedValue: WidgetEditorViewModel(config: config))
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Group {
                if showingSuccess, let config = savedConfig {
                    WidgetCreatedView(widgetName: config.name) {
                        onSave?(config)
                        dismiss()
                    }
                } else {
                    VStack(spacing: 0) {
                        // Progress indicator
                        StepIndicator(currentStep: viewModel.currentStep)
                            .padding()

                        Divider()

                        // Step content
                        Group {
                            switch viewModel.currentStep {
                            case .url:
                                URLInputStep(viewModel: viewModel)
                            case .selectData:
                                DataSelectionStep(viewModel: viewModel)
                            case .chooseTemplate:
                                TemplateSelectionStep(viewModel: viewModel)
                            case .customize:
                                CustomizeStep(viewModel: viewModel)
                            }
                        }
                    }
                    .navigationTitle(viewModel.isEditing ? "Edit Widget" : "New Widget")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                dismiss()
                            }
                        }

                        if viewModel.currentStep == .customize {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Save") {
                                    let config = viewModel.save()
                                    savedConfig = config
                                    withAnimation {
                                        showingSuccess = true
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Step Indicator

struct StepIndicator: View {
    let currentStep: WidgetEditorViewModel.Step

    var body: some View {
        HStack(spacing: 0) {
            ForEach(WidgetEditorViewModel.Step.allCases, id: \.rawValue) { step in
                HStack(spacing: 8) {
                    Circle()
                        .fill(step.rawValue <= currentStep.rawValue ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)

                    if step.rawValue < WidgetEditorViewModel.Step.allCases.count - 1 {
                        Rectangle()
                            .fill(step.rawValue < currentStep.rawValue ? Color.blue : Color.gray.opacity(0.3))
                            .frame(height: 2)
                    }
                }
            }
        }
        .frame(maxWidth: 200)
    }
}

// MARK: - Step 1: URL Input

struct URLInputStep: View {
    @ObservedObject var viewModel: WidgetEditorViewModel
    @FocusState private var isURLFocused: Bool
    @State private var showingExamples = false
    @State private var testResult: TestResult?

    enum TestResult {
        case testing
        case success(TimeInterval)
        case failure(String)
    }

    private let exampleEndpoints = [
        ("GitHub Status", "https://www.githubstatus.com/api/v2/status.json"),
        ("CoinGecko BTC", "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd"),
        ("JSONPlaceholder", "https://jsonplaceholder.typicode.com/todos/1"),
        ("Cat Fact", "https://catfact.ninja/fact"),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // URL Input
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("JSON Endpoint")
                            .font(.headline)

                        Spacer()

                        Button {
                            showingExamples = true
                        } label: {
                            Text("Examples")
                                .font(.caption)
                        }
                    }

                    HStack(spacing: 8) {
                        TextField("https://api.example.com/data.json", text: $viewModel.urlString)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.URL)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .focused($isURLFocused)
                            .onChange(of: viewModel.urlString) { _, _ in
                                testResult = nil
                                viewModel.error = nil
                            }
                            .onSubmit {
                                if viewModel.canProceedFromURL {
                                    Task { await viewModel.fetchJSON() }
                                }
                            }

                        // Test button
                        if viewModel.canProceedFromURL {
                            Button {
                                testEndpoint()
                            } label: {
                                Group {
                                    switch testResult {
                                    case .testing:
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    case .success:
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                    case .failure:
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.red)
                                    case nil:
                                        Image(systemName: "arrow.clockwise.circle")
                                            .foregroundStyle(.blue)
                                    }
                                }
                                .frame(width: 24, height: 24)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // URL validation feedback
                    if !viewModel.urlString.isEmpty {
                        HStack(spacing: 4) {
                            if viewModel.canProceedFromURL {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                                Text("Valid URL")
                                    .font(.caption)
                                    .foregroundStyle(.green)

                                if case .success(let latency) = testResult {
                                    Text("• \(Int(latency * 1000))ms")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            } else {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                                Text("Enter a valid https:// URL")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                            Spacer()
                        }
                    } else {
                        Text("Paste any public URL that returns JSON")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Headers
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Headers")
                            .font(.headline)

                        Spacer()

                        Button {
                            Haptics.tap()
                            viewModel.addHeader()
                        } label: {
                            Label("Add", systemImage: "plus.circle")
                                .font(.subheadline)
                        }
                    }

                    if viewModel.headers.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle")
                                .foregroundStyle(.secondary)
                            Text("Optional: Add API keys or Bearer tokens for authenticated endpoints")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(12)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        ForEach(viewModel.headers.indices, id: \.self) { index in
                            HeaderRow(
                                header: $viewModel.headers[index],
                                onDelete: {
                                    Haptics.tap()
                                    viewModel.removeHeader(at: index)
                                }
                            )
                        }

                        Text("Headers are stored securely in your device's Keychain")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }

                // Error
                if let error = viewModel.error {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Request Failed")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.red.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                Spacer(minLength: 40)

                // Fetch button
                Button {
                    Haptics.confirm()
                    Task { await viewModel.fetchJSON() }
                } label: {
                    HStack(spacing: 8) {
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "arrow.down.doc")
                            Text("Fetch JSON")
                        }
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.canProceedFromURL ? Color.blue : Color.gray.opacity(0.5))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(!viewModel.canProceedFromURL || viewModel.isLoading)
            }
            .padding()
        }
        .onAppear {
            isURLFocused = true
            Haptics.prepare()
        }
        .sheet(isPresented: $showingExamples) {
            ExampleEndpointsSheet(examples: exampleEndpoints) { url in
                viewModel.urlString = url
                showingExamples = false
            }
        }
    }

    private func testEndpoint() {
        testResult = .testing
        Task {
            let result = await APIService.shared.testEndpoint(
                url: viewModel.urlString,
                headers: viewModel.headers
            )
            if result.success, let latency = result.latency {
                testResult = .success(latency)
                Haptics.success()
            } else {
                testResult = .failure(result.error?.localizedDescription ?? "Unknown error")
                Haptics.error()
            }
        }
    }
}

struct ExampleEndpointsSheet: View {
    let examples: [(String, String)]
    let onSelect: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(examples, id: \.1) { name, url in
                        Button {
                            onSelect(url)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(name)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text(url)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                } header: {
                    Text("Try These Public APIs")
                } footer: {
                    Text("These are free, public endpoints you can use to test Vulpino.")
                }
            }
            .navigationTitle("Examples")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

struct HeaderRow: View {
    @Binding var header: HTTPHeader
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            TextField("Key", text: $header.key)
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.none)
                .frame(maxWidth: 120)

            SecureField("Value", text: $header.value)
                .textFieldStyle(.roundedBorder)

            Button {
                onDelete()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Step 2: Data Selection

struct DataSelectionStep: View {
    @ObservedObject var viewModel: WidgetEditorViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Selection info
            HStack {
                Text("Select \(viewModel.selectedTemplate.minBindings)-\(viewModel.selectedTemplate.maxBindings) values")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(viewModel.selectedPaths.count) selected")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(viewModel.canProceedFromData ? .blue : .secondary)
            }
            .padding()

            Divider()

            // JSON Tree
            ScrollView {
                JSONTreeView(
                    nodes: viewModel.jsonNodes,
                    selectedPaths: $viewModel.selectedPaths,
                    maxSelections: viewModel.selectedTemplate.maxBindings
                )
            }

            Divider()

            // Navigation
            HStack {
                Button {
                    Haptics.tap()
                    viewModel.goBack()
                } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }

                Spacer()

                Button {
                    Haptics.confirm()
                    viewModel.proceedToTemplate()
                } label: {
                    HStack {
                        Text("Choose Template")
                        Image(systemName: "chevron.right")
                    }
                    .fontWeight(.medium)
                }
                .disabled(!viewModel.canProceedFromData)
            }
            .padding()
        }
        .onChange(of: viewModel.selectedPaths) { _, _ in
            Haptics.select()
        }
    }
}

// MARK: - Step 3: Template Selection

struct TemplateSelectionStep: View {
    @ObservedObject var viewModel: WidgetEditorViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Template grid
            TemplatePickerView(
                selectedTemplate: $viewModel.selectedTemplate,
                previewData: viewModel.previewData
            )

            Divider()

            // Size picker
            VStack(spacing: 12) {
                Text("Widget Size")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                SizePickerView(
                    selectedSize: $viewModel.selectedSize,
                    availableSizes: viewModel.selectedTemplate.supportedSizes
                )
            }
            .padding()

            Divider()

            // Navigation
            HStack {
                Button {
                    Haptics.tap()
                    viewModel.goBack()
                } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }

                Spacer()

                Button {
                    Haptics.confirm()
                    viewModel.proceedToCustomize()
                } label: {
                    HStack {
                        Text("Customize")
                        Image(systemName: "chevron.right")
                    }
                    .fontWeight(.medium)
                }
                .disabled(!viewModel.canProceedFromTemplate)
            }
            .padding()
        }
        .onChange(of: viewModel.selectedTemplate) { _, newTemplate in
            Haptics.select()
            // Auto-select compatible size
            if !newTemplate.supportedSizes.contains(viewModel.selectedSize) {
                viewModel.selectedSize = newTemplate.supportedSizes.first ?? .small
            }
        }
        .onChange(of: viewModel.selectedSize) { _, _ in
            Haptics.select()
        }
    }
}

// MARK: - Step 4: Customize

struct CustomizeStep: View {
    @ObservedObject var viewModel: WidgetEditorViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Live preview
                VStack(alignment: .leading, spacing: 8) {
                    Text("Preview")
                        .font(.headline)

                    TemplateRenderer(
                        template: viewModel.selectedTemplate,
                        data: viewModel.previewData
                    )
                    .frame(height: 155)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: .black.opacity(0.1), radius: 10)
                }

                // Widget name
                VStack(alignment: .leading, spacing: 8) {
                    Text("Widget Name")
                        .font(.headline)

                    TextField("My Widget", text: $viewModel.widgetName)
                        .textFieldStyle(.roundedBorder)
                }

                // Labels
                VStack(alignment: .leading, spacing: 12) {
                    Text("Labels")
                        .font(.headline)

                    Text("Customize how each value is labeled in your widget")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    ForEach(viewModel.bindings.indices, id: \.self) { index in
                        LabelRow(binding: $viewModel.bindings[index])
                    }
                }

                // Refresh interval
                VStack(alignment: .leading, spacing: 8) {
                    Text("Refresh Interval")
                        .font(.headline)

                    Picker("Interval", selection: $viewModel.refreshInterval) {
                        ForEach(RefreshInterval.allCases) { interval in
                            Text(interval.displayName).tag(interval)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text("iOS may adjust refresh timing to optimize battery life")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                // Tap action
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tap Action")
                        .font(.headline)

                    TextField("https://... (optional)", text: $viewModel.tapURL)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.URL)
                        .autocapitalization(.none)

                    Text("Open a URL when tapping the widget. Leave empty to open Vulpino.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Back button
                Button {
                    Haptics.tap()
                    viewModel.goBack()
                } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back to Templates")
                    }
                    .foregroundStyle(.secondary)
                }
                .padding(.top)
            }
            .padding()
        }
    }
}

struct LabelRow: View {
    @Binding var binding: DataBinding

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(binding.jsonPath)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.tertiary)

            TextField("Label", text: $binding.label)
                .textFieldStyle(.roundedBorder)
        }
    }
}

// MARK: - Preview

#Preview {
    WidgetEditorView()
}
