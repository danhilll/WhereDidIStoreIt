import SwiftUI

/// Full-screen search. Results push the item detail.
struct SearchView: View {
    @EnvironmentObject private var store: ItemStore
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var path: [String] = []
    @FocusState private var isFocused: Bool

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var results: [Item] {
        guard !trimmedQuery.isEmpty else { return [] }
        return store.items.filter { $0.matches(trimmedQuery) }
    }

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    CircleIconButton(systemName: "chevron.left", accessibilityLabel: "Close search") {
                        dismiss()
                    }
                    SearchField(text: $query, placeholder: "What are you looking for?", focus: $isFocused)
                }
                .padding(.horizontal, AppMetrics.screenPadding)
                .padding(.top, 8)
                .padding(.bottom, 12)

                content
            }
            .background(AppColor.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: String.self) { id in
                ItemDetailView(itemID: id)
            }
            .task {
                // Give the cover presentation a moment, then focus the field.
                try? await Task.sleep(for: .milliseconds(350))
                isFocused = true
            }
        }
    }

    @ViewBuilder private var content: some View {
        ScrollView {
            if trimmedQuery.isEmpty {
                EmptyStateView(
                    emoji: "🔎",
                    title: "Start typing to search",
                    message: store.items.isEmpty
                        ? "You haven't stored anything yet. Add an item first, then find it here."
                        : "Search by name, room, furniture, category or notes."
                )
                .padding(.top, 40)
            } else if results.isEmpty {
                EmptyStateView(
                    emoji: "🤷",
                    title: "No results",
                    message: "Nothing matches “\(trimmedQuery)”. Check the spelling or try another word."
                )
                .padding(.top, 40)
            } else {
                LazyVStack(alignment: .leading, spacing: 10) {
                    Text(pluralized(results.count, "result"))
                        .appFont(14, .semibold)
                        .foregroundStyle(AppColor.subtext)
                        .padding(.horizontal, 4)
                    ForEach(results) { item in
                        Button {
                            isFocused = false
                            path.append(item.id)
                        } label: {
                            SearchResultRow(item: item)
                        }
                        .buttonStyle(PressableStyle())
                    }
                }
                .padding(.horizontal, AppMetrics.screenPadding)
                .padding(.bottom, 24)
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }
}

private struct SearchResultRow: View {
    let item: Item

    var body: some View {
        HStack(spacing: 14) {
            ItemImageView(imageURL: item.imageURL) {
                CategoryPlaceholder(category: item.categoryInfo, emojiSize: 26)
            }
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .appFont(16, .semibold)
                    .foregroundStyle(AppColor.text)
                    .lineLimit(1)
                Text(item.breadcrumb)
                    .appFont(13, .regular)
                    .foregroundStyle(AppColor.subtext)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .appFont(13, .semibold)
                .foregroundStyle(AppColor.chevron)
        }
        .padding(12)
        .card(radius: 20)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.name), \(item.breadcrumb)")
    }
}
