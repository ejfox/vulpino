import SwiftUI

/// Settings and about screen
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true

    private let appVersion: String = {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }()

    var body: some View {
        NavigationStack {
            List {
                // About section
                Section {
                    HStack(spacing: 16) {
                        AppIconView(size: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 13))

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Vulpino")
                                .font(.headline)
                            Text("Version \(appVersion)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }

                // Help section
                Section("Help") {
                    Button {
                        hasCompletedOnboarding = false
                        dismiss()
                    } label: {
                        Label("Show Onboarding", systemImage: "hand.wave")
                    }

                    Link(destination: URL(string: "https://github.com/ejfox/vulpino")!) {
                        Label("Documentation", systemImage: "book")
                    }

                    Link(destination: URL(string: "https://github.com/ejfox/vulpino/issues")!) {
                        Label("Report an Issue", systemImage: "ladybug")
                    }
                }

                // Legal section
                Section("Legal") {
                    Link(destination: URL(string: "https://ejfox.com/privacy")!) {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    }

                    Link(destination: URL(string: "https://ejfox.com/terms")!) {
                        Label("Terms of Service", systemImage: "doc.text")
                    }
                }

                // Data section
                Section {
                    NavigationLink {
                        DataManagementView()
                    } label: {
                        Label("Manage Data", systemImage: "externaldrive")
                    }
                } footer: {
                    Text("Widget configurations and cached data are stored locally on your device. API keys are stored in your device's secure Keychain.")
                }

                // Credits
                Section {
                    VStack(alignment: .center, spacing: 8) {
                        Text("Made with care by")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text("Room 302 Studio")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Text("\"Vulpino dice no.\"")
                            .font(.caption)
                            .italic()
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

/// Data management screen
struct DataManagementView: View {
    @State private var widgetCount = 0
    @State private var cacheSize = "Calculating..."
    @State private var showingDeleteConfirmation = false

    var body: some View {
        List {
            Section {
                HStack {
                    Text("Widgets")
                    Spacer()
                    Text("\(widgetCount)")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Cached Data")
                    Spacer()
                    Text(cacheSize)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    Label("Delete All Widgets", systemImage: "trash")
                }
            } footer: {
                Text("This will remove all widget configurations and cached data. This cannot be undone.")
            }
        }
        .navigationTitle("Manage Data")
        .onAppear {
            loadStats()
        }
        .confirmationDialog(
            "Delete All Widgets?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete All", role: .destructive) {
                deleteAllData()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all \(widgetCount) widgets and their cached data.")
        }
    }

    private func loadStats() {
        let configs = StorageService.shared.loadConfigs()
        widgetCount = configs.count

        // Estimate cache size
        if let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.vulpino.widgets"
        ) {
            let cacheURL = containerURL.appendingPathComponent("widget_cache.json")
            if let attributes = try? FileManager.default.attributesOfItem(atPath: cacheURL.path),
               let size = attributes[.size] as? Int64 {
                cacheSize = ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
            } else {
                cacheSize = "0 KB"
            }
        } else {
            cacheSize = "0 KB"
        }
    }

    private func deleteAllData() {
        let configs = StorageService.shared.loadConfigs()
        for config in configs {
            StorageService.shared.deleteConfig(id: config.id)
            KeychainService.shared.deleteHeaders(for: config.id)
        }
        Haptics.success()
        loadStats()
    }
}

#Preview {
    SettingsView()
}
