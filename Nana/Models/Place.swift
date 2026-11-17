import CoreLocation
import Foundation
import SwiftData

/// Somewhere Nana stays quiet when the charm is out of range: home, campus, work.
/// Saved on this phone only.
@Model
final class Place {
    nonisolated enum Kind: String, Codable, CaseIterable, Sendable {
        case home, school, office, partner, other

        var name: LocalizedStringResource {
            switch self {
            case .home: "Home"
            case .school: "School"
            case .office: "Office"
            case .partner: "Partner’s place"
            case .other: "Other"
            }
        }

        var systemImage: String {
            switch self {
            case .home: "house.fill"
            case .school: "graduationcap.fill"
            case .office: "briefcase.fill"
            case .partner: "heart.fill"
            case .other: "mappin"
            }
        }
    }

    static let radiusChoices: [Double] = [100, 150, 250]

    var id: UUID
    var kind: Kind
    var latitude: Double
    var longitude: Double
    /// Metres.
    var radius: Double
    var createdAt: Date

    init(kind: Kind, coordinate: CLLocationCoordinate2D, radius: Double) {
        id = UUID()
        self.kind = kind
        latitude = coordinate.latitude
        longitude = coordinate.longitude
        self.radius = radius
        createdAt = .now
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var region: PlaceRegion {
        PlaceRegion(id: id.uuidString, center: coordinate, radius: radius)
    }
}

/// A place reduced to what geofencing needs.
nonisolated struct PlaceRegion: Equatable, Sendable {
    var id: String
    var center: CLLocationCoordinate2D
    var radius: Double

    static func == (lhs: PlaceRegion, rhs: PlaceRegion) -> Bool {
        lhs.id == rhs.id && lhs.radius == rhs.radius
            && lhs.center.latitude == rhs.center.latitude && lhs.center.longitude == rhs.center.longitude
    }
}
