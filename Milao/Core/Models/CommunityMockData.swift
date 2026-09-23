import SwiftUI

// MARK: - Category filter enums (UI-only — map to live Supabase category strings via `dbValue`)

enum ListingCategory: String, CaseIterable, Identifiable, Hashable {
    case all = "All"
    case housing = "Housing"
    case jobs = "Jobs"
    case buySell = "Buy & Sell"
    case food = "Food"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .all:     "square.grid.2x2.fill"
        case .housing: "building.2.fill"
        case .jobs:    "briefcase.fill"
        case .buySell: "bag.fill"
        case .food:    "fork.knife"
        }
    }

    var colors: [Color] {
        switch self {
        case .all:     [Theme.Colors.primary, Theme.Colors.accent]
        case .housing: [Theme.Colors.accent, Color(hex: "E84393")]
        case .jobs:    [Color(hex: "00C48C"), Color(hex: "007A5E")]
        case .buySell: [Color(hex: "0099FF"), Color(hex: "0055CC")]
        case .food:    [Theme.Colors.primary, Color(hex: "E68A00")]
        }
    }

    // Maps to `listings.category` in Supabase — nil means "no filter" (all).
    var dbValue: String? {
        switch self {
        case .all:     nil
        case .housing: "housing"
        case .jobs:    "jobs"
        case .buySell: "buysell"
        case .food:    "food"
        }
    }
}

enum RideCategory: String, CaseIterable, Identifiable, Hashable {
    case all = "All"
    case airport = "Airport"
    case university = "University"
    case religious = "Religious"
    case general = "General"
    case longRide = "Long Ride"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .all: "square.grid.2x2.fill"
        case .airport: "airplane"
        case .university: "graduationcap.fill"
        case .religious: "leaf.fill"
        case .general: "car.fill"
        case .longRide: "map.fill"
        }
    }

    // Maps to `rides.category` in Supabase — nil means "no filter" (all).
    var dbValue: String? {
        switch self {
        case .all:        nil
        case .airport:    "airport"
        case .university: "university"
        case .religious:  "religious"
        case .general:    "general"
        case .longRide:   "long_ride"
        }
    }
}
