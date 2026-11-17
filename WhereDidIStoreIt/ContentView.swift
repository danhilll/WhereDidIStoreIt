import SwiftUI

enum AppTab: Hashable {
    case home, items, settings
}

/// Main shell: tab content + custom bottom tab bar with an elevated "+" button.
struct ContentView: View {
    @State private var selectedTab: AppTab = .home
    @State private var showAddItem = false
    @State private var showSearch = false

    var body: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()

            switch selectedTab {
            case .home:
                HomeView(
                    onSearch: { showSearch = true },
                    onAdd: { showAddItem = true },
                    onSeeAll: { selectedTab = .items }
                )
            case .items:
                ItemsView(onAdd: { showAddItem = true })
            case .settings:
                SettingsView()
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            CustomTabBar(selectedTab: $selectedTab, onAdd: { showAddItem = true })
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .sheet(isPresented: $showAddItem) {
            ItemFormView(mode: .add)
        }
        .fullScreenCover(isPresented: $showSearch) {
            SearchView()
        }
    }
}

// MARK: - Tab bar

struct CustomTabBar: View {
    @Binding var selectedTab: AppTab
    let onAdd: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            tabButton(.home, title: "Home", icon: "house", selectedIcon: "house.fill")
            tabButton(.items, title: "Items", icon: "square.grid.2x2", selectedIcon: "square.grid.2x2.fill")

            Button(action: onAdd) {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 60, height: 60)
                    .background(Circle().fill(AppColor.primaryGradient))
                    .overlay(Circle().stroke(Color.white, lineWidth: 4))
                    .shadow(color: AppColor.primary.opacity(0.35), radius: 12, x: 0, y: 6)
            }
            .buttonStyle(PressableStyle())
            .offset(y: -18)
            .frame(maxWidth: .infinity)
            .accessibilityLabel("Add item")
            .accessibilityShowsLargeContentViewer {
                Label("Add item", systemImage: "plus")
            }

            tabButton(.settings, title: "Settings", icon: "gearshape", selectedIcon: "gearshape.fill")
        }
        .padding(.horizontal, 8)
        .padding(.top, 8)
        .padding(.bottom, 4)
        .frame(height: 64, alignment: .top)
        .background(alignment: .top) {
            // Hairline lives in the background so the elevated "+" button sits above it.
            ZStack(alignment: .top) {
                Color.white
                    .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: -2)
                    .ignoresSafeArea(edges: .bottom)
                Rectangle().fill(AppColor.hairline).frame(height: 1)
            }
        }
    }

    private func tabButton(_ tab: AppTab, title: String, icon: String, selectedIcon: String) -> some View {
        let isSelected = selectedTab == tab
        return Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: isSelected ? selectedIcon : icon)
                    .font(.system(size: 20, weight: .semibold))
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(isSelected ? AppColor.primary : AppColor.subtext)
            .frame(maxWidth: .infinity, minHeight: 48)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
        // Labels stay compact like the system tab bar; long-press shows them enlarged at large text sizes.
        .accessibilityShowsLargeContentViewer {
            Label(title, systemImage: isSelected ? selectedIcon : icon)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(ItemStore())
}
