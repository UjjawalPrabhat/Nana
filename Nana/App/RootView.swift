import SwiftUI

struct RootView: View {
    @AppStorage(AppSettings.hasOnboarded) private var hasOnboarded = false

    var body: some View {
        if hasOnboarded {
            MainTabView()
        } else {
            OnboardingFlow {
                withAnimation { hasOnboarded = true }
            }
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            Tab("Home", systemImage: "house") {
                HomeView()
            }
            Tab("Learn", systemImage: "leaf") {
                LearnView()
            }
            Tab("Settings", systemImage: "gearshape") {
                SettingsView()
            }
        }
    }
}
