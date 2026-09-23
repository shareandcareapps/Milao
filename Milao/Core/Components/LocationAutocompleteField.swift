import SwiftUI
import MapKit

// MARK: - Location Suggestion
// Plain Sendable data only — MKLocalSearchCompletion itself isn't Sendable, so it
// never crosses the actor hop from the completer's nonisolated delegate callback.
// Selecting a suggestion re-resolves its coordinate by search text instead of
// holding onto the original completion object.

private struct LocationSuggestion: Identifiable, Sendable {
    let id = UUID()
    let title: String
    let subtitle: String
}

// MARK: - Location Completer
// Wraps MKLocalSearchCompleter, biased toward the St. Louis metro area Milao serves
// (same center/radius as LocationGateService, kept independent to avoid a MapKit
// dependency in that file).

@Observable
@MainActor
private final class LocationCompleter: NSObject, MKLocalSearchCompleterDelegate {
    var suggestions: [LocationSuggestion] = []

    private static let region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 38.6247, longitude: -90.1848),
        latitudinalMeters: 96_000,
        longitudinalMeters: 96_000
    )

    private let completer: MKLocalSearchCompleter = {
        let c = MKLocalSearchCompleter()
        c.resultTypes = [.address, .pointOfInterest]
        c.region = region
        return c
    }()

    override init() {
        super.init()
        completer.delegate = self
    }

    func update(query: String) {
        guard query.trimmingCharacters(in: .whitespaces).count >= 2 else {
            suggestions = []
            return
        }
        completer.queryFragment = query
    }

    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        let mapped: [LocationSuggestion] = completer.results.prefix(5).map {
            LocationSuggestion(title: $0.title, subtitle: $0.subtitle)
        }
        Task { @MainActor in self.suggestions = mapped }
    }

    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {}

    func resolveCoordinate(for suggestion: LocationSuggestion) async -> CLLocationCoordinate2D? {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = suggestion.subtitle.isEmpty
            ? suggestion.title
            : "\(suggestion.title), \(suggestion.subtitle)"
        request.region = Self.region
        let response = try? await MKLocalSearch(request: request).start()
        return response?.mapItems.first?.location.coordinate
    }
}

// MARK: - Location Autocomplete Field
// A route text field with an inline, Maps-style suggestion dropdown. Selecting a
// suggestion resolves `coordinate`; typing further afterward clears it back to nil,
// since free-typed text no longer necessarily matches a real place.

struct LocationAutocompleteField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    @Binding var coordinate: CLLocationCoordinate2D?

    @State private var completer = LocationCompleter()
    @FocusState private var isFocused: Bool

    private var showSuggestions: Bool { isFocused && !completer.suggestions.isEmpty }

    var body: some View {
        fieldRow
            .overlay(alignment: .top) {
                if showSuggestions {
                    suggestionList
                        .offset(y: 58)
                }
            }
            .zIndex(showSuggestions ? 10 : 0)
    }

    private var fieldRow: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(Theme.Colors.textLight)
                .frame(width: 20)
            TextField(placeholder, text: $text)
                .font(.inter(.medium, size: 15))
                .foregroundStyle(Theme.Colors.textPrimary)
                .focused($isFocused)
                .onChange(of: text) { _, newValue in
                    coordinate = nil
                    completer.update(query: newValue)
                }
            if coordinate != nil {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.Colors.success)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .padding(.trailing, 40)
        .background(Theme.Colors.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Theme.Colors.border, lineWidth: 1)
        )
    }

    private var suggestionList: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(completer.suggestions) { suggestion in
                Button {
                    select(suggestion)
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(suggestion.title)
                            .font(.inter(.semibold, size: 14))
                            .foregroundStyle(Theme.Colors.textPrimary)
                        if !suggestion.subtitle.isEmpty {
                            Text(suggestion.subtitle)
                                .font(.inter(.regular, size: 12))
                                .foregroundStyle(Theme.Colors.textLight)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if suggestion.id != completer.suggestions.last?.id {
                    Divider().padding(.leading, 14)
                }
            }
        }
        .background(Theme.Colors.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Theme.Colors.border, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.14), radius: 14, x: 0, y: 8)
    }

    private func select(_ suggestion: LocationSuggestion) {
        text = suggestion.subtitle.isEmpty ? suggestion.title : "\(suggestion.title), \(suggestion.subtitle)"
        completer.suggestions = []
        isFocused = false
        Task {
            coordinate = await completer.resolveCoordinate(for: suggestion)
        }
    }
}
