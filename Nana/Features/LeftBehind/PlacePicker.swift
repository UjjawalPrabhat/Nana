import MapKit
import SwiftUI

/// Address search plus a map with the place's circle. Tap the map to move the
/// pin; search and "Use my location" do the same for VoiceOver users.
struct PlacePicker: View {
    @Binding var coordinate: CLLocationCoordinate2D?
    var radius: Double

    @Environment(PlaceMonitor.self) private var placeMonitor
    @State private var search = AddressSearch()
    @State private var camera: MapCameraPosition = .automatic
    @State private var isLocating = false
    @FocusState private var isSearching: Bool

    var body: some View {
        VStack(spacing: 14) {
            searchField
            map
        }
        .onAppear {
            if let coordinate { camera = Self.camera(around: coordinate, radius: radius) }
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.cobalt)
                .accessibilityHidden(true)
            TextField("Search address", text: $search.query)
                .font(.nanaBody)
                .textContentType(.fullStreetAddress)
                .submitLabel(.search)
                .focused($isSearching)
            Button("Use my location", systemImage: isLocating ? "location.fill" : "location") {
                useCurrentLocation()
            }
            .labelStyle(.iconOnly)
            .font(.system(size: 18, weight: .bold))
            .foregroundStyle(.cobalt)
            .frame(width: 44, height: 44)
            .disabled(isLocating)
        }
        .padding(.leading, 14)
        .padding(.trailing, 4)
        .frame(minHeight: 50)
        .background(Color.card, in: .rect(cornerRadius: 18))
        .overlay { RoundedRectangle(cornerRadius: 18).strokeBorder(.nightInk, lineWidth: 3) }
        .overlay(alignment: .top) {
            if isSearching, !search.suggestions.isEmpty { suggestions.offset(y: 56) }
        }
        .zIndex(1)
    }

    private var suggestions: some View {
        RowGroup {
            ForEach(search.suggestions, id: \.self) { suggestion in
                Button {
                    pick(suggestion)
                } label: {
                    RowLabel(title: Text(verbatim: suggestion.title), detail: Text(verbatim: suggestion.subtitle))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var map: some View {
        MapReader { proxy in
            Map(position: $camera) {
                if let coordinate {
                    MapCircle(center: coordinate, radius: radius)
                        .foregroundStyle(Color.banana.opacity(0.6))
                        .stroke(Color.cobalt, style: StrokeStyle(lineWidth: 3, dash: [8, 6]))
                    Annotation("", coordinate: coordinate, anchor: .bottom) {
                        Image(.mapPin).accessibilityHidden(true)
                    }
                }
            }
            .mapStyle(.standard(pointsOfInterest: .excludingAll))
            .onTapGesture { point in
                guard let tapped = proxy.convert(point, from: .local) else { return }
                coordinate = tapped
                isSearching = false
            }
        }
        .overlay(alignment: .bottomLeading) {
            Text("About \(Int(radius)) m")
                .font(.nanaLabelSmall)
                .padding(.horizontal, 14)
                .frame(minHeight: 34)
                .background(Color.card, in: .capsule)
                .overlay { Capsule().strokeBorder(.nightInk, lineWidth: 2.5) }
                .padding(14)
        }
        .overlay {
            if coordinate == nil {
                Text("Search for the address, use your location, or tap the map.")
                    .font(.nanaLabelSmall)
                    .multilineTextAlignment(.center)
                    .nanaCard(cornerRadius: 18, padding: 12)
                    .padding(24)
                    .allowsHitTesting(false)
            }
        }
        .clipShape(.rect(cornerRadius: 28))
        .overlay { RoundedRectangle(cornerRadius: 28).strokeBorder(.nightInk, lineWidth: 3) }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(coordinate == nil
            ? Text("Map, nothing pinned yet")
            : Text("Map with your place pinned and a circle of about \(Int(radius)) metres around it"))
        .onChange(of: radius) { _, radius in
            if let coordinate { withAnimation { camera = Self.camera(around: coordinate, radius: radius) } }
        }
    }

    private func pick(_ suggestion: MKLocalSearchCompletion) {
        isSearching = false
        Task {
            guard let found = await search.coordinate(for: suggestion) else { return }
            search.query = suggestion.title
            move(to: found)
        }
    }

    private func useCurrentLocation() {
        isLocating = true
        Task {
            defer { isLocating = false }
            if let here = await placeMonitor.currentLocation() { move(to: here) }
        }
    }

    private func move(to newCoordinate: CLLocationCoordinate2D) {
        coordinate = newCoordinate
        withAnimation { camera = Self.camera(around: newCoordinate, radius: radius) }
    }

    private static func camera(around center: CLLocationCoordinate2D, radius: Double) -> MapCameraPosition {
        .region(MKCoordinateRegion(center: center, latitudinalMeters: radius * 3.2, longitudinalMeters: radius * 3.2))
    }
}
