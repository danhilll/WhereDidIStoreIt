import SwiftUI

/// Item detail. Reads the live item from the store so edits show immediately.
/// Uses `dismiss()` so it works both pushed (Search) and as a full-screen cover (Home / Items).
struct ItemDetailView: View {
    let itemID: String

    @EnvironmentObject private var store: ItemStore
    @Environment(\.dismiss) private var dismiss
    @State private var showEdit = false
    @State private var showDeleteConfirm = false

    private let heroHeight: CGFloat = 340

    var body: some View {
        Group {
            if let item = store.item(withID: itemID) {
                content(item)
            } else {
                // The item was deleted; show nothing while the screen closes.
                AppColor.background.ignoresSafeArea()
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private func content(_ item: Item) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                hero(item)
                details(item)
                    .padding(.top, -28)
            }
        }
        .scrollIndicators(.hidden)
        .ignoresSafeArea(edges: .top)
        .background(AppColor.background.ignoresSafeArea())
        .overlay(alignment: .top) { floatingButtons }
        .sheet(isPresented: $showEdit) {
            ItemFormView(mode: .edit(item))
        }
        .alert("Delete Item?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                dismiss()
                store.deleteItem(item)
                Haptics.impact()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("“\(item.name)” and its photo will be permanently removed.")
        }
    }

    // MARK: Hero

    private func hero(_ item: Item) -> some View {
        ItemImageView(imageURL: item.imageURL) {
            ZStack {
                LinearGradient(colors: [item.categoryInfo.color.opacity(0.22), AppColor.tint],
                               startPoint: .top, endPoint: .bottom)
                Text(item.categoryInfo.emoji)
                    .font(.system(size: 110))
            }
            .accessibilityHidden(true)
        }
        .frame(height: heroHeight)
        .frame(maxWidth: .infinity)
        .accessibilityLabel(item.hasPhoto ? "Photo of \(item.name)" : "")
    }

    private var floatingButtons: some View {
        HStack {
            CircleIconButton(systemName: "chevron.left", accessibilityLabel: "Back") { dismiss() }
            Spacer()
            CircleIconButton(systemName: "pencil", accessibilityLabel: "Edit item") { showEdit = true }
            CircleIconButton(systemName: "trash", accessibilityLabel: "Delete item",
                             foreground: AppColor.danger) { showDeleteConfirm = true }
        }
        .padding(.horizontal, AppMetrics.screenPadding)
        .padding(.top, 8)
    }

    // MARK: Details

    private func details(_ item: Item) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 12) {
                CategoryBadge(category: item.categoryInfo)
                Text(item.name)
                    .appFont(28, .bold, design: .rounded)
                    .foregroundStyle(AppColor.text)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                BreadcrumbPill(text: item.breadcrumb)
                Label("Stored on \(item.dateStored)", systemImage: "calendar")
                    .appFont(14, .medium)
                    .foregroundStyle(AppColor.subtext)
            }

            locationCard(item)

            if !item.description.isEmpty {
                textCard(title: "Description", icon: "text.alignleft", text: item.description)
            }
            if !item.notes.isEmpty {
                textCard(title: "Notes", icon: "note.text", text: item.notes)
            }
        }
        .padding(AppMetrics.screenPadding)
        .padding(.top, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28, style: .continuous)
                .fill(AppColor.background)
        )
    }

    private func locationCard(_ item: Item) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            cardTitle("Where It Is", icon: "mappin.and.ellipse")
                .padding(.bottom, 8)
            locationRow(label: "Room", value: "\(Room.emoji(for: item.room)) \(item.room)")
            Rectangle().fill(AppColor.hairline).frame(height: 1)
            locationRow(label: "Furniture", value: item.furniture)
            Rectangle().fill(AppColor.hairline).frame(height: 1)
            locationRow(label: "Spot", value: item.spot)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    private func locationRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .appFont(15, .regular)
                .foregroundStyle(AppColor.subtext)
            Spacer()
            Text(value)
                .appFont(15, .semibold)
                .foregroundStyle(AppColor.text)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 10)
        .accessibilityElement(children: .combine)
    }

    private func textCard(title: String, icon: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            cardTitle(title, icon: icon)
            Text(text)
                .appFont(15, .regular)
                .foregroundStyle(AppColor.text)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
                .textSelection(.enabled)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    private func cardTitle(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .appFont(15, .bold, design: .rounded)
            .foregroundStyle(AppColor.text)
            .accessibilityAddTraits(.isHeader)
    }
}
