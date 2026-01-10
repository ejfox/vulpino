import SwiftUI

/// Main list of all configured widgets
struct WidgetListView: View {
    @StateObject private var viewModel = WidgetListViewModel()
    @State private var showingEditor = false
    @State private var editingConfig: WidgetConfig?

    /// Deep link binding from app - when set, opens the widget editor for that ID
    @Binding var deepLinkedWidgetId: UUID?

    init(deepLinkedWidgetId: Binding<UUID?> = .constant(nil)) {
        self._deepLinkedWidgetId = deepLinkedWidgetId
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.configs.isEmpty {
                    EmptyStateView(onCreateFirst: { showingEditor = true })
                } else {
                    List {
                        ForEach(viewModel.configs) { config in
                            WidgetListRow(config: config)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    Haptics.tap()
                                    editingConfig = config
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        Haptics.warning()
                                        viewModel.delete(config)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }

                                    Button {
                                        Haptics.tap()
                                        viewModel.duplicate(config)
                                    } label: {
                                        Label("Duplicate", systemImage: "doc.on.doc")
                                    }
                                    .tint(.blue)
                                }
                                .swipeActions(edge: .leading) {
                                    Button {
                                        Haptics.tap()
                                        Task { await viewModel.refresh(config) }
                                    } label: {
                                        Label("Refresh", systemImage: "arrow.clockwise")
                                    }
                                    .tint(.green)
                                }
                        }
                    }
                    .listStyle(.plain)
                    .refreshable {
                        await viewModel.refreshAll()
                    }
                }
            }
            .navigationTitle("Vulpino")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Haptics.tap()
                        showingEditor = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingEditor) {
                WidgetEditorView { _ in
                    viewModel.reload()
                }
            }
            .sheet(item: $editingConfig) { config in
                WidgetEditorView(config: config) { _ in
                    viewModel.reload()
                }
            }
            .onAppear {
                viewModel.reload()
            }
            .onChange(of: deepLinkedWidgetId) { _, newId in
                // Handle deep link - find and open the widget
                if let widgetId = newId,
                   let config = viewModel.configs.first(where: { $0.id == widgetId }) {
                    editingConfig = config
                    deepLinkedWidgetId = nil // Clear the deep link
                }
            }
        }
    }
}

struct WidgetListRow: View {
    let config: WidgetConfig

    private var displayData: WidgetDisplayData {
        StorageService.shared.getDisplayData(configId: config.id)
    }

    var body: some View {
        HStack(spacing: 16) {
            // Mini preview
            TemplateRenderer(template: config.template, data: displayData)
                .frame(width: 70, height: 70)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(config.name)
                    .font(.headline)

                Text(config.template.displayName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text(config.refreshInterval.displayName)
                        .font(.caption)
                }
                .foregroundStyle(.tertiary)
            }

            Spacer()

            // Status indicator
            if displayData.isStale {
                Image(systemName: "exclamationmark.circle")
                    .foregroundStyle(.orange)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.quaternary)
        }
        .padding(.vertical, 8)
    }
}

struct EmptyStateView: View {
    let onCreateFirst: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Fox icon placeholder
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: "square.grid.2x2")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 8) {
                Text("No Widgets Yet")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Create your first widget from any JSON endpoint.\nSixty seconds from URL to home screen.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                Haptics.confirm()
                onCreateFirst()
            } label: {
                Label("Create Widget", systemImage: "plus")
                    .font(.headline)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            Spacer()
        }
        .padding()
    }
}

// MARK: - View Model

@MainActor
final class WidgetListViewModel: ObservableObject {
    @Published var configs: [WidgetConfig] = []

    func reload() {
        configs = StorageService.shared.loadConfigs()
    }

    func delete(_ config: WidgetConfig) {
        StorageService.shared.deleteConfig(id: config.id)
        KeychainService.shared.deleteHeaders(for: config.id)
        reload()
    }

    func duplicate(_ config: WidgetConfig) {
        _ = StorageService.shared.duplicateConfig(config)
        reload()
    }

    func refresh(_ config: WidgetConfig) async {
        _ = await StorageService.shared.refreshWidget(configId: config.id)
        Haptics.success()
        reload()
    }

    func refreshAll() async {
        for config in configs {
            _ = await StorageService.shared.refreshWidget(configId: config.id)
        }
        Haptics.success()
        reload()
    }
}

// MARK: - Preview

#Preview {
    WidgetListView()
}
