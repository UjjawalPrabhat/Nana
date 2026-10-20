import SwiftUI

// Placeholder until the curriculum lands (milestone 3).
struct LearnView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Lessons are on the way",
                systemImage: "leaf",
                description: Text("Short, research-backed lessons will appear here.")
            )
            .nanaCanvas()
            .navigationTitle("Learn")
        }
    }
}
