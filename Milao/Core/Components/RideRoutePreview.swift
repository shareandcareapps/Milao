import SwiftUI
import MapKit

/// Shows pickup/dropoff pins and a driving-route line for a ride whose poster
/// picked real location-search suggestions (see `LocationAutocompleteField`).
/// Falls back to just the two pins, framed to fit, if directions can't be resolved.
struct RideRoutePreview: View {
    let fromCoordinate: CLLocationCoordinate2D
    let toCoordinate: CLLocationCoordinate2D
    let fromLabel: String
    let toLabel: String

    @State private var route: MKRoute?
    @State private var cameraPosition: MapCameraPosition

    init(fromCoordinate: CLLocationCoordinate2D, toCoordinate: CLLocationCoordinate2D, fromLabel: String, toLabel: String) {
        self.fromCoordinate = fromCoordinate
        self.toCoordinate = toCoordinate
        self.fromLabel = fromLabel
        self.toLabel = toLabel
        _cameraPosition = State(initialValue: .rect(
            MKMapRect(origin: MKMapPoint(fromCoordinate), size: MKMapSize())
                .union(MKMapRect(origin: MKMapPoint(toCoordinate), size: MKMapSize()))
                .insetBy(dx: -3000, dy: -3000)
        ))
    }

    var body: some View {
        Map(position: $cameraPosition, interactionModes: [.pan, .zoom]) {
            Marker(fromLabel, systemImage: "circle.fill", coordinate: fromCoordinate)
                .tint(Theme.Colors.info)
            Marker(toLabel, systemImage: "mappin", coordinate: toCoordinate)
                .tint(Theme.Colors.primary)
            if let route {
                MapPolyline(route.polyline)
                    .stroke(Theme.Colors.primary, lineWidth: 4)
            }
        }
        .mapStyle(.standard(pointsOfInterest: .excludingAll))
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Theme.Colors.border, lineWidth: 1)
        )
        .task { await loadRoute() }
    }

    private func loadRoute() async {
        let request = MKDirections.Request()
        request.source = MKMapItem(location: CLLocation(latitude: fromCoordinate.latitude, longitude: fromCoordinate.longitude), address: nil)
        request.destination = MKMapItem(location: CLLocation(latitude: toCoordinate.latitude, longitude: toCoordinate.longitude), address: nil)
        request.transportType = .automobile

        guard let response = try? await MKDirections(request: request).calculate(),
              let firstRoute = response.routes.first
        else { return }

        route = firstRoute
        withAnimation {
            cameraPosition = .rect(firstRoute.polyline.boundingMapRect.insetBy(dx: -2000, dy: -2000))
        }
    }
}
