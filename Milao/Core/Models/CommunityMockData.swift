import SwiftUI

struct CommunityListing: Identifiable, Hashable {
    let id: UUID
    var title: String
    var category: ListingCategory
    var price: String
    var location: String
    var description: String
    var seller: String
    var posted: String
    var isFeatured: Bool
    var status: ListingStatus

    init(
        id: UUID = UUID(),
        title: String,
        category: ListingCategory,
        price: String,
        location: String,
        description: String,
        seller: String,
        posted: String,
        isFeatured: Bool = false,
        status: ListingStatus = .available
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.price = price
        self.location = location
        self.description = description
        self.seller = seller
        self.posted = posted
        self.isFeatured = isFeatured
        self.status = status
    }
}

enum ListingStatus: String, CaseIterable, Hashable {
    case available = "Available"
    case sold = "Sold"
    case outOfStock = "Out of Stock"
}

enum ListingCategory: String, CaseIterable, Identifiable, Hashable {
    case all = "All"
    case housing = "Housing"
    case jobs = "Jobs"
    case buySell = "Buy & Sell"
    case food = "Food"
    case events = "Events"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .all: "square.grid.2x2.fill"
        case .housing: "building.2.fill"
        case .jobs: "briefcase.fill"
        case .buySell: "bag.fill"
        case .food: "fork.knife"
        case .events: "calendar"
        }
    }

    var colors: [Color] {
        switch self {
        case .all: [Theme.Colors.primary, Theme.Colors.accent]
        case .housing: [Theme.Colors.accent, Color(hex: "E84393")]
        case .jobs: [Color(hex: "00C48C"), Color(hex: "007A5E")]
        case .buySell: [Color(hex: "0099FF"), Color(hex: "0055CC")]
        case .food: [Theme.Colors.primary, Color(hex: "E68A00")]
        case .events: [Color(hex: "9B59B6"), Color(hex: "6C3483")]
        }
    }
}

struct RidePost: Identifiable, Hashable {
    let id: UUID
    var driver: String
    var type: RidePostType
    var category: RideCategory
    var from: String
    var to: String
    var date: String
    var time: String
    var seats: Int
    var booked: Int
    var notes: String

    init(
        id: UUID = UUID(),
        driver: String,
        type: RidePostType,
        category: RideCategory,
        from: String,
        to: String,
        date: String,
        time: String,
        seats: Int,
        booked: Int = 0,
        notes: String
    ) {
        self.id = id
        self.driver = driver
        self.type = type
        self.category = category
        self.from = from
        self.to = to
        self.date = date
        self.time = time
        self.seats = seats
        self.booked = booked
        self.notes = notes
    }
}

enum RidePostType: String, CaseIterable, Identifiable, Hashable {
    case offer = "Offering"
    case request = "Need Seat"

    var id: String { rawValue }
    var icon: String { self == .offer ? "car.fill" : "hand.raised.fill" }
    var color: Color { self == .offer ? Color(hex: "0099FF") : Theme.Colors.primary }
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
}

struct CommunityArticle: Identifiable, Hashable {
    let id: UUID
    var title: String
    var category: String
    var author: String
    var date: String
    var readTime: String
    var summary: String
    var body: String
    var isPinned: Bool

    init(
        id: UUID = UUID(),
        title: String,
        category: String,
        author: String,
        date: String,
        readTime: String,
        summary: String,
        body: String,
        isPinned: Bool = false
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.author = author
        self.date = date
        self.readTime = readTime
        self.summary = summary
        self.body = body
        self.isPinned = isPinned
    }
}

struct CommunityConversation: Identifiable, Hashable {
    let id: UUID
    var name: String
    var subject: String
    var preview: String
    var timestamp: String
    var unreadCount: Int
    var tint: Color

    init(
        id: UUID = UUID(),
        name: String,
        subject: String,
        preview: String,
        timestamp: String,
        unreadCount: Int = 0,
        tint: Color
    ) {
        self.id = id
        self.name = name
        self.subject = subject
        self.preview = preview
        self.timestamp = timestamp
        self.unreadCount = unreadCount
        self.tint = tint
    }
}

struct CommunityMessage: Identifiable, Hashable {
    let id = UUID()
    var text: String
    var isMine: Bool
    var timestamp: String
}

enum CommunitySamples {
    static let listings: [CommunityListing] = [
        CommunityListing(title: "2BR Apartment Near WashU", category: .housing, price: "$1,250/mo", location: "University City, MO", description: "Sunny apartment with parking, in-unit laundry, and quick access to Delmar Loop.", seller: "Priya Shah", posted: "Today", isFeatured: true),
        CommunityListing(title: "Part-time Front Desk Help", category: .jobs, price: "$18/hr", location: "Chesterfield, MO", description: "Evening shifts at a family clinic. Bilingual Hindi or Telugu helpful.", seller: "Gateway Clinic", posted: "Yesterday"),
        CommunityListing(title: "Homemade Biryani Trays", category: .food, price: "$42", location: "Creve Coeur, MO", description: "Hyderabadi chicken biryani trays for pickup Friday evening.", seller: "Ayesha Kitchen", posted: "Jun 14", isFeatured: true),
        CommunityListing(title: "MacBook Air M2", category: .buySell, price: "$650", location: "Clayton, MO", description: "13-inch MacBook Air M2, 16 GB RAM, excellent condition with charger.", seller: "Rohan Patel", posted: "Jun 13"),
        CommunityListing(title: "Summer Garba Night", category: .events, price: "$12", location: "St. Louis, MO", description: "Community garba night with snacks and live dhol.", seller: "STL Desi Events", posted: "Jun 12")
    ]

    static let rides: [RidePost] = [
        RidePost(driver: "Vikram Rao", type: .offer, category: .airport, from: "Clayton", to: "STL Airport", date: "Today", time: "5:30 PM", seats: 3, booked: 1, notes: "Cost-sharing airport drop. Two bags are fine."),
        RidePost(driver: "Nisha Menon", type: .request, category: .university, from: "Webster University", to: "Creve Coeur", date: "Tomorrow", time: "Anytime", seats: 1, notes: "Flexible after afternoon classes."),
        RidePost(driver: "Arjun Iyer", type: .offer, category: .longRide, from: "St. Louis", to: "Chicago", date: "Sat, Jun 20", time: "7:00 AM", seats: 2, notes: "Round trip, stopping near Bloomington."),
        RidePost(driver: "Meera Kulkarni", type: .offer, category: .religious, from: "Ballwin", to: "Hindu Temple", date: "Sunday", time: "9:15 AM", seats: 2, notes: "Returning after lunch prasadam.")
    ]

    static let articles: [CommunityArticle] = [
        CommunityArticle(title: "Community picnic returns to Forest Park", category: "Community", author: "NestApp Team", date: "Jun 16", readTime: "3 min", summary: "The annual summer picnic is back with games, food stalls, and volunteer signups.", body: "The annual summer picnic returns to Forest Park this weekend. Families can expect cricket, kids activities, vegetarian food stalls, and a volunteer desk for new community programs.", isPinned: true),
        CommunityArticle(title: "Airport ride safety reminders", category: "Safety", author: "Moderation Team", date: "Jun 15", readTime: "2 min", summary: "Use in-app messages, confirm cost sharing up front, and report suspicious requests.", body: "Rides in Milao are for community cost-sharing only. Confirm route, luggage, and contribution before the ride. Never move a conversation off-platform when something feels unusual."),
        CommunityArticle(title: "Five new food sellers joined this week", category: "Market", author: "Local Desk", date: "Jun 14", readTime: "4 min", summary: "Explore fresh tiffins, biryani trays, sweets, and weekend snack boxes.", body: "The market has added several new home cooks offering rotating menus. Check seller details, pickup windows, and allergy notes before ordering.")
    ]

    static let conversations: [CommunityConversation] = [
        CommunityConversation(name: "Priya Shah", subject: "2BR Apartment Near WashU", preview: "The unit is still available. I can show it tomorrow evening.", timestamp: "2m", unreadCount: 2, tint: Theme.Colors.accent),
        CommunityConversation(name: "Vikram Rao", subject: "STL Airport ride", preview: "I have room for one more carry-on.", timestamp: "18m", tint: Theme.Colors.carpoolAccent),
        CommunityConversation(name: "Ayesha Kitchen", subject: "Biryani tray pickup", preview: "Pickup is from 6 to 7 PM on Friday.", timestamp: "1h", unreadCount: 1, tint: Theme.Colors.primary),
        CommunityConversation(name: "Moderation Team", subject: "Report update", preview: "Thanks for the details. We reviewed the listing.", timestamp: "Yesterday", tint: Theme.Colors.messagesAccent)
    ]

    static let chatMessages: [CommunityMessage] = [
        CommunityMessage(text: "Hi, is this still available?", isMine: true, timestamp: "4:02 PM"),
        CommunityMessage(text: "Yes, it is. I can share more details here.", isMine: false, timestamp: "4:04 PM"),
        CommunityMessage(text: "Great. Does tomorrow evening work?", isMine: true, timestamp: "4:05 PM")
    ]
}
