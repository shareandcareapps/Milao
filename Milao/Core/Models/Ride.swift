import Foundation
import CoreLocation

// MARK: - Ride (matches `rides` Supabase table)

struct Ride: Codable, Identifiable, Sendable, Hashable {
    let id: UUID
    var driverId: UUID?
    var requesterId: UUID?
    var fromLocation: String
    var toLocation: String
    var rideDate: Date?
    var rideType: String          // offer | request
    var seatsAvailable: Int?
    var price: Double?
    var notes: String?
    var status: String            // active | completed | cancelled
    var category: String?         // airport | university | religious | general | long_ride
    var createdAt: Date
    var fromLat: Double?
    var fromLng: Double?
    var toLat: Double?
    var toLng: Double?

    enum CodingKeys: String, CodingKey {
        case id, notes, status, category
        case driverId       = "driver_id"
        case requesterId    = "requester_id"
        case fromLocation   = "from_location"
        case toLocation     = "to_location"
        case rideDate       = "ride_date"
        case rideType       = "ride_type"
        case seatsAvailable = "seats_available"
        case price          = "cost_share"
        case createdAt      = "created_at"
        case fromLat        = "from_lat"
        case fromLng        = "from_lng"
        case toLat          = "to_lat"
        case toLng          = "to_lng"
    }

    /// Set only when the poster picked a location-search suggestion rather than free-typing it.
    var fromCoordinate: CLLocationCoordinate2D? {
        guard let fromLat, let fromLng else { return nil }
        return CLLocationCoordinate2D(latitude: fromLat, longitude: fromLng)
    }
    var toCoordinate: CLLocationCoordinate2D? {
        guard let toLat, let toLng else { return nil }
        return CLLocationCoordinate2D(latitude: toLat, longitude: toLng)
    }

    var isOffering: Bool { rideType == "offer" }
    var ownerId: UUID? { isOffering ? driverId : requesterId }

    var formattedDate: String {
        guard let d = rideDate else { return "TBD" }
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f.string(from: d)
    }

    var categoryKind: RideCategoryKind {
        RideCategoryKind(rawValue: category ?? "") ?? .general
    }
}

// MARK: - Ride Booking (matches `ride_bookings` table)

struct RideBooking: Codable, Identifiable, Sendable {
    let id: UUID
    var rideId: UUID
    var riderId: UUID
    var status: String            // pending | confirmed | cancelled | checked_in
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, status
        case rideId    = "ride_id"
        case riderId   = "rider_id"
        case createdAt = "created_at"
    }
}

// MARK: - Category kind

enum RideCategoryKind: String, CaseIterable, Identifiable {
    case all        = "all"
    case airport    = "airport"
    case university = "university"
    case religious  = "religious"
    case general    = "general"
    case longRide   = "long_ride"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .all:        "All"
        case .airport:    "Airport"
        case .university: "University"
        case .religious:  "Religious"
        case .general:    "General"
        case .longRide:   "Long Ride"
        }
    }

    var icon: String {
        switch self {
        case .all:        "square.grid.2x2.fill"
        case .airport:    "airplane"
        case .university: "graduationcap.fill"
        case .religious:  "leaf.fill"
        case .general:    "car.fill"
        case .longRide:   "map.fill"
        }
    }
}
