import SwiftUI

/// Three-step picker: Room → Furniture → Spot. Presented as a normal large sheet.
struct LocationPickerView: View {
    let onConfirm: (String, String, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var step: Int
    @State private var room: String
    @State private var furniture: String
    @State private var spot: String

    init(room: String = "", furniture: String = "", spot: String = "",
         onConfirm: @escaping (String, String, String) -> Void) {
        self.onConfirm = onConfirm
        // Pre-fill (when editing) only if the saved location still exists in the tree.
        let validRoom = LocationTree.rooms.contains(room)
        let validFurniture = validRoom && LocationTree.furniture(in: room).contains(furniture)
        let validSpot = validFurniture && LocationTree.spots(in: room, furniture: furniture).contains(spot)
        _room = State(initialValue: validRoom ? room : "")
        _furniture = State(initialValue: validFurniture ? furniture : "")
        _spot = State(initialValue: validSpot ? spot : "")
        _step = State(initialValue: validFurniture ? 2 : (validRoom ? 1 : 0))
    }

    private var stepTitle: String {
        switch step {
        case 0: return "Which room?"
        case 1: return "Which furniture?"
        default: return "Which spot?"
        }
    }

    private var options: [String] {
        switch step {
        case 0: return LocationTree.rooms
        case 1: return LocationTree.furniture(in: room)
        default: return LocationTree.spots(in: room, furniture: furniture)
        }
    }

    private var selectedOption: String {
        switch step {
        case 0: return room
        case 1: return furniture
        default: return spot
        }
    }

    private var canConfirm: Bool { !room.isEmpty && !furniture.isEmpty && !spot.isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.horizontal, AppMetrics.screenPadding)
                .padding(.top, 24)

            if !room.isEmpty {
                breadcrumbChips
                    .padding(.top, 14)
            }

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(options, id: \.self) { option in
                        optionRow(option)
                    }
                }
                .padding(.horizontal, AppMetrics.screenPadding)
                .padding(.vertical, 16)
            }
            .id(step) // reset scroll position per step
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(AppColor.background.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            if canConfirm {
                Button {
                    onConfirm(room, furniture, spot)
                    dismiss()
                } label: {
                    Label("Confirm Location", systemImage: "checkmark")
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, AppMetrics.screenPadding)
                .padding(.top, 10)
                .padding(.bottom, 8)
                .background(AppColor.background.opacity(0.96).ignoresSafeArea())
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.22), value: step)
        .animation(.easeInOut(duration: 0.22), value: canConfirm)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(AppMetrics.cardRadius)
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                if step > 0 {
                    Button {
                        step -= 1
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(AppColor.text)
                            .frame(width: AppMetrics.minTouch, height: AppMetrics.minTouch)
                            .background(Circle().fill(Color.white))
                            .overlay(Circle().stroke(AppColor.border, lineWidth: 1))
                    }
                    .buttonStyle(PressableStyle())
                    .accessibilityLabel("Back")
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Storage Location")
                        .appFont(13, .semibold)
                        .foregroundStyle(AppColor.subtext)
                    Text(stepTitle)
                        .appFont(28, .bold, design: .rounded)
                        .foregroundStyle(AppColor.text)
                        .accessibilityAddTraits(.isHeader)
                }
                Spacer()
                stepDots
            }
        }
    }

    private var stepDots: some View {
        HStack(spacing: 6) {
            ForEach(0..<3) { index in
                Capsule()
                    .fill(index <= step ? AppColor.primary : AppColor.border)
                    .frame(width: index == step ? 20 : 8, height: 8)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Step \(step + 1) of 3")
    }

    private var breadcrumbChips: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 6) {
                chip("\(Room.emoji(for: room)) \(room)", targetStep: 0)
                if !furniture.isEmpty {
                    arrow
                    chip(furniture, targetStep: 1)
                }
                if !spot.isEmpty {
                    arrow
                    chip(spot, targetStep: 2)
                }
            }
            .padding(.horizontal, AppMetrics.screenPadding)
        }
        .scrollIndicators(.hidden)
    }

    private var arrow: some View {
        Image(systemName: "chevron.right")
            .appFont(11, .bold)
            .foregroundStyle(AppColor.muted)
            .accessibilityHidden(true)
    }

    private func chip(_ title: String, targetStep: Int) -> some View {
        Button {
            step = targetStep
        } label: {
            Text(title)
                .appFont(14, .semibold)
                .foregroundStyle(AppColor.primary)
                .padding(.horizontal, 12)
                .frame(minHeight: 36)
                .background(Capsule().fill(AppColor.tint))
                .contentShape(Capsule())
                .padding(.vertical, 4)
        }
        .buttonStyle(PressableStyle())
        .accessibilityHint("Change this step")
    }

    // MARK: Options

    private func optionRow(_ option: String) -> some View {
        let isSelected = option == selectedOption
        return Button {
            select(option)
        } label: {
            HStack(spacing: 14) {
                if step == 0 {
                    Text(Room.emoji(for: option))
                        .font(.system(size: 20))
                        .frame(width: 40, height: 40)
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Room.color(for: option).opacity(0.12)))
                }
                Text(option)
                    .appFont(16, .semibold)
                    .foregroundStyle(AppColor.text)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .appFont(20, .regular)
                        .foregroundStyle(AppColor.primary)
                } else if step < 2 {
                    Image(systemName: "chevron.right")
                        .appFont(13, .semibold)
                        .foregroundStyle(AppColor.chevron)
                }
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 60)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isSelected ? AppColor.tint : Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isSelected ? AppColor.primary.opacity(0.5) : AppColor.hairline, lineWidth: isSelected ? 1.5 : 1)
            )
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle())
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func select(_ option: String) {
        switch step {
        case 0:
            if option != room {
                room = option
                furniture = ""
                spot = ""
            }
            step = 1
        case 1:
            if option != furniture {
                furniture = option
                spot = ""
            }
            step = 2
        default:
            spot = option
        }
    }
}
