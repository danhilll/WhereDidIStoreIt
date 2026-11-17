import Foundation
import Combine

/// Owns all items and persists them as JSON in UserDefaults.
final class ItemStore: ObservableObject {
    @Published private(set) var items: [Item] = []

    private let defaults: UserDefaults
    private let imageStorage: ImageStorage

    static let storageKey = "WhereDidIStoreIt_Items"
    #if DEBUG
    static let sampleSeededKey = "WhereDidIStoreIt_SampleDataSeeded"
    #endif

    init(defaults: UserDefaults = .standard, imageStorage: ImageStorage = .shared) {
        self.defaults = defaults
        self.imageStorage = imageStorage
        load()
        #if DEBUG
        seedSampleDataIfNeeded()
        #endif
    }

    // MARK: Queries

    var recentItems: [Item] { Array(items.prefix(3)) }
    var totalCount: Int { items.count }

    func itemsInRoom(_ room: String) -> [Item] {
        items.filter { $0.room == room }
    }

    func item(withID id: String) -> Item? {
        items.first { $0.id == id }
    }

    /// Number of distinct rooms that currently hold at least one item.
    var occupiedRoomCount: Int {
        Set(items.map(\.room)).count
    }

    /// One stat per room (in display order), including empty rooms.
    var roomStats: [RoomStat] {
        let total = max(items.count, 1)
        return Room.all.map { room in
            let count = items.reduce(0) { $0 + ($1.room == room.name ? 1 : 0) }
            return RoomStat(name: room.name, count: count, fraction: Double(count) / Double(total))
        }
    }

    // MARK: Mutations

    func addItem(_ item: Item) {
        items.insert(item, at: 0)
        save()
    }

    /// Replaces the stored item with the same id. If its photo changed, the old file is deleted.
    func updateItem(_ item: Item) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        let oldImage = items[index].imageURL
        items[index] = item
        save()
        if !oldImage.isEmpty, oldImage != item.imageURL {
            imageStorage.delete(oldImage)
        }
    }

    func deleteItem(_ item: Item) {
        let stored = items.first { $0.id == item.id }
        items.removeAll { $0.id == item.id }
        save()
        imageStorage.delete(stored?.imageURL ?? item.imageURL)
    }

    func deleteAll() {
        let files = items.map(\.imageURL)
        items.removeAll()
        save()
        files.forEach { imageStorage.delete($0) }
    }

    // MARK: Persistence

    private func load() {
        guard let data = defaults.data(forKey: Self.storageKey) else { return }
        do {
            items = try JSONDecoder().decode([Item].self, from: data)
        } catch {
            #if DEBUG
            print("ItemStore: failed to decode items – \(error)")
            #endif
        }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(items)
            defaults.set(data, forKey: Self.storageKey)
        } catch {
            #if DEBUG
            print("ItemStore: failed to encode items – \(error)")
            #endif
        }
    }

    // MARK: Sample data (Debug builds only)

    #if DEBUG
    private func seedSampleDataIfNeeded() {
        guard !defaults.bool(forKey: Self.sampleSeededKey) else { return }
        defaults.set(true, forKey: Self.sampleSeededKey)
        guard items.isEmpty else { return }

        items = [
            Item(name: "Passport", category: "documents", room: "Study Room", furniture: "Filing Cabinet", spot: "Top Drawer",
                 description: "Blue passport inside a clear folder.", notes: "Expires in 2029."),
            Item(name: "Spare House Keys", category: "other", room: "Entrance", furniture: "Key Hook", spot: "Left Hook"),
            Item(name: "Laptop Charger", category: "electronics", room: "Bedroom", furniture: "Desk", spot: "Bottom Drawer",
                 description: "65W USB-C charger."),
            Item(name: "Winter Jacket", category: "clothing", room: "Bedroom", furniture: "Wardrobe", spot: "Top Shelf",
                 notes: "Vacuum-sealed bag."),
            Item(name: "Cordless Drill", category: "tools", room: "Storage Room", furniture: "Shelf Unit", spot: "Bottom Shelf",
                 description: "Drill with the bit set in the same case."),
        ]
        save()
    }
    #endif
}
