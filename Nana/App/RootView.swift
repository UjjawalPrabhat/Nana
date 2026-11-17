import SwiftData
import SwiftUI

struct RootView: View {
    @AppStorage(AppSettings.hasOnboarded) private var hasOnboarded = false
    @Query private var places: [Place]
    @Environment(PlaceMonitor.self) private var placeMonitor
    @Environment(AppRouter.self) private var router

    var body: some View {
        @Bindable var router = router
        Group {
            if hasOnboarded {
                HomeView()
                    .sheet(isPresented: $router.showsSettings) {
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
        .task(id: places.map(\.region)) {
            await placeMonitor.sync(places.map(\.region))
        }
    }
}
