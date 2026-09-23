import Foundation
import Supabase
import CoreLocation

@Observable
@MainActor
final class RidesService {
    var rides: [Ride] = []
    var myRides: [Ride] = []
    var isLoading = false
    var error: String?

    // MARK: - Fetch

    func fetchAll(category: String? = nil) async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            if let cat = category, cat != "all" {
                rides = try await supabase
                    .from("rides")
                    .select()
                    .eq("status", value: "active")
                    .eq("category", value: cat)
                    .order("created_at", ascending: false)
                    .limit(40)
                    .execute()
                    .value
            } else {
                rides = try await supabase
                    .from("rides")
                    .select()
                    .eq("status", value: "active")
                    .order("created_at", ascending: false)
                    .limit(40)
                    .execute()
                    .value
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func fetchHome() async -> [Ride] {
        do {
            return try await supabase
                .from("rides")
                .select()
                .eq("status", value: "active")
                .order("created_at", ascending: false)
                .limit(8)
                .execute()
                .value
        } catch { return [] }
    }

    func fetchMine(userId: UUID) async {
        do {
            let posted: [Ride] = try await supabase
                .from("rides")
                .select()
                .or("driver_id.eq.\(userId.uuidString),requester_id.eq.\(userId.uuidString)")
                .order("ride_date", ascending: true)
                .limit(20)
                .execute()
                .value

            // Rides booked by the user
            let bookings: [RideBooking] = (try? await supabase
                .from("ride_bookings")
                .select()
                .eq("rider_id", value: userId.uuidString)
                .not("status", operator: .eq, value: "cancelled")
                .execute()
                .value) ?? []

            var bookedRides: [Ride] = []
            if !bookings.isEmpty {
                bookedRides = (try? await supabase
                    .from("rides")
                    .select()
                    .in("id", values: bookings.map { $0.rideId.uuidString })
                    .execute()
                    .value) ?? []
            }

            let postedIds = Set(posted.map { $0.id })
            let combined = posted + bookedRides.filter { !postedIds.contains($0.id) }
            myRides = combined.sorted { ($0.rideDate ?? .distantFuture) < ($1.rideDate ?? .distantFuture) }
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Post

    func post(
        userId: UUID,
        rideType: String,
        fromLocation: String,
        toLocation: String,
        fromCoordinate: CLLocationCoordinate2D? = nil,
        toCoordinate: CLLocationCoordinate2D? = nil,
        rideDate: Date,
        seatsAvailable: Int,
        price: Double?,
        notes: String,
        category: String
    ) async throws -> Ride {
        var body: [String: AnyJSON] = [
            "from_location":    .string(fromLocation),
            "to_location":      .string(toLocation),
            "ride_date":        .string(ISO8601DateFormatter().string(from: rideDate)),
            "ride_type":        .string(rideType),
            "seats_available":  .double(Double(seatsAvailable)),
            "status":           .string("active"),
            "category":         .string(category),
            "notes":            .string(notes),
        ]
        if rideType == "offer" {
            body["driver_id"] = .string(userId.uuidString)
        } else {
            body["requester_id"] = .string(userId.uuidString)
        }
        if let price { body["cost_share"] = .double(price) }
        if let fromCoordinate {
            body["from_lat"] = .double(fromCoordinate.latitude)
            body["from_lng"] = .double(fromCoordinate.longitude)
        }
        if let toCoordinate {
            body["to_lat"] = .double(toCoordinate.latitude)
            body["to_lng"] = .double(toCoordinate.longitude)
        }

        return try await supabase
            .from("rides")
            .insert(body)
            .select()
            .single()
            .execute()
            .value
    }

    // MARK: - Booking RPCs

    func confirmBooking(rideId: UUID, riderId: UUID) async throws {
        try await supabase.rpc("confirm_ride_booking", params: [
            "p_ride_id":  AnyJSON.string(rideId.uuidString),
            "p_rider_id": AnyJSON.string(riderId.uuidString),
        ]).execute()
    }

    func cancelBooking(rideId: UUID, riderId: UUID) async throws {
        try await supabase.rpc("cancel_ride_booking", params: [
            "p_ride_id":  AnyJSON.string(rideId.uuidString),
            "p_rider_id": AnyJSON.string(riderId.uuidString),
        ]).execute()
    }

    func checkIn(rideId: UUID, riderId: UUID) async throws {
        try await supabase.rpc("set_booking_checkin", params: [
            "p_ride_id":  AnyJSON.string(rideId.uuidString),
            "p_rider_id": AnyJSON.string(riderId.uuidString),
        ]).execute()
    }

    // MARK: - Edit / Delete

    func update(id: UUID, updates: [String: AnyJSON]) async throws {
        try await supabase
            .from("rides")
            .update(updates)
            .eq("id", value: id.uuidString)
            .execute()
    }

    func delete(id: UUID) async throws {
        try await supabase
            .from("rides")
            .update(["status": "cancelled"])
            .eq("id", value: id.uuidString)
            .execute()
        rides.removeAll { $0.id == id }
        myRides.removeAll { $0.id == id }
    }

    func fetchBookings(rideId: UUID) async throws -> [RideBooking] {
        try await supabase
            .from("ride_bookings")
            .select()
            .eq("ride_id", value: rideId.uuidString)
            .execute()
            .value
    }
}
