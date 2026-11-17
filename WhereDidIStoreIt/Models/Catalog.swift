import SwiftUI

// MARK: - Categories

nonisolated struct ItemCategory: Identifiable, Hashable, Sendable {
    let id: String
    let label: String
    let emoji: String
    let colorHex: String

    var color: Color { Color(hex: colorHex) }

    static let all: [ItemCategory] = [
        ItemCategory(id: "electronics", label: "Electronics", emoji: "💻", colorHex: "5B5CE2"),
        ItemCategory(id: "clothing", label: "Clothing", emoji: "👕", colorHex: "EC4899"),
        ItemCategory(id: "documents", label: "Documents", emoji: "📄", colorHex: "F59E0B"),
        ItemCategory(id: "tools", label: "Tools", emoji: "🔧", colorHex: "10B981"),
        ItemCategory(id: "kitchen", label: "Kitchen", emoji: "🍳", colorHex: "EF4444"),
        ItemCategory(id: "books", label: "Books", emoji: "📚", colorHex: "8B5CF6"),
        ItemCategory(id: "sports", label: "Sports", emoji: "⚽", colorHex: "06B6D4"),
        ItemCategory(id: "other", label: "Other", emoji: "📦", colorHex: "6B7280"),
    ]

    static let other = all.last!

    static func with(id: String) -> ItemCategory {
        all.first { $0.id == id } ?? other
    }
}

// MARK: - Rooms

nonisolated struct Room: Identifiable, Hashable, Sendable {
    var id: String { name }
    let name: String
    let emoji: String
    let colorHex: String

    var color: Color { Color(hex: colorHex) }

    static let all: [Room] = [
        Room(name: "Bedroom", emoji: "🛏️", colorHex: "5B5CE2"),
        Room(name: "Living Room", emoji: "🛋️", colorHex: "22C55E"),
        Room(name: "Kitchen", emoji: "🍳", colorHex: "F59E0B"),
        Room(name: "Bathroom", emoji: "🚿", colorHex: "06B6D4"),
        Room(name: "Study Room", emoji: "📚", colorHex: "8B5CF6"),
        Room(name: "Storage Room", emoji: "📦", colorHex: "6B7280"),
        Room(name: "Entrance", emoji: "🚪", colorHex: "F59E0B"),
    ]

    static var names: [String] { all.map(\.name) }

    static func emoji(for room: String) -> String {
        all.first { $0.name == room }?.emoji ?? "📦"
    }

    static func colorHex(for room: String) -> String {
        all.first { $0.name == room }?.colorHex ?? "6B7280"
    }

    static func color(for room: String) -> Color {
        Color(hex: colorHex(for: room))
    }
}

/// Per-room statistics for the Home overview. Identity is the room name so SwiftUI diffing is stable.
nonisolated struct RoomStat: Identifiable, Hashable, Sendable {
    var id: String { name }
    let name: String
    let count: Int
    let fraction: Double
}

// MARK: - Location tree (room → furniture → spots)

nonisolated enum LocationTree {
    private static let raw: [String: [String: [String]]] = {
        let cabinetSides = ["Left Side", "Right Side", "Top Shelf", "Bottom Shelf", "Other"]
        return [
            "Bedroom": [
                "Desk": ["Top Drawer", "Bottom Drawer", "Left Side", "Right Side", "On Top", "Other"],
                "Wardrobe": ["Top Shelf", "Middle Shelf", "Bottom Shelf", "Left Section", "Right Section", "Other"],
                "Bedside Table": ["Top Drawer", "Bottom Drawer", "On Top", "Other"],
                "Cabinet": ["Top Shelf", "Middle Shelf", "Bottom Shelf", "Lock Box", "Other"],
                "Other": ["Top", "Middle", "Bottom", "Inside", "Other"],
            ],
            "Living Room": [
                "TV Cabinet": ["Left Drawer", "Right Drawer", "Top Shelf", "Behind TV", "Other"],
                "Sofa": ["Left Cushion", "Right Cushion", "Under Sofa", "Side Table", "Other"],
                "Bookshelf": ["Top Shelf", "Middle Shelf", "Bottom Shelf", "Left Side", "Right Side", "Other"],
                "Coffee Table": ["Top Surface", "Lower Shelf", "Drawer", "Other"],
                "Other": ["Top", "Middle", "Bottom", "Inside", "Other"],
            ],
            "Kitchen": [
                "Upper Cabinet": cabinetSides,
                "Lower Cabinet": cabinetSides,
                "Refrigerator": ["Top Shelf", "Middle Shelf", "Bottom Shelf", "Door", "Freezer", "Other"],
                "Pantry": ["Top Shelf", "Middle Shelf", "Bottom Shelf", "Door Rack", "Other"],
                "Drawer": ["Utensil Drawer", "Junk Drawer", "Other"],
                "Other": ["Counter", "Inside", "Other"],
            ],
            "Bathroom": [
                "Cabinet": ["Top Shelf", "Middle Shelf", "Bottom Shelf", "Other"],
                "Drawer": ["Top Drawer", "Bottom Drawer", "Other"],
                "Under Sink": ["Left Side", "Right Side", "Back", "Other"],
                "Other": ["Counter", "Inside", "Other"],
            ],
            "Study Room": [
                "Desk": ["Top Drawer", "Bottom Drawer", "Left Side", "Right Side", "On Top", "Other"],
                "Bookshelf": ["Top Shelf", "Middle Shelf", "Bottom Shelf", "Other"],
                "Filing Cabinet": ["Top Drawer", "Middle Drawer", "Bottom Drawer", "Other"],
                "Other": ["Top", "Middle", "Bottom", "Inside", "Other"],
            ],
            "Storage Room": [
                "Shelf Unit": ["Top Shelf", "Middle Shelf", "Bottom Shelf", "Other"],
                "Boxes": ["Box A", "Box B", "Box C", "Other"],
                "Cabinet": ["Top Shelf", "Middle Shelf", "Bottom Shelf", "Other"],
                "Other": ["Left Side", "Right Side", "Back", "Other"],
            ],
            "Entrance": [
                "Shoe Cabinet": ["Top Shelf", "Middle Shelf", "Bottom Shelf", "Other"],
                "Key Hook": ["Left Hook", "Right Hook", "Middle Hook", "Other"],
                "Coat Rack": ["Top Hook", "Middle Hook", "Other"],
                "Other": ["Left Side", "Right Side", "Other"],
            ],
        ]
    }()

    /// Rooms in display order.
    static var rooms: [String] { Room.names }

    /// Furniture for a room, alphabetical with "Other" last.
    static func furniture(in room: String) -> [String] {
        let names = Array(raw[room]?.keys ?? [:].keys)
        return names.sorted { a, b in
            if a == "Other" { return false }
            if b == "Other" { return true }
            return a.localizedStandardCompare(b) == .orderedAscending
        }
    }

    /// Spots for a piece of furniture, in their defined order.
    static func spots(in room: String, furniture: String) -> [String] {
        raw[room]?[furniture] ?? []
    }
}
