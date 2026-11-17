import UIKit

/// Stores item photos as JPEG files in the app's Documents directory.
/// Items only ever keep the bare filename; the full URL is resolved against the *current*
/// Documents directory each time (the container path changes between installs/updates).
nonisolated final class ImageStorage: @unchecked Sendable {
    static let shared = ImageStorage()

    private let cache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private let maxPixelSize: CGFloat = 1600
    private let jpegQuality: CGFloat = 0.85

    private init() {
        cache.countLimit = 60
    }

    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    /// Resolves a stored filename to a file URL in the current Documents directory.
    /// Tolerates legacy absolute paths by only using their last path component.
    func fileURL(for filename: String) -> URL? {
        let trimmed = filename.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let name = (trimmed as NSString).lastPathComponent
        guard !name.isEmpty else { return nil }
        return documentsDirectory.appendingPathComponent(name, isDirectory: false)
    }

    /// Downscales, encodes and writes the image. Returns the bare filename, or nil on failure / nil input.
    func save(_ image: UIImage?) -> String? {
        guard let image else { return nil }
        let resized = downscaled(image)
        guard let data = resized.jpegData(compressionQuality: jpegQuality) else { return nil }
        let filename = "\(UUID().uuidString).jpg"
        guard let url = fileURL(for: filename) else { return nil }
        do {
            try data.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
            cache.setObject(resized, forKey: filename as NSString)
            return filename
        } catch {
            #if DEBUG
            print("ImageStorage: failed to save image – \(error)")
            #endif
            return nil
        }
    }

    /// Returns a cached image if one is already in memory (cheap, safe to call during view updates).
    func cachedImage(for filename: String) -> UIImage? {
        guard !filename.isEmpty else { return nil }
        return cache.object(forKey: key(for: filename))
    }

    /// Loads an image from disk (using the cache when possible).
    func load(from filename: String) -> UIImage? {
        guard !filename.isEmpty else { return nil }
        let cacheKey = key(for: filename)
        if let cached = cache.object(forKey: cacheKey) { return cached }
        guard let url = fileURL(for: filename),
              let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else { return nil }
        let prepared = image.preparingForDisplay() ?? image
        cache.setObject(prepared, forKey: cacheKey)
        return prepared
    }

    /// Deletes a stored photo file (no-op for an empty name or a missing file).
    func delete(_ filename: String) {
        guard !filename.isEmpty else { return }
        cache.removeObject(forKey: key(for: filename))
        guard let url = fileURL(for: filename), fileManager.fileExists(atPath: url.path) else { return }
        do {
            try fileManager.removeItem(at: url)
        } catch {
            #if DEBUG
            print("ImageStorage: failed to delete \(filename) – \(error)")
            #endif
        }
    }

    // MARK: Private

    private func key(for filename: String) -> NSString {
        (filename as NSString).lastPathComponent as NSString
    }

    private func downscaled(_ image: UIImage) -> UIImage {
        let pixelWidth = image.size.width * image.scale
        let pixelHeight = image.size.height * image.scale
        let longSide = max(pixelWidth, pixelHeight)
        let ratio = longSide > maxPixelSize ? maxPixelSize / longSide : 1
        let target = CGSize(width: (pixelWidth * ratio).rounded(), height: (pixelHeight * ratio).rounded())

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        // Redrawing also normalises orientation (camera photos are often rotated via EXIF).
        return UIGraphicsImageRenderer(size: target, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
    }
}
