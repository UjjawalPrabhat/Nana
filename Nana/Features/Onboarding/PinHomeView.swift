import MapKit
import SwiftData
import SwiftUI

/// Saves Home, where Nana stays quiet. Asking for location happens here, in
/// context, and only if you save.
struct PinHomeView: View {
    var onContinue: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(PlaceMonitor.self) private var placeMonitor
    @State private var coordinate: CLLocationCoordinate2D?

    private let radius: Double = 150

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Pin your\nhome")
                .font(.nanaTitle)
                .lineHeight(.multiple(factor: 0.9))
                .foregroundStyle(.cobalt)
                .accessibilityAddTraits(.isHeader)
                .padding(.bottom, 18)
            Text("Leave the circle without your charm, and Nana sends a nudge.")
                .padding(.bottom, 14)

            PlacePicker(coordinate: $coordinate, radius: radius)
                .frame(minHeight: 220)

            Text("Your home stays on this phone. Nana asks for Always location access, so it notices when you head out.")
                .font(.nanaFootnote)
                .foregroundStyle(.inkSoft)
                .padding(.vertical, 12)

            Button("Save home", action: save)
                .nanaPrimaryButton()
                .disabled(coordinate == nil)
            Button("Skip for now", action: onContinue)
                .nanaLinkButton()
                .padding(.top, 6)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 12)
        .nanaScreen()
    }

    private func save() {
        guard let coordinate else { return }
        modelContext.insert(Place(kind: .home, coordinate: coordinate, radius: radius))
        try? modelContext.save()
        placeMonitor.requestAlwaysAccess()
        onContinue()
    }
}
