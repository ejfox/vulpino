import SwiftUI

/// Main list of all configured widgets
struct WidgetListView: View {
    @StateObject private var viewModel = WidgetListViewModel()
    @State private var showingEditor = false
    @State private var editingConfig: WidgetConfig?

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
                                    editingConfig = config
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        viewModel.delete(config)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }

                                    Button {
                                        viewModel.duplicate(config)
                                    } label: {
                                        Label("Duplicate", systemImage: "doc.on.doc")
                                    }
                                    .tint(.blue)
                                }
                                .swipeActions(edge: .leading) {
                                    Button {
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

            Image(systemName: "square.grid.2x2")
                .font(.system(size: 60))
                .foregroundStyle(.quaternary)

            VStack(spacing: 8) {
                Text("No Widgets Yet")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Create your first widget from any JSON endpoint")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                onCreateFirst()
            } label: {
                Label("Create Widget", systemImage: "plus")
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
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
        reload()
    }

    func refreshAll() async {
        for config in configs {
            _ = await StorageService.shared.refreshWidget(configId: config.id)
        }
        reload()
    }
}

// MARK: - Preview

#Preview {
    WidgetListView()
}
