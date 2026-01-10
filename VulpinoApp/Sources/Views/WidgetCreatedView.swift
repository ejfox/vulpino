import SwiftUI

/// Shown after successfully creating a widget
/// Provides instructions for adding to home screen
struct WidgetCreatedView: View {
    let widgetName: String
    let onDone: () -> Void

    @State private var showingInstructions = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Success animation
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.green)
            }

            VStack(spacing: 8) {
                Text("Widget Created")
                    .font(.title)
                    .fontWeight(.bold)

                Text("\"\(widgetName)\" is ready for your home screen")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            // Instructions
            VStack(spacing: 16) {
                Button {
                    showingInstructions = true
                } label: {
                    HStack {
                        Image(systemName: "questionmark.circle")
                        Text("How to Add to Home Screen")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.blue)
                }

                Button {
                    Haptics.success()
                    onDone()
                } label: {
                    Text("Done")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.primary)
                        .foregroundStyle(Color(uiColor: .systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .sheet(isPresented: $showingInstructions) {
            HomeScreenInstructionsView()
        }
        .onAppear {
            Haptics.success()
        }
    }
}

struct HomeScreenInstructionsView: View {
    @Environment(\.dismiss) private var dismiss

    private let steps = [
        InstructionStep(
            number: 1,
            title: "Long press on home screen",
            description: "Touch and hold any empty area until the apps start jiggling"
        ),
        InstructionStep(
            number: 2,
            title: "Tap the + button",
            description: "Look for the plus button in the top-left corner"
        ),
        InstructionStep(
            number: 3,
            title: "Search for Vulpino",
            description: "Scroll or search to find Vulpino in the widget gallery"
        ),
        InstructionStep(
            number: 4,
            title: "Choose a size",
            description: "Swipe to pick small, medium, or large"
        ),
        InstructionStep(
            number: 5,
            title: "Add and configure",
            description: "Tap \"Add Widget\", then hold it to choose which widget to display"
        )
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Adding Vulpino widgets to your home screen takes just a few taps.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)

                    ForEach(steps) { step in
                        HStack(alignment: .top, spacing: 16) {
                            Text("\(step.number)")
                                .font(.system(.title3, design: .rounded, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 32, height: 32)
                                .background(Color.blue)
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 4) {
                                Text(step.title)
                                    .font(.headline)

                                Text(step.description)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Pro tip
                    HStack(spacing: 12) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(.yellow)

                        Text("**Pro tip:** Long-press an existing Vulpino widget to quickly switch which data it displays.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color.yellow.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                .padding(.vertical)
            }
            .navigationTitle("Add to Home Screen")
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

struct InstructionStep: Identifiable {
    let id = UUID()
    let number: Int
    let title: String
    let description: String
}

#Preview {
    WidgetCreatedView(widgetName: "Page Views") {
        print("Done")
    }
}
