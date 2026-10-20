import SwiftData
import SwiftUI

@main
struct NanaApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .tint(.brandGreen)
        }
        .modelContainer(for: [SupplyEvent.self])
    }
}
