import SwiftUI

/// The main widget creation/editing flow
struct WidgetEditorView: View {
    @StateObject private var viewModel: WidgetEditorViewModel
    @Environment(\.dismiss) private var dismiss

    var onSave: ((WidgetConfig) -> Void)?

    init(config: WidgetConfig? = nil, onSave: ((WidgetConfig) -> Void)? = nil) {
        self._viewModel = StateObject(wrappedValue: WidgetEditorViewModel(config: config))
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
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
                            onSave?(config)
                            dismiss()
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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // URL Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("JSON Endpoint")
                        .font(.headline)

                    TextField("https://api.example.com/data.json", text: $viewModel.urlString)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.URL)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .focused($isURLFocused)
                        .onSubmit {
                            if viewModel.canProceedFromURL {
                                Task { await viewModel.fetchJSON() }
                            }
                        }

                    Text("Paste any public URL that returns JSON")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Headers
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Headers")
                            .font(.headline)

                        Spacer()

                        Button {
                            viewModel.addHeader()
                        } label: {
                            Label("Add", systemImage: "plus.circle")
                                .font(.subheadline)
                        }
                    }

                    if viewModel.headers.isEmpty {
                        Text("Optional: Add API keys or auth tokens")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.headers.indices, id: \.self) { index in
                            HeaderRow(
                                header: $viewModel.headers[index],
                                onDelete: { viewModel.removeHeader(at: index) }
                            )
                        }
                    }
                }

                // Error
                if let error = viewModel.error {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                        Text(error)
                            .font(.subheadline)
                            .foregroundStyle(.red)
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                Spacer()

                // Fetch button
                Button {
                    Task { await viewModel.fetchJSON() }
                } label: {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Fetch JSON")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.canProceedFromURL ? Color.blue : Color.gray)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!viewModel.canProceedFromURL || viewModel.isLoading)
            }
            .padding()
        }
        .onAppear {
            isURLFocused = true
        }
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

            TextField("Value", text: $header.value)
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.none)

            Button {
                onDelete()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
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
                    viewModel.goBack()
                } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }

                Spacer()

                Button {
                    viewModel.proceedToTemplate()
                } label: {
                    HStack {
                        Text("Choose Template")
                        Image(systemName: "chevron.right")
                    }
                }
                .disabled(!viewModel.canProceedFromData)
            }
            .padding()
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
                    viewModel.goBack()
                } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }

                Spacer()

                Button {
                    viewModel.proceedToCustomize()
                } label: {
                    HStack {
                        Text("Customize")
                        Image(systemName: "chevron.right")
                    }
                }
                .disabled(!viewModel.canProceedFromTemplate)
            }
            .padding()
        }
        .onChange(of: viewModel.selectedTemplate) { _, newTemplate in
            // Auto-select compatible size
            if !newTemplate.supportedSizes.contains(viewModel.selectedSize) {
                viewModel.selectedSize = newTemplate.supportedSizes.first ?? .small
            }
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
                VStack(alignment: .leading, spacing: 8) {
                    Text("Labels")
                        .font(.headline)

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
                }

                // Tap action
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tap Action")
                        .font(.headline)

                    TextField("https://... (optional)", text: $viewModel.tapURL)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.URL)
                        .autocapitalization(.none)

                    Text("Open a URL when tapping the widget")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Back button
                Button {
                    viewModel.goBack()
                } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back to Templates")
                    }
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
        HStack {
            Text(binding.jsonPath)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Spacer()

            TextField("Label", text: $binding.label)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 150)
        }
    }
}

// MARK: - Preview

#Preview {
    WidgetEditorView()
}
