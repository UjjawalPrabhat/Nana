import SwiftData
import SwiftUI

@main
struct NanaApp: App {
    private let modelContainer: ModelContainer
    @State private var containerStore: ContainerStore

    init() {
        do {
            modelContainer = try ModelContainer(for: SupplyEvent.self)
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
                .task { containerStore.start() }
        }
        .modelContainer(modelContainer)
    }
}
