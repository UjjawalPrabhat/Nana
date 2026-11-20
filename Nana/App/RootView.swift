import SwiftUI

struct RootView: View {
    @AppStorage(AppSettings.hasOnboarded) private var hasOnboarded = false
    @Environment(AppRouter.self) private var router

    var body: some View {
        @Bindable var router = router
        Group {
            if hasOnboarded {
                HomeView()
                    .sheet(isPresented: $router.showsSettings, onDismiss: router.settingsDidDismiss) {
                        NavigationStack { SettingsView() }
                    }
                    .fullScreenCover(item: $router.cover) { cover in
                        switch cover {
                        case .guide: GuideView()
                        case .stayedBehind: StayedBehindView()
                        }
                    }
            } else {
                OnboardingFlow {
                    withAnimation { hasOnboarded = true }
                }
            }
        }
    }
}
