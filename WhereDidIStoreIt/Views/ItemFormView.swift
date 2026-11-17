import SwiftUI
import UIKit

/// Shared Add / Edit item screen.
struct ItemFormView: View {
    enum Mode {
        case add
        case edit(Item)

        var original: Item? {
            if case .edit(let item) = self { return item }
            return nil
        }
    }

    /// What the user did to the photo in this session.
    private enum PhotoChange {
        case unchanged
        case replaced(UIImage)
        case removed
    }

    let mode: Mode
    var onSaved: ((Item) -> Void)?

    @EnvironmentObject private var store: ItemStore
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var category: String
    @State private var room: String
    @State private var furniture: String
    @State private var spot: String
    @State private var description: String
    @State private var notes: String
    @State private var photoChange: PhotoChange = .unchanged
    @State private var showPhotoSource = false
    @State private var showLocationPicker = false
    @FocusState private var focusedField: Field?

    private enum Field { case name, description, notes }

    init(mode: Mode, onSaved: ((Item) -> Void)? = nil) {
        self.mode = mode
        self.onSaved = onSaved
        let item = mode.original
        _name = State(initialValue: item?.name ?? "")
        _category = State(initialValue: item?.category ?? ItemCategory.all[0].id)
        _room = State(initialValue: item?.room ?? "")
        _furniture = State(initialValue: item?.furniture ?? "")
        _spot = State(initialValue: item?.spot ?? "")
        _description = State(initialValue: item?.description ?? "")
        _notes = State(initialValue: item?.notes ?? "")
    }

    // MARK: Derived state

    private var isEditing: Bool { mode.original != nil }
    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var hasLocation: Bool { !room.isEmpty && !furniture.isEmpty && !spot.isEmpty }
    private var canSave: Bool { !trimmedName.isEmpty && hasLocation }

    /// Explains why Save is disabled (shown under the button), nil when saving is possible.
    private var missingRequirement: String? {
        switch (trimmedName.isEmpty, hasLocation) {
        case (true, false): return "Add a name and choose a storage location to save."
        case (true, true): return "Add a name to save."
        case (false, false): return "Choose a storage location to save."
        case (false, true): return nil
        }
    }

    /// The original photo filename that is still in effect (nil when removed/replaced or none).
    private var existingPhoto: String? {
        guard case .unchanged = photoChange, let file = mode.original?.imageURL, !file.isEmpty else { return nil }
        return file
    }

    private var hasAnyPhoto: Bool {
        if case .replaced = photoChange { return true }
        return existingPhoto != nil
    }

    private var hasChanges: Bool {
        guard let original = mode.original else {
            return !trimmedName.isEmpty || hasLocation || hasAnyPhoto
                || !description.isEmpty || !notes.isEmpty
        }
        if case .unchanged = photoChange {} else { return true }
        return trimmedName != original.name || category != original.category || room != original.room
            || furniture != original.furniture || spot != original.spot
            || description.trimmingCharacters(in: .whitespacesAndNewlines) != original.description
            || notes.trimmingCharacters(in: .whitespacesAndNewlines) != original.notes
    }

    // MARK: Body

    var body: some View {
        VStack(spacing: 0) {
            topBar
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    photoSection
                    field(title: "Item Name") {
                        TextField("e.g. Passport", text: $name)
                            .appFont(16, .regular)
                            .foregroundStyle(AppColor.text)
                            .textInputAutocapitalization(.words)
                            .submitLabel(.done)
                            .focused($focusedField, equals: .name)
                            .padding(.horizontal, 16)
                            .frame(minHeight: 52)
                            .card(radius: 16)
                    }
                    field(title: "Category") { categoryMenu }
                    field(title: "Storage Location") { locationButton }
                    field(title: "Description", optional: true) {
                        textEditor(text: $description, placeholder: "What does it look like?", field: .description)
                    }
                    field(title: "Notes", optional: true) {
                        textEditor(text: $notes, placeholder: "Anything else worth remembering?", field: .notes)
                    }
                }
                .padding(.horizontal, AppMetrics.screenPadding)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .background(AppColor.background.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 8) {
                if let missingRequirement {
                    Label(missingRequirement, systemImage: "info.circle")
                        .appFont(13, .medium)
                        .foregroundStyle(AppColor.subtext)
                        .multilineTextAlignment(.center)
                }
                Button(isEditing ? "Save Changes" : "Save Item", action: save)
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(!canSave)
                    .accessibilityHint(missingRequirement ?? "")
            }
                .padding(.horizontal, AppMetrics.screenPadding)
                .padding(.top, 10)
                .padding(.bottom, 8)
                .background(AppColor.background.opacity(0.96).ignoresSafeArea())
        }
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(hasChanges)
        .sheet(isPresented: $showPhotoSource) {
            PhotoSourceSheet(onRemove: hasAnyPhoto ? { photoChange = isEditing ? .removed : .unchanged } : nil) { image in
                photoChange = .replaced(image)
            }
        }
        .sheet(isPresented: $showLocationPicker) {
            LocationPickerView(room: room, furniture: furniture, spot: spot) { newRoom, newFurniture, newSpot in
                room = newRoom
                furniture = newFurniture
                spot = newSpot
            }
        }
    }

    // MARK: Sections

    private var topBar: some View {
        ZStack {
            Text(isEditing ? "Edit Item" : "Store an Item")
                .appFont(18, .bold, design: .rounded)
                .foregroundStyle(AppColor.text)
                .accessibilityAddTraits(.isHeader)
            HStack {
                Button("Cancel") { dismiss() }
                    .appFont(16, .medium)
                    .foregroundStyle(AppColor.subtext)
                    .frame(minHeight: AppMetrics.minTouch)
                    .contentShape(Rectangle())
                Spacer()
            }
        }
        .padding(.horizontal, AppMetrics.screenPadding)
        .padding(.top, 14)
        .padding(.bottom, 6)
    }

    private var photoSection: some View {
        Button {
            focusedField = nil
            showPhotoSource = true
        } label: {
            ZStack {
                if case .replaced(let image) = photoChange {
                    Color.clear.overlay {
                        Image(uiImage: image).resizable().scaledToFill()
                    }
                    .clipped()
                } else if let existingPhoto {
                    ItemImageView(imageURL: existingPhoto) { photoPlaceholder }
                } else {
                    photoPlaceholder
                }
            }
            .frame(height: 200)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: AppMetrics.cardRadius, style: .continuous))
            .overlay(alignment: .bottomTrailing) {
                if hasAnyPhoto {
                    Label("Change", systemImage: "camera.fill")
                        .appFont(13, .semibold)
                        .foregroundStyle(AppColor.text)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Color.white.opacity(0.95)))
                        .padding(12)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel(hasAnyPhoto ? "Change or remove photo" : "Add photo, optional")
    }

    private var photoPlaceholder: some View {
        VStack(spacing: 10) {
            Image(systemName: "camera.fill")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(AppColor.primary)
                .frame(width: 56, height: 56)
                .background(Circle().fill(Color.white))
            Text("Add a Photo")
                .appFont(15, .semibold)
                .foregroundStyle(AppColor.primary)
            Text("Optional — helps you recognize it later")
                .appFont(13, .regular)
                .foregroundStyle(AppColor.subtext)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColor.tint)
        .overlay(
            RoundedRectangle(cornerRadius: AppMetrics.cardRadius, style: .continuous)
                .strokeBorder(AppColor.primary.opacity(0.35), style: StrokeStyle(lineWidth: 1.5, dash: [6, 5]))
        )
    }

    private var categoryMenu: some View {
        let current = ItemCategory.with(id: category)
        return Menu {
            Picker("Category", selection: $category) {
                ForEach(ItemCategory.all) { cat in
                    Text("\(cat.emoji)  \(cat.label)").tag(cat.id)
                }
            }
        } label: {
            HStack(spacing: 12) {
                Text(current.emoji)
                    .font(.system(size: 18))
                    .frame(width: 36, height: 36)
                    .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(current.color.opacity(0.12)))
                Text(current.label)
                    .appFont(16, .medium)
                    .foregroundStyle(AppColor.text)
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .appFont(13, .semibold)
                    .foregroundStyle(AppColor.subtext)
            }
            .padding(.horizontal, 12)
            .frame(minHeight: 56)
            .card(radius: 16)
            .contentShape(Rectangle())
        }
        .accessibilityLabel("Category, \(current.label)")
    }

    private var locationButton: some View {
        Button {
            focusedField = nil
            showLocationPicker = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AppColor.primary)
                    .frame(width: 36, height: 36)
                    .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(AppColor.tint))
                VStack(alignment: .leading, spacing: 2) {
                    if hasLocation {
                        Text("\(Room.emoji(for: room)) \(room)")
                            .appFont(16, .semibold)
                            .foregroundStyle(AppColor.text)
                        Text(Item.makeLocation(furniture: furniture, spot: spot))
                            .appFont(13, .regular)
                            .foregroundStyle(AppColor.subtext)
                    } else {
                        Text("Choose where it's stored")
                            .appFont(16, .medium)
                            .foregroundStyle(AppColor.subtext)
                    }
                }
                .multilineTextAlignment(.leading)
                Spacer()
                Image(systemName: "chevron.right")
                    .appFont(13, .semibold)
                    .foregroundStyle(AppColor.chevron)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(minHeight: 56)
            .card(radius: 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel(hasLocation
            ? "Storage location, \(Item.makeBreadcrumb(room: room, furniture: furniture, spot: spot))"
            : "Choose storage location")
    }

    // MARK: Building blocks

    private func field<Content: View>(title: String, optional: Bool = false,
                                      @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text(title)
                    .appFont(14, .semibold)
                    .foregroundStyle(AppColor.text)
                if optional {
                    Text("Optional")
                        .appFont(12, .medium)
                        .foregroundStyle(AppColor.subtext)
                }
            }
            content()
        }
    }

    private func textEditor(text: Binding<String>, placeholder: String, field: Field) -> some View {
        ZStack(alignment: .topLeading) {
            if text.wrappedValue.isEmpty {
                Text(placeholder)
                    .appFont(16, .regular)
                    .foregroundStyle(AppColor.subtext)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
            TextEditor(text: text)
                .appFont(16, .regular)
                .foregroundStyle(AppColor.text)
                .scrollContentBackground(.hidden)
                .focused($focusedField, equals: field)
                .padding(.horizontal, 11)
                .padding(.vertical, 6)
                .accessibilityLabel(placeholder)
        }
        .frame(minHeight: 96)
        .card(radius: 16)
    }

    // MARK: Save

    private func save() {
        guard canSave else { return }
        let cleanDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)

        if let original = mode.original {
            var updated = original
            updated.name = trimmedName
            updated.category = category
            updated.setLocation(room: room, furniture: furniture, spot: spot)
            updated.description = cleanDescription
            updated.notes = cleanNotes
            switch photoChange {
            case .unchanged:
                break
            case .removed:
                updated.imageURL = ""
            case .replaced(let image):
                // Only write a new file when the photo actually changed; keep the old one if saving fails.
                if let file = ImageStorage.shared.save(image) { updated.imageURL = file }
            }
            store.updateItem(updated) // deletes the previous photo file if it was replaced/removed
            onSaved?(updated)
        } else {
            var imageFile = ""
            if case .replaced(let image) = photoChange {
                imageFile = ImageStorage.shared.save(image) ?? ""
            }
            let item = Item(
                name: trimmedName,
                category: category,
                room: room,
                furniture: furniture,
                spot: spot,
                description: cleanDescription,
                imageURL: imageFile,
                notes: cleanNotes
            )
            store.addItem(item)
            onSaved?(item)
        }
        Haptics.success()
        dismiss()
    }
}
