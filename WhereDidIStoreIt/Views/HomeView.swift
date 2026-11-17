import SwiftUI

struct HomeView: View {
    let onSearch: () -> Void
    let onAdd: () -> Void
    let onSeeAll: () -> Void

    @EnvironmentObject private var store: ItemStore
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var selectedItem: Item?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header
                SearchPillButton(action: onSearch)

                if store.items.isEmpty {
                    EmptyStateView(
                        emoji: "📦",
                        title: "Nothing stored yet",
                        message: "Save where you put your first item and it will show up here.",
                        buttonTitle: "Store an Item",
                        action: onAdd
                    )
                    .card()
                } else {
                    recentSection
                }

                quickActions

                if !store.items.isEmpty {
                    StorageOverviewCard(total: store.totalCount, stats: store.roomStats)
                }
            }
            .padding(.horizontal, AppMetrics.screenPadding)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
        .background(AppColor.background)
        .fullScreenCover(item: $selectedItem) { item in
            ItemDetailView(itemID: item.id)
        }
    }

    // MARK: Header

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning 👋"
        case 12..<17: return "Good afternoon 👋"
        default: return "Good evening 👋"
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(greeting)
                .appFont(15, .medium)
                .foregroundStyle(AppColor.subtext)
            Text("WhereDidIStoreIt?")
                .appFont(28, .bold, design: .rounded)
                .foregroundStyle(AppColor.text)
                // One long word: shrink a little at huge text sizes rather than orphaning the "?".
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .accessibilityAddTraits(.isHeader)
        }
    }

    // MARK: Recently stored

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Recently Stored", actionTitle: "See All", action: onSeeAll)
            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 14) {
                    ForEach(store.recentItems) { item in
                        Button { selectedItem = item } label: {
                            RecentItemCard(item: item)
                        }
                        .buttonStyle(PressableStyle())
                    }
                }
                .padding(.horizontal, AppMetrics.screenPadding)
                .padding(.vertical, 12)
            }
            .scrollIndicators(.hidden)
            .padding(.horizontal, -AppMetrics.screenPadding)
            .padding(.vertical, -12)
        }
    }

    // MARK: Quick actions

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Quick Actions")
            // Side by side normally; stacked at accessibility text sizes.
            let layout = dynamicTypeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(spacing: 14))
                : AnyLayout(HStackLayout(alignment: .top, spacing: 14))
            layout {
                QuickActionCard(icon: "plus.square.fill", title: "Store an Item",
                                subtitle: "Save where it is", accent: AppColor.primary, action: onAdd)
                QuickActionCard(icon: "magnifyingglass", title: "Find Something",
                                subtitle: "Search your items", accent: AppColor.success, action: onSearch)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Cards

private struct RecentItemCard: View {
    let item: Item

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ItemImageView(imageURL: item.imageURL) {
                CategoryPlaceholder(category: item.categoryInfo, emojiSize: 38)
            }
            .frame(width: 168, height: 112)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .appFont(15, .semibold)
                    .foregroundStyle(AppColor.text)
                    .lineLimit(2)
                Text("\(Room.emoji(for: item.room)) \(item.room)")
                    .appFont(13, .regular)
                    .foregroundStyle(AppColor.subtext)
                    .lineLimit(1)
            }
            .padding(12)
            .frame(width: 168, alignment: .leading)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppMetrics.cardRadius, style: .continuous))
        .card()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.name), \(item.breadcrumb)")
    }
}

private struct QuickActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let accent: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(accent)
                    .frame(width: 46, height: 46)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(accent.opacity(0.12)))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .appFont(15, .semibold)
                        .foregroundStyle(AppColor.text)
                    Text(subtitle)
                        .appFont(13, .regular)
                        .foregroundStyle(AppColor.subtext)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .card()
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle())
    }
}

private struct StorageOverviewCard: View {
    let total: Int
    let stats: [RoomStat]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Storage Overview")
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(total)")
                        .appFont(34, .bold, design: .rounded)
                        .foregroundStyle(AppColor.text)
                    Text(total == 1 ? "item stored" : "items stored")
                        .appFont(15, .medium)
                        .foregroundStyle(AppColor.subtext)
                }
                .accessibilityElement(children: .combine)

                proportionBar
                    .frame(height: 12)

                VStack(spacing: 0) {
                    ForEach(Array(stats.enumerated()), id: \.element.id) { index, stat in
                        roomRow(stat)
                        if index < stats.count - 1 {
                            Rectangle().fill(AppColor.hairline).frame(height: 1)
                        }
                    }
                }
            }
            .padding(18)
            .card()
        }
    }

    /// Stacked bar of room shares. Clipped to its capsule so tiny or rounding-heavy segments can't overflow.
    private var proportionBar: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                ForEach(stats.filter { $0.count > 0 }) { stat in
                    Rectangle()
                        .fill(Room.color(for: stat.name))
                        .frame(width: max(0, geo.size.width * stat.fraction))
                }
                Spacer(minLength: 0)
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .leading)
            .background(AppColor.hairline)
            .clipShape(Capsule())
        }
        .accessibilityHidden(true)
    }

    private func roomRow(_ stat: RoomStat) -> some View {
        let percent = Int((stat.fraction * 100).rounded())
        return HStack(spacing: 12) {
            Text(Room.emoji(for: stat.name))
                .font(.system(size: 18))
                .frame(width: 36, height: 36)
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Room.color(for: stat.name).opacity(0.12)))
            Text(stat.name)
                .appFont(15, .medium)
                .foregroundStyle(AppColor.text)
            Spacer()
            Text("\(stat.count)")
                .appFont(15, .semibold)
                .foregroundStyle(AppColor.text)
                .monospacedDigit()
            Text("\(percent)%")
                .appFont(13, .medium)
                .foregroundStyle(AppColor.subtext)
                .monospacedDigit()
                .frame(width: 44, alignment: .trailing)
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(stat.name): \(pluralized(stat.count, "item")), \(percent) percent")
    }
}
