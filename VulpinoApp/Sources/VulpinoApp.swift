import SwiftUI

@main
struct VulpinoApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var deepLinkedWidgetId: UUID?

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    WidgetListView(deepLinkedWidgetId: $deepLinkedWidgetId)
                } else {
                    OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                }
            }
            .onOpenURL { url in
                handleDeepLink(url)
            }
        }
    }

    private func handleDeepLink(_ url: URL) {
        // Handle vulpino:// URLs
        guard url.scheme == "vulpino" else { return }

        // vulpino://widget/{id} - open widget editor
        if url.host == "widget", let pathComponent = url.pathComponents.last,
           let widgetId = UUID(uuidString: pathComponent) {
            deepLinkedWidgetId = widgetId
        }
    }
}
