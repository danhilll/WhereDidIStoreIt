import SwiftUI
import PhotosUI
import UIKit

// MARK: - Photo library

/// PHPicker wrapper: images only, single selection. Calls `onPick` with the image (or nil if cancelled).
struct PhotoPicker: UIViewControllerRepresentable {
    let onPick: (UIImage?) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        config.preferredAssetRepresentationMode = .current
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let onPick: (UIImage?) -> Void

        init(onPick: @escaping (UIImage?) -> Void) {
            self.onPick = onPick
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else {
                onPick(nil)
                return
            }
            let callback = onPick
            provider.loadObject(ofClass: UIImage.self) { object, _ in
                let image = object as? UIImage
                Task { @MainActor in
                    callback(image)
                }
            }
        }
    }
}

// MARK: - Camera

/// UIImagePickerController camera wrapper. Only present it when `CameraPicker.isAvailable`.
struct CameraPicker: UIViewControllerRepresentable {
    let onPick: (UIImage?) -> Void

    static var isAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.allowsEditing = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onPick: (UIImage?) -> Void

        init(onPick: @escaping (UIImage?) -> Void) {
            self.onPick = onPick
        }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            onPick(info[.originalImage] as? UIImage)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onPick(nil)
        }
    }
}

// MARK: - Source chooser sheet

/// A normal bottom sheet offering "Take Photo" (only when a camera exists) and "Choose from Photos".
/// It dismisses itself once a photo has been chosen and then hands the image to `onPick`.
struct PhotoSourceSheet: View {
    /// When non-nil, a "Remove Photo" option is shown.
    var onRemove: (() -> Void)?
    let onPick: (UIImage) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showCamera = false
    @State private var showLibrary = false
    @State private var pickedImage: UIImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add a Photo")
                .appFont(20, .bold, design: .rounded)
                .foregroundStyle(AppColor.text)
                .padding(.bottom, 4)

            if CameraPicker.isAvailable {
                sourceRow(icon: "camera.fill", title: "Take Photo") { showCamera = true }
            }
            sourceRow(icon: "photo.on.rectangle", title: "Choose from Photos") { showLibrary = true }

            if let onRemove {
                sourceRow(icon: "trash", title: "Remove Photo", tint: AppColor.danger, background: AppColor.dangerBg) {
                    onRemove()
                    dismiss()
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, AppMetrics.screenPadding)
        .padding(.top, 28)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(AppColor.background)
        .presentationDetents([.height(onRemove == nil ? 240 : 310)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(AppMetrics.cardRadius)
        .fullScreenCover(isPresented: $showCamera, onDismiss: deliverPick) {
            CameraPicker { image in
                pickedImage = image
                showCamera = false
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showLibrary, onDismiss: deliverPick) {
            PhotoPicker { image in
                pickedImage = image
                showLibrary = false
            }
            .ignoresSafeArea()
        }
    }

    /// Runs after the camera / library has fully dismissed, so the sheet can then close cleanly.
    private func deliverPick() {
        guard let image = pickedImage else { return }
        pickedImage = nil
        onPick(image)
        dismiss()
    }

    private func sourceRow(icon: String, title: String, tint: Color = AppColor.primary,
                           background: Color = AppColor.tint, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 44, height: 44)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(background))
                Text(title)
                    .appFont(16, .semibold)
                    .foregroundStyle(tint == AppColor.danger ? AppColor.dangerText : AppColor.text)
                Spacer()
                Image(systemName: "chevron.right")
                    .appFont(13, .semibold)
                    .foregroundStyle(AppColor.chevron)
            }
            .padding(10)
            .contentShape(Rectangle())
            .card(radius: 18)
        }
        .buttonStyle(PressableStyle())
    }
}
