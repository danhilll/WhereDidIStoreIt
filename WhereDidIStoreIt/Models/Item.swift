import Foundation

/// A stored belonging and where it lives.
nonisolated struct Item: Identifiable, Hashable, Codable, Sendable {
    var id: String
    var name: String
    /// Category id (see `ItemCategory.all`).
    var category: String
    var room: String
    /// "Furniture · Spot"
    var location: String
    /// "Room → Furniture → Spot"
    var breadcrumb: String
    /// Formatted as "MMMM d, yyyy".
    var dateStored: String
    var description: String
    /// Bare filename in the Documents directory (e.g. "<uuid>.jpg"). Empty = no photo.
    var imageURL: String
    var notes: String

    init(
        id: String = UUID().uuidString,
        name: String,
        category: String,
        room: String,
        furniture: String,
        spot: String,
        dateStored: String = Item.formatDate(Date()),
        description: String = "",
        imageURL: String = "",
        notes: String = ""
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.room = room
        self.location = Item.makeLocation(furniture: furniture, spot: spot)
        self.breadcrumb = Item.makeBreadcrumb(room: room, furniture: furniture, spot: spot)
        self.dateStored = dateStored
        self.description = description
        self.imageURL = imageURL
        self.notes = notes
    }

    // MARK: Location helpers

    static let locationSeparator = " · "
    static let breadcrumbSeparator = " → "

    static func makeLocation(furniture: String, spot: String) -> String {
        "\(furniture)\(locationSeparator)\(spot)"
    }

    static func makeBreadcrumb(room: String, furniture: String, spot: String) -> String {
        [room, furniture, spot].joined(separator: breadcrumbSeparator)
    }

    var furniture: String {
        location.components(separatedBy: Item.locationSeparator).first ?? ""
    }

    var spot: String {
        let parts = location.components(separatedBy: Item.locationSeparator)
        return parts.count > 1 ? parts.dropFirst().joined(separator: Item.locationSeparator) : ""
    }

    mutating func setLocation(room: String, furniture: String, spot: String) {
        self.room = room
        self.location = Item.makeLocation(furniture: furniture, spot: spot)
        self.breadcrumb = Item.makeBreadcrumb(room: room, furniture: furniture, spot: spot)
    }

    var categoryInfo: ItemCategory { ItemCategory.with(id: category) }
    var hasPhoto: Bool { !imageURL.isEmpty }

    // MARK: Dates

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "MMMM d, yyyy"
        return f
    }()

    static func formatDate(_ date: Date) -> String {
        dateFormatter.string(from: date)
    }

    /// `dateStored` parsed back into a Date (nil if unparseable).
    var storedDate: Date? { Item.dateFormatter.date(from: dateStored) }

    // MARK: Search

    /// Trimmed, case-insensitive match across all user-visible text. Empty query matches everything.
    func matches(_ query: String) -> Bool {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return true }
        let fields = [name, room, location, breadcrumb, description, notes, categoryInfo.label]
        return fields.contains { $0.range(of: q, options: [.caseInsensitive, .diacriticInsensitive]) != nil }
    }
}
