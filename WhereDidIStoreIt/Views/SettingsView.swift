import SwiftUI

/// Values to fill in before release. Related rows are hidden while a value is empty.
enum AppInfo {
    static let supportEmail = "" /* <FILL LATER> */
    static let privacyPolicyURL = "" /* <FILL LATER> */

    static var version: String {
        let short = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
        return "\(short) (\(build))"
    }

    static var supportMailURL: URL? {
        let email = supportEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !email.isEmpty else { return nil }
        return URL(string: "mailto:\(email)")
    }

    static var privacyURL: URL? {
        let raw = privacyPolicyURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return nil }
        return URL(string: raw)
    }
}

struct SettingsView: View {
    @EnvironmentObject private var store: ItemStore
    @Environment(\.openURL) private var openURL
    @State private var showEraseConfirm = false
    @State private var showHowItWorks = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    Text("Settings")
                        .appFont(28, .bold, design: .rounded)
                        .foregroundStyle(AppColor.text)
                        .accessibilityAddTraits(.isHeader)

                    summaryCard

                    section("Storage") {
                        NavigationLink {
                            CategoriesListView()
                        } label: {
                            SettingsRow(icon: "square.grid.2x2.fill", tint: AppColor.primary, title: "Categories",
                                        value: "\(ItemCategory.all.count)", showsChevron: true)
                        }
                        divider
                        NavigationLink {
                            LocationsListView()
                        } label: {
                            SettingsRow(icon: "house.fill", tint: AppColor.success, title: "Locations",
                                        value: pluralized(Room.all.count, "room"), showsChevron: true)
                        }
                    }

                    section("Data") {
                        Button {
                            showEraseConfirm = true
                        } label: {
                            SettingsRow(icon: "trash.fill", tint: AppColor.danger, title: "Erase All Data",
                                        titleColor: AppColor.dangerText)
                        }
                        .disabled(store.items.isEmpty)
                        .opacity(store.items.isEmpty ? 0.5 : 1)
                    }

                    section("About") {
                        Button {
                            showHowItWorks = true
                        } label: {
                            SettingsRow(icon: "lightbulb.fill", tint: Color(hex: "F59E0B"), title: "How It Works",
                                        showsChevron: true)
                        }
                        if let mail = AppInfo.supportMailURL {
                            divider
                            Button {
                                openURL(mail)
                            } label: {
                                SettingsRow(icon: "envelope.fill", tint: Color(hex: "06B6D4"), title: "Help & Support",
                                            showsChevron: true)
                            }
                        }
                        if let privacy = AppInfo.privacyURL {
                            divider
                            Button {
                                openURL(privacy)
                            } label: {
                                SettingsRow(icon: "hand.raised.fill", tint: Color(hex: "8B5CF6"), title: "Privacy Policy",
                                            showsChevron: true)
                            }
                        }
                        divider
                        SettingsRow(icon: "info.circle.fill", tint: AppColor.subtext, title: "Version",
                                    value: AppInfo.version)
                    }
                }
                .buttonStyle(PressableStyle())
                .padding(.horizontal, AppMetrics.screenPadding)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
            .background(AppColor.background)
            .toolbar(.hidden, for: .navigationBar)
        }
        .alert("Erase All Data?", isPresented: $showEraseConfirm) {
            Button("Erase Everything", role: .destructive) {
                store.deleteAll()
                Haptics.impact()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently deletes all \(pluralized(store.totalCount, "item")) and their photos from this iPhone. This can't be undone.")
        }
        .sheet(isPresented: $showHowItWorks) {
            OnboardingView(isReplay: true) { showHowItWorks = false }
                .presentationDragIndicator(.visible)
        }
    }

    private var summaryCard: some View {
        HStack(spacing: 16) {
            Image(systemName: "archivebox.fill")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.white.opacity(0.2)))
            VStack(alignment: .leading, spacing: 4) {
                Text(pluralized(store.totalCount, "item") + " stored")
                    .appFont(20, .bold, design: .rounded)
                Text("in " + pluralized(store.occupiedRoomCount, "room"))
                    .appFont(15, .medium)
                    .opacity(0.85)
            }
            .foregroundStyle(.white)
            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: AppMetrics.cardRadius, style: .continuous)
                .fill(AppColor.primaryGradient)
        )
        .shadow(color: AppColor.primary.opacity(0.3), radius: 14, x: 0, y: 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(pluralized(store.totalCount, "item")) stored in \(pluralized(store.occupiedRoomCount, "room"))")
    }

    private var divider: some View {
        Rectangle().fill(AppColor.hairline).frame(height: 1).padding(.leading, 64)
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .appFont(13, .semibold)
                .foregroundStyle(AppColor.subtext)
                .padding(.leading, 6)
                .accessibilityAddTraits(.isHeader)
            VStack(spacing: 0) { content() }
                .card()
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let tint: Color
    let title: String
    var value: String?
    var titleColor: Color = AppColor.text
    var showsChevron = false

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 36, height: 36)
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(tint.opacity(0.12)))
                .accessibilityHidden(true)
            Text(title)
                .appFont(16, .medium)
                .foregroundStyle(titleColor)
            Spacer()
            if let value {
                Text(value)
                    .appFont(15, .regular)
                    .foregroundStyle(AppColor.subtext)
            }
            if showsChevron {
                Image(systemName: "chevron.right")
                    .appFont(13, .semibold)
                    .foregroundStyle(AppColor.chevron)
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 60)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Storage lists (generated from the model)

struct CategoriesListView: View {
    @EnvironmentObject private var store: ItemStore

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(Array(ItemCategory.all.enumerated()), id: \.element.id) { index, category in
                    HStack(spacing: 14) {
                        Text(category.emoji)
                            .font(.system(size: 18))
                            .frame(width: 36, height: 36)
                            .background(RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(category.color.opacity(0.12)))
                        Text(category.label)
                            .appFont(16, .medium)
                            .foregroundStyle(AppColor.text)
                        Spacer()
                        Text(pluralized(store.items.filter { $0.category == category.id }.count, "item"))
                            .appFont(15, .regular)
                            .foregroundStyle(AppColor.subtext)
                    }
                    .padding(.horizontal, 14)
                    .frame(minHeight: 60)
                    .accessibilityElement(children: .combine)
                    if index < ItemCategory.all.count - 1 {
                        Rectangle().fill(AppColor.hairline).frame(height: 1).padding(.leading, 64)
                    }
                }
            }
            .card()
            .padding(AppMetrics.screenPadding)
        }
        .background(AppColor.background)
        .navigationTitle("Categories")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
    }
}

struct LocationsListView: View {
    @EnvironmentObject private var store: ItemStore
    @State private var expandedRoom: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(Room.all) { room in
                    VStack(alignment: .leading, spacing: 0) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                expandedRoom = expandedRoom == room.name ? nil : room.name
                            }
                        } label: {
                            HStack(spacing: 14) {
                                Text(room.emoji)
                                    .font(.system(size: 18))
                                    .frame(width: 36, height: 36)
                                    .background(RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(room.color.opacity(0.12)))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(room.name)
                                        .appFont(16, .semibold)
                                        .foregroundStyle(AppColor.text)
                                    Text("\(pluralized(LocationTree.furniture(in: room.name).count, "place")) · \(pluralized(store.itemsInRoom(room.name).count, "item"))")
                                        .appFont(13, .regular)
                                        .foregroundStyle(AppColor.subtext)
                                }
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .appFont(13, .semibold)
                                    .foregroundStyle(AppColor.subtext)
                                    .rotationEffect(.degrees(expandedRoom == room.name ? 180 : 0))
                            }
                            .padding(.horizontal, 14)
                            .frame(minHeight: 64)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PressableStyle())
                        .accessibilityHint(expandedRoom == room.name ? "Collapse" : "Show furniture and spots")

                        if expandedRoom == room.name {
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(LocationTree.furniture(in: room.name), id: \.self) { furniture in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(furniture)
                                            .appFont(14, .semibold)
                                            .foregroundStyle(AppColor.text)
                                        Text(LocationTree.spots(in: room.name, furniture: furniture).joined(separator: " · "))
                                            .appFont(13, .regular)
                                            .foregroundStyle(AppColor.subtext)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .accessibilityElement(children: .combine)
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.leading, 50)
                            .padding(.bottom, 16)
                        }
                    }
                    .card(radius: 20)
                }
            }
            .padding(AppMetrics.screenPadding)
        }
        .background(AppColor.background)
        .navigationTitle("Locations")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
    }
}
