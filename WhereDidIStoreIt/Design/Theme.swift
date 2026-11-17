import SwiftUI
import UIKit

// MARK: - Hex colors

extension Color {
    /// Creates a color from a hex string. Supports RGB (3), RGBA (4), RRGGBB (6) and RRGGBBAA (8) digits,
    /// with or without a leading "#".
    nonisolated init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)

        let r, g, b, a: Double
        switch cleaned.count {
        case 3:
            r = Double((value >> 8) & 0xF) / 15
            g = Double((value >> 4) & 0xF) / 15
            b = Double(value & 0xF) / 15
            a = 1
        case 4:
            r = Double((value >> 12) & 0xF) / 15
            g = Double((value >> 8) & 0xF) / 15
            b = Double((value >> 4) & 0xF) / 15
            a = Double(value & 0xF) / 15
        case 6:
            r = Double((value >> 16) & 0xFF) / 255
            g = Double((value >> 8) & 0xFF) / 255
            b = Double(value & 0xFF) / 255
            a = 1
        case 8:
            r = Double((value >> 24) & 0xFF) / 255
            g = Double((value >> 16) & 0xFF) / 255
            b = Double((value >> 8) & 0xFF) / 255
            a = Double(value & 0xFF) / 255
        default:
            r = 0; g = 0; b = 0; a = 1
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}

// MARK: - Design tokens

enum AppColor {
    static let primary = Color(hex: "5B5CE2")
    static let primaryLight = Color(hex: "7B7CF4")
    static let tint = Color(hex: "EEF0FF")
    static let background = Color(hex: "F8F9FC")
    static let text = Color(hex: "17181C")
    static let subtext = Color(hex: "6B7280")
    static let muted = Color(hex: "9CA3AF")
    static let border = Color(hex: "E8EAF0")
    static let hairline = Color(hex: "F0F1F5")
    static let chevron = Color(hex: "D1D5DB")
    static let success = Color(hex: "22C55E")
    static let danger = Color(hex: "EF4444")
    static let dangerBg = Color(hex: "FEF2F2")
    /// Darker red for destructive *text* only: `danger` on white is 3.8:1, this is 4.8:1 (WCAG AA).
    static let dangerText = Color(hex: "DC2626")

    /// primaryLight only as a top-left highlight, so white labels sit on `primary` (5.2:1 contrast
    /// instead of 3.5:1 on primaryLight).
    static let primaryGradient = LinearGradient(
        stops: [.init(color: primaryLight, location: 0), .init(color: primary, location: 0.45)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

enum AppMetrics {
    static let cardRadius: CGFloat = 24
    static let searchHeight: CGFloat = 50
    static let searchRadius: CGFloat = 24
    static let screenPadding: CGFloat = 20
    static let minTouch: CGFloat = 44
}

extension Font {
    /// SF Rounded, bold – used for titles.
    static func rounded(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    static let screenTitle = Font.rounded(28)
    static let sectionTitle = Font.rounded(20)
}

// MARK: - Dynamic Type

/// Fixed design sizes that still follow the user's text-size setting (Dynamic Type).
/// The design size is used at the default setting and scaled with UIFontMetrics otherwise.
struct ScaledFont: ViewModifier {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let size: CGFloat
    let weight: Font.Weight
    let design: Font.Design

    func body(content: Content) -> some View {
        let style: UIFont.TextStyle = size >= 26 ? .title1 : (size >= 20 ? .title3 : .body)
        let traits = UITraitCollection(preferredContentSizeCategory: UIContentSizeCategory(dynamicTypeSize))
        let scaled = UIFontMetrics(forTextStyle: style).scaledValue(for: size, compatibleWith: traits)
        return content.font(.system(size: scaled, weight: weight, design: design))
    }
}

extension View {
    func appFont(_ size: CGFloat, _ weight: Font.Weight = .regular, design: Font.Design = .default) -> some View {
        modifier(ScaledFont(size: size, weight: weight, design: design))
    }
}

// MARK: - Haptics

enum Haptics {
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func impact() { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
}

// MARK: - Card style

struct CardStyle: ViewModifier {
    var radius: CGFloat = AppMetrics.cardRadius

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(AppColor.hairline, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 2)
    }
}

extension View {
    func card(radius: CGFloat = AppMetrics.cardRadius) -> some View {
        modifier(CardStyle(radius: radius))
    }
}

// MARK: - Buttons

/// Gives any tappable content a subtle press feedback without changing its layout bounds.
/// With Reduce Motion on, only the opacity changes (no scaling).
struct PressableStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// Purple gradient primary button.
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .appFont(17, .semibold, design: .rounded)
            .multilineTextAlignment(.center)
            .padding(.vertical, 8)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isEnabled ? AnyShapeStyle(AppColor.primaryGradient) : AnyShapeStyle(AppColor.muted.opacity(0.5)))
            )
            .shadow(color: AppColor.primary.opacity(isEnabled ? 0.3 : 0), radius: 12, x: 0, y: 6)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// Round floating icon button (used over hero images and in headers). 44pt hit area.
struct CircleIconButton: View {
    let systemName: String
    let accessibilityLabel: String
    var foreground: Color = AppColor.text
    var background: Color = .white
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(foreground)
                .frame(width: AppMetrics.minTouch, height: AppMetrics.minTouch)
                .background(Circle().fill(background))
                .overlay(Circle().stroke(AppColor.hairline, lineWidth: 1))
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel(accessibilityLabel)
    }
}
