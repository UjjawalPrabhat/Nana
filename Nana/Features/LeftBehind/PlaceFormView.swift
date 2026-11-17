import MapKit
import SwiftData
import SwiftUI

/// Adds a place, or edits one, from Settings.
struct PlaceFormView: View {
    /// `nil` adds a new place.
    var place: Place?

    @Query private var places: [Place]
    @Environment(\.modelContext) private var modelContext
    @Environment(PlaceMonitor.self) private var placeMonitor
    @Environment(\.dismiss) private var dismiss
    @State private var kind: Place.Kind
    @State private var coordinate: CLLocationCoordinate2D?
    @State private var radius: Double

    init(place: Place? = nil) {
        self.place = place
        _kind = State(initialValue: place?.kind ?? .school)
        _coordinate = State(initialValue: place?.coordinate)
        _radius = State(initialValue: place?.radius ?? 250)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 18) {
                (place.map { Text($0.kind.name) } ?? Text("Add a place"))
                    .font(.nanaTitle)
                    .lineHeight(.multiple(factor: 0.9))
                    .foregroundStyle(.cobalt)
                    .accessibilityAddTraits(.isHeader)
                Text("Nana stays quiet here, like at home.")
            }

            if place?.kind != .home {
                ChoiceRow(title: "Kind of place", options: kinds, selection: $kind, columns: 2) { Text($0.name) }
            }

            PlacePicker(coordinate: $coordinate, radius: radius)
                .frame(minHeight: 240)

            ChoiceRow(title: "Area size", options: Place.radiusChoices, selection: $radius) {
                Text("\(Int($0)) m")
            }
            Text("Pick a bigger area for a campus or office block. Saved on this phone only.")
                .font(.nanaFootnote)
                .foregroundStyle(.inkSoft)

            Button("Save place", action: save)
                .nanaPrimaryButton()
                .disabled(coordinate == nil)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 12)
        .nanaScreen()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let place {
                ToolbarItem(placement: .destructiveAction) {
                    Button("Remove", role: .destructive) {
                        modelContext.delete(place)
                        try? modelContext.save()
                        dismiss()
                    }
                }
            }
        }
    }

    /// Only one Home.
    private var kinds: [Place.Kind] {
        let hasHome = places.contains { $0.kind == .home }
        return Place.Kind.allCases.filter { $0 != .home || !hasHome }
    }

    private func save() {
        guard let coordinate else { return }
        if let place {
            place.kind = kind
            place.latitude = coordinate.latitude
            place.longitude = coordinate.longitude
            place.radius = radius
        } else {
            modelContext.insert(Place(kind: kind, coordinate: coordinate, radius: radius))
        }
        try? modelContext.save()
        placeMonitor.requestAlwaysAccess()
        dismiss()
    }
}
