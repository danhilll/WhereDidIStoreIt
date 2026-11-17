import SwiftUI

@main
struct WhereDidIStoreItApp: App {
    /// Created exactly once for the app's lifetime and shared through the environment.
    @StateObject private var store = ItemStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .preferredColorScheme(.light)
        }
    }
}

struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                ContentView()
                    .transition(.opacity)
            } else {
                OnboardingView {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        hasCompletedOnboarding = true
                    }
                }
                .transition(.opacity)
            }
        }
        .tint(AppColor.primary)
        // Text scales with Dynamic Type up to the third accessibility size.
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
    }
}
