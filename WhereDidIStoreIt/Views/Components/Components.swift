import SwiftUI

// MARK: - Text helpers

/// "1 item" / "3 items".
func pluralized(_ count: Int, _ singular: String, _ plural: String? = nil) -> String {
    "\(count) \(count == 1 ? singular : (plural ?? singular + "s"))"
}

// MARK: - Search pill

/// Editable pill-shaped search field.
struct SearchField: View {
    @Binding var text: String
    var placeholder: String = "Search your items"
    var focus: FocusState<Bool>.Binding?

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .appFont(16, .semibold)
                .foregroundStyle(AppColor.muted)
                .accessibilityHidden(true)
            field
                .appFont(16, .regular)
                .foregroundStyle(AppColor.text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 17))
                        .foregroundStyle(AppColor.subtext)
                        .frame(width: AppMetrics.minTouch, height: AppMetrics.minTouch)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
                .padding(.trailing, -12)
            }
        }
        .padding(.horizontal, 18)
        .frame(minHeight: AppMetrics.searchHeight)
        .background(Capsule().fill(Color.white))
        .overlay(Capsule().stroke(AppColor.border, lineWidth: 1))
        .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 2)
    }

    @ViewBuilder private var field: some View {
        if let focus {
            TextField(placeholder, text: $text).focused(focus)
        } else {
            TextField(placeholder, text: $text)
        }
    }
}

/// Non-editable search pill that acts as a button (Home).
struct SearchPillButton: View {
    var placeholder: String = "Search your items"
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .appFont(16, .semibold)
                    .foregroundStyle(AppColor.subtext)
                Text(placeholder)
                    .appFont(16, .regular)
                    .foregroundStyle(AppColor.subtext)
                Spacer()
            }
            .padding(.horizontal, 18)
            .frame(minHeight: AppMetrics.searchHeight)
            .background(Capsule().fill(Color.white))
            .overlay(Capsule().stroke(AppColor.border, lineWidth: 1))
            .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 2)
            .contentShape(Capsule())
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel("Search your items")
    }
}

// MARK: - Section header

struct SectionHeader: View {
    let title: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .appFont(20, .bold, design: .rounded)
                .foregroundStyle(AppColor.text)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .appFont(15, .semibold)
                    .foregroundStyle(AppColor.primary)
                    .frame(minHeight: AppMetrics.minTouch)
                    .contentShape(Rectangle())
            }
        }
    }
}

// MARK: - Category badge

struct CategoryBadge: View {
    let category: ItemCategory
    var compact = false

    var body: some View {
        HStack(spacing: 4) {
            Text(category.emoji).appFont(compact ? 11 : 13)
            Text(category.label)
                .appFont(compact ? 11 : 13, .semibold)
                .foregroundStyle(category.color)
                .lineLimit(1)
        }
        .padding(.horizontal, compact ? 8 : 10)
        .padding(.vertical, compact ? 4 : 6)
        .background(Capsule().fill(Color.white.opacity(compact ? 0.95 : 1)))
        .overlay(Capsule().stroke(category.color.opacity(0.25), lineWidth: 1))
    }
}

// MARK: - Filter chip

struct FilterChip: View {
    let title: String
    var emoji: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let emoji { Text(emoji).appFont(14, .regular) }
                Text(title)
                    .appFont(14, .semibold)
            }
            .foregroundStyle(isSelected ? Color.white : AppColor.subtext)
            .padding(.horizontal, 16)
            .frame(minHeight: 40)
            .background(
                Capsule().fill(isSelected ? AnyShapeStyle(AppColor.primaryGradient) : AnyShapeStyle(Color.white))
            )
            .overlay(Capsule().stroke(isSelected ? Color.clear : AppColor.border, lineWidth: 1))
            .contentShape(Capsule())
            .padding(.vertical, 2)
        }
        .buttonStyle(PressableStyle())
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Empty state

struct EmptyStateView: View {
    let emoji: String
    let title: String
    let message: String
    var buttonTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 12) {
            Text(emoji)
                .font(.system(size: 44))
                .frame(width: 88, height: 88)
                .background(Circle().fill(AppColor.tint))
                .accessibilityHidden(true)
            Text(title)
                .appFont(19, .bold, design: .rounded)
                .foregroundStyle(AppColor.text)
                .multilineTextAlignment(.center)
            Text(message)
                .appFont(15, .regular)
                .foregroundStyle(AppColor.subtext)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            if let buttonTitle, let action {
                Button(action: action) {
                    Label(buttonTitle, systemImage: "plus")
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top, 8)
                .padding(.horizontal, 24)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Breadcrumb pill

struct BreadcrumbPill: View {
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "mappin.and.ellipse")
                .appFont(13, .semibold)
                .accessibilityHidden(true)
            Text(text)
                .appFont(14, .semibold)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(AppColor.primary)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Capsule().fill(AppColor.tint))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Location: \(text)")
    }
}
