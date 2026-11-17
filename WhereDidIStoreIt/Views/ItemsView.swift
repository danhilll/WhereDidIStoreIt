import SwiftUI

struct ItemsView: View {
    let onAdd: () -> Void

    @EnvironmentObject private var store: ItemStore
    @State private var query = ""
    @State private var filter = ItemsView.allFilter
    @State private var selectedItem: Item?
    @State private var editingItem: Item?
    @State private var itemPendingDelete: Item?

    static let allFilter = "All"
    static let recentFilter = "Recently Added"
    private var filters: [String] { [Self.allFilter, Self.recentFilter] + Room.names }

    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    private var filteredItems: [Item] {
        let base: [Item]
        switch filter {
        case Self.allFilter:
            base = store.items
        case Self.recentFilter:
            base = store.items.filter { Self.isRecent($0) }
        default:
            base = store.itemsInRoom(filter)
        }
        return base.filter { $0.matches(query) }
    }

    /// "Recently Added" = stored within the last 7 days.
    private static func isRecent(_ item: Item) -> Bool {
        guard let date = item.storedDate,
              let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: Calendar.current.startOfDay(for: Date()))
        else { return false }
        return date >= cutoff
    }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, AppMetrics.screenPadding)
                .padding(.top, 12)

            SearchField(text: $query, placeholder: "Search by name, room, notes…")
                .padding(.horizontal, AppMetrics.screenPadding)
                .padding(.top, 16)

            filterChips
                .padding(.top, 12)

            content
        }
        .background(AppColor.background)
        .fullScreenCover(item: $selectedItem) { item in
            ItemDetailView(itemID: item.id)
        }
        .sheet(item: $editingItem) { item in
            ItemFormView(mode: .edit(item))
        }
        .alert(
            "Delete Item?",
            isPresented: Binding(get: { itemPendingDelete != nil }, set: { if !$0 { itemPendingDelete = nil } }),
            presenting: itemPendingDelete
        ) { item in
            Button("Delete", role: .destructive) {
                store.deleteItem(item)
                Haptics.impact()
            }
            Button("Cancel", role: .cancel) {}
        } message: { item in
            Text("“\(item.name)” and its photo will be permanently removed.")
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("My Items")
                    .appFont(28, .bold, design: .rounded)
                    .foregroundStyle(AppColor.text)
                    .accessibilityAddTraits(.isHeader)
                Text("\(pluralized(store.totalCount, "item")) stored")
                    .appFont(15, .medium)
                    .foregroundStyle(AppColor.subtext)
            }
            Spacer()
            CircleIconButton(systemName: "plus", accessibilityLabel: "Add item",
                             foreground: .white, background: AppColor.primary, action: onAdd)
        }
    }

    private var filterChips: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(filters, id: \.self) { name in
                    FilterChip(
                        title: name,
                        emoji: Room.names.contains(name) ? Room.emoji(for: name) : nil,
                        isSelected: filter == name
                    ) {
                        withAnimation(.easeOut(duration: 0.2)) { filter = name }
                    }
                }
            }
            .padding(.horizontal, AppMetrics.screenPadding)
        }
        .scrollIndicators(.hidden)
    }

    @ViewBuilder private var content: some View {
        if store.items.isEmpty {
            ScrollView {
                EmptyStateView(
                    emoji: "📦",
                    title: "No items stored yet",
                    message: "Tap + to save where you put something. You'll be able to find it here later.",
                    buttonTitle: "Store an Item",
                    action: onAdd
                )
                .card()
                .padding(AppMetrics.screenPadding)
            }
            .scrollDismissesKeyboard(.interactively)
        } else if filteredItems.isEmpty {
            ScrollView {
                EmptyStateView(
                    emoji: "🔍",
                    title: "No matching items",
                    message: emptyResultsMessage
                )
                .card()
                .padding(AppMetrics.screenPadding)
            }
            .scrollDismissesKeyboard(.interactively)
        } else {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(filteredItems) { item in
                        Button { selectedItem = item } label: {
                            ItemGridCard(item: item)
                        }
                        .buttonStyle(PressableStyle())
                        // VoiceOver alternative to the long-press menu.
                        .accessibilityAction(named: "Edit") { editingItem = item }
                        .accessibilityAction(named: "Delete") { itemPendingDelete = item }
                        .contextMenu {
                            Button { editingItem = item } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            Button(role: .destructive) { itemPendingDelete = item } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .padding(.horizontal, AppMetrics.screenPadding)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }

    private var emptyResultsMessage: String {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        switch (trimmed.isEmpty, filter) {
        case (true, Self.recentFilter):
            return "Nothing was added in the last 7 days."
        case (true, _):
            return "Nothing is stored in \(filter) yet."
        case (false, Self.allFilter):
            return "No items match “\(trimmed)”. Try a different word."
        default:
            return "No items in \(filter) match “\(trimmed)”."
        }
    }
}

private struct ItemGridCard: View {
    let item: Item

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ItemImageView(imageURL: item.imageURL) {
                CategoryPlaceholder(category: item.categoryInfo, emojiSize: 42)
            }
            .frame(height: 130)
            .frame(maxWidth: .infinity)
            .overlay(alignment: .topLeading) {
                CategoryBadge(category: item.categoryInfo, compact: true)
                    .padding(10)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .appFont(15, .semibold)
                    .foregroundStyle(AppColor.text)
                    .lineLimit(2, reservesSpace: true)
                    .multilineTextAlignment(.leading)
                Text("\(Room.emoji(for: item.room)) \(item.room)")
                    .appFont(13, .regular)
                    .foregroundStyle(AppColor.subtext)
                    .lineLimit(1)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppMetrics.cardRadius, style: .continuous))
        .card()
        .contentShape(RoundedRectangle(cornerRadius: AppMetrics.cardRadius, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.name), \(item.categoryInfo.label), \(item.breadcrumb)")
        .accessibilityHint("Opens item details. Touch and hold for more options.")
    }
}
