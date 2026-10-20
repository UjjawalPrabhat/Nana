import SwiftData
import SwiftUI

@main
struct NanaApp: App {
    private let modelContainer: ModelContainer
    @State private var containerStore: ContainerStore
    @State private var companion = NanaCompanion()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        do {
            modelContainer = try ModelContainer(for: SupplyEvent.self, LessonCompletion.self)
        } catch {
            fatalError("Could not open Nana's local store: \(error)")
        }
        _containerStore = State(initialValue: ContainerStore(modelContext: modelContainer.mainContext))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .tint(.brandGreen)
                .environment(containerStore)
                .environment(companion)
                .task { containerStore.start() }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { companion.recordActive() }
        }
        .modelContainer(modelContainer)
    }
}
