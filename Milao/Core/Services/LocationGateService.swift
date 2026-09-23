import Foundation
import CoreLocation

// MARK: - Location Gate Service
// Confirms a new signup is in or around St. Louis, MO before the account is created —
// replaces zip-code collection with an actual location check.

@Observable
@MainActor
final class LocationGateService: NSObject, CLLocationManagerDelegate {
    enum CheckResult {
        case inArea
        case outOfArea(distanceMiles: Double)
        case permissionDenied
        case unavailable
    }

    // Gateway Arch — center of the metro area we serve.
    private static let stLouisCenter = CLLocation(latitude: 38.6247, longitude: -90.1848)
    // Covers the city, county, St. Charles, Metro East IL, and the outer suburbs.
    private static let serviceRadiusMiles: Double = 60

    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CheckResult, Never>?

    override init() {
        super.init()
        manager.delegate = self
    }

    /// Requests "when in use" authorization if needed, fetches a single location fix,
    /// and resolves once with whether that location falls within the service area.
    func checkLocation() async -> CheckResult {
        await withCheckedContinuation { continuation in
            self.continuation = continuation
            switch manager.authorizationStatus {
            case .notDetermined:
                manager.requestWhenInUseAuthorization()
            case .denied, .restricted:
                resume(.permissionDenied)
            case .authorizedWhenInUse, .authorizedAlways:
                manager.requestLocation()
            @unknown default:
                resume(.unavailable)
            }
        }
    }

    private func resume(_ result: CheckResult) {
        continuation?.resume(returning: result)
        continuation = nil
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            switch self.manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                self.manager.requestLocation()
            case .denied, .restricted:
                self.resume(.permissionDenied)
            case .notDetermined:
                break // Still waiting on the system prompt.
            @unknown default:
                self.resume(.unavailable)
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            let miles = location.distance(from: Self.stLouisCenter) / 1609.34
            self.resume(miles <= Self.serviceRadiusMiles ? .inArea : .outOfArea(distanceMiles: miles))
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in self.resume(.unavailable) }
    }
}
