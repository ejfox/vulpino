import SwiftUI

/// First-run onboarding experience
struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "link",
            title: "Paste Any JSON URL",
            description: "Public APIs, personal dashboards, analytics endpoints. If it returns JSON, Vulpino can display it."
        ),
        OnboardingPage(
            icon: "hand.tap",
            title: "Tap to Select",
            description: "Browse the JSON structure and tap the values you want. No code, no JSONPath syntax to learn."
        ),
        OnboardingPage(
            icon: "textformat",
            title: "Typography is the Feature",
            description: "Seven opinionated templates designed for glanceability. Monospace numbers, proper hierarchy, generous whitespace."
        ),
        OnboardingPage(
            icon: "square.grid.2x2",
            title: "Your Home Screen",
            description: "Add widgets in any size. They refresh automatically and work offline with cached data."
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Pages
            TabView(selection: $currentPage) {
                ForEach(pages.indices, id: \.self) { index in
                    OnboardingPageView(page: pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Page indicator
            HStack(spacing: 8) {
                ForEach(pages.indices, id: \.self) { index in
                    Circle()
                        .fill(index == currentPage ? Color.primary : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.bottom, 32)

            // Action button
            Button {
                if currentPage < pages.count - 1 {
                    withAnimation {
                        currentPage += 1
                    }
                } else {
                    hasCompletedOnboarding = true
                }
            } label: {
                Text(currentPage < pages.count - 1 ? "Continue" : "Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.primary)
                    .foregroundStyle(Color(uiColor: .systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)

            // Skip button
            if currentPage < pages.count - 1 {
                Button("Skip") {
                    hasCompletedOnboarding = true
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.bottom, 24)
            } else {
                Color.clear.frame(height: 44)
            }
        }
        .background(Color(uiColor: .systemBackground))
    }
}

struct OnboardingPage: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
}

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            Image(systemName: page.icon)
                .font(.system(size: 72, weight: .light))
                .foregroundStyle(.primary)

            // Title
            Text(page.title)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            // Description
            Text(page.description)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
    }
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
}
