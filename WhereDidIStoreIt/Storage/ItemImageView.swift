import SwiftUI
import UIKit

/// Shows an item's locally stored photo, or `placeholder` when there is none.
/// Built as `Color.clear.overlay { … }.clipped()` so an aspect-filled image can never inflate the layout:
/// the caller's frame decides the size.
struct ItemImageView<Placeholder: View>: View {
    let imageURL: String
    @ViewBuilder var placeholder: () -> Placeholder

    @State private var image: UIImage?
    @State private var loadedName: String?

    init(imageURL: String, @ViewBuilder placeholder: @escaping () -> Placeholder) {
        self.imageURL = imageURL
        self.placeholder = placeholder
        _image = State(initialValue: ImageStorage.shared.cachedImage(for: imageURL))
        _loadedName = State(initialValue: ImageStorage.shared.cachedImage(for: imageURL) == nil ? nil : imageURL)
    }

    var body: some View {
        Color.clear
            .overlay {
                if let image, loadedName == imageURL {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    placeholder()
                }
            }
            .clipped()
            .task(id: imageURL) {
                await load()
            }
    }

    private func load() async {
        let name = imageURL
        guard !name.isEmpty else {
            image = nil
            loadedName = nil
            return
        }
        if loadedName == name, image != nil { return }
        let loaded = await Task.detached(priority: .userInitiated) {
            ImageStorage.shared.load(from: name)
        }.value
        guard !Task.isCancelled else { return }
        image = loaded
        loadedName = loaded == nil ? nil : name
    }
}

/// Standard emoji placeholder for an item without a photo.
struct CategoryPlaceholder: View {
    let category: ItemCategory
    var emojiSize: CGFloat = 40

    var body: some View {
        ZStack {
            category.color.opacity(0.12)
            Text(category.emoji)
                .font(.system(size: emojiSize))
        }
        .accessibilityHidden(true)
    }
}
