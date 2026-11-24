import SwiftUI

struct RootView: View {
    @AppStorage(AppSettings.hasOnboarded) private var hasOnboarded = false
    @Environment(AppRouter.self) private var router

    var body: some View {
        @Bindable var router = router
        Group {
            if hasOnboarded {
                HomeView()
                    .sheet(isPresented: $router.showsSettings, onDismiss: router.sheetDidDismiss) {
                        NavigationStack { SettingsView() }
                    }
                    .sheet(isPresented: $router.showsDebugger, onDismiss: router.sheetDidDismiss) {
                        NavigationStack {
                            DebugView().nanaCloseButton { router.showsDebugger = false }
                        }
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
