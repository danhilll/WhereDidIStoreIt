import SwiftUI

struct OnboardingPage: Identifiable {
    let id: Int
    let title: String
    let message: String
    let emoji: String
    let symbol: String
    let badges: [String]

    static let all: [OnboardingPage] = [
        OnboardingPage(
            id: 0,
            title: "Remember Where You Put Things.",
            message: "Save the location of your belongings so you can find them later — no more hunting through every drawer.",
            emoji: "🏠",
            symbol: "mappin.and.ellipse",
            badges: ["🛏️", "🗄️", "🔑"]
        ),
        OnboardingPage(
            id: 1,
            title: "Capture It.",
            message: "Take a photo and give your item a storage location. Add notes for extra detail.",
            emoji: "📸",
            symbol: "camera.fill",
            badges: ["📝", "📦", "🏷️"]
        ),
        OnboardingPage(
            id: 2,
            title: "Find It Instantly.",
            message: "Search for something you stored and see exactly where it belongs — room, shelf, or drawer.",
            emoji: "🔍",
            symbol: "magnifyingglass",
            badges: ["📍", "✨", "🧭"]
        ),
    ]
}

/// Three swipeable intro pages. Also reused from Settings → "How It Works" (`isReplay = true`).
struct OnboardingView: View {
    var isReplay = false
    let onFinish: () -> Void

    @State private var page = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    private let pages = OnboardingPage.all

    private var isLastPage: Bool { page == pages.count - 1 }

    var body: some View {
        VStack(spacing: 0) {
            // Top bar
            HStack {
                Spacer()
                Button(isReplay ? "Close" : "Skip", action: onFinish)
                    .appFont(16, .semibold)
                    .foregroundStyle(AppColor.subtext)
                    .frame(minWidth: AppMetrics.minTouch, minHeight: AppMetrics.minTouch)
                    .contentShape(Rectangle())
                    .opacity(isLastPage && !isReplay ? 0 : 1)
                    .disabled(isLastPage && !isReplay)
            }
            .padding(.horizontal, AppMetrics.screenPadding)
            .padding(.top, 8)

            TabView(selection: $page) {
                ForEach(pages) { item in
                    pageView(item).tag(item.id)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: page)

            // Progress capsules
            HStack(spacing: 8) {
                ForEach(pages) { item in
                    Capsule()
                        .fill(item.id == page ? AppColor.primary : AppColor.border)
                        .frame(width: item.id == page ? 28 : 8, height: 8)
                }
            }
            .animation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.8), value: page)
            .accessibilityElement()
            .accessibilityLabel("Page \(page + 1) of \(pages.count)")
            .padding(.bottom, 28)

            Button {
                if isLastPage {
                    onFinish()
                } else {
                    withAnimation(reduceMotion ? nil : .default) { page += 1 }
                }
            } label: {
                HStack(spacing: 8) {
                    Text(isLastPage ? (isReplay ? "Done" : "Get Started") : "Continue")
                    Image(systemName: "arrow.right")
                        .appFont(15, .bold)
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .background(AppColor.background.ignoresSafeArea())
    }

    /// Centered when it fits; scrolls (instead of overlapping the dots) at large text sizes.
    private func pageView(_ item: OnboardingPage) -> some View {
        GeometryReader { geo in
            ScrollView {
                pageContent(item)
                    .frame(minHeight: geo.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicators(.hidden)
        }
    }

    private func pageContent(_ item: OnboardingPage) -> some View {
        let compact = dynamicTypeSize.isAccessibilitySize
        return VStack(spacing: 0) {
            Spacer(minLength: 12)
            Illustration(page: item)
                .scaleEffect(compact ? 0.72 : 1)
                .frame(height: compact ? 210 : 280)
            Spacer(minLength: 24)
            VStack(spacing: 14) {
                Text(item.title)
                    .appFont(28, .bold, design: .rounded)
                    .foregroundStyle(AppColor.text)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Text(item.message)
                    .appFont(16, .regular)
                    .foregroundStyle(AppColor.subtext)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 32)
            Spacer(minLength: 24)
        }
    }
}

/// Code-drawn illustration: gradient disc with a big emoji, an SF Symbol badge and floating emoji bubbles.
private struct Illustration: View {
    let page: OnboardingPage

    var body: some View {
        ZStack {
            Circle()
                .fill(AppColor.tint)
                .frame(width: 260, height: 260)
            Circle()
                .fill(AppColor.primaryGradient)
                .frame(width: 170, height: 170)
                .shadow(color: AppColor.primary.opacity(0.35), radius: 24, x: 0, y: 12)
            Text(page.emoji)
                .font(.system(size: 78))

            Image(systemName: page.symbol)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(AppColor.primary)
                .frame(width: 56, height: 56)
                .background(Circle().fill(Color.white))
                .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
                .offset(x: 72, y: 72)

            ForEach(Array(page.badges.enumerated()), id: \.offset) { index, badge in
                Text(badge)
                    .font(.system(size: 24))
                    .frame(width: 50, height: 50)
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.white))
                    .shadow(color: .black.opacity(0.07), radius: 10, x: 0, y: 4)
                    .offset(badgeOffset(index))
            }
        }
        .accessibilityHidden(true)
    }

    private func badgeOffset(_ index: Int) -> CGSize {
        switch index {
        case 0: return CGSize(width: -110, height: -70)
        case 1: return CGSize(width: 105, height: -95)
        default: return CGSize(width: -95, height: 95)
        }
    }
}

#Preview {
    OnboardingView {}
}
