import MapKit

/// Address suggestions as you type, then the coordinate for the one you pick.
@Observable
final class AddressSearch: NSObject {
    var query = "" {
        didSet { completer.queryFragment = query }
    }

    private(set) var suggestions: [MKLocalSearchCompletion] = []

    @ObservationIgnored private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
    }

    func coordinate(for suggestion: MKLocalSearchCompletion) async -> CLLocationCoordinate2D? {
        let response = try? await MKLocalSearch(request: MKLocalSearch.Request(completion: suggestion)).start()
        return response?.mapItems.first?.location.coordinate
    }

    func clear() {
        query = ""
        suggestions = []
    }
}

extension AddressSearch: @preconcurrency MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        suggestions = Array(completer.results.prefix(4))
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        suggestions = []
    }
}
