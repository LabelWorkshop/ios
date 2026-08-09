import SwiftUI

struct ColorEditor: View {
    let manager: TagColorManager
    let color: TagColor?
    let belongingNamespace: String?
    
    @Environment(\.dismiss) var dismiss
    
    @State var name: String
    @State var slug: String
    @State var primary: Color
    @State var secondary: Color
    @State var secondaryAsBorder: Bool
    
    @State var saveError: Bool = false
    
    init(manager: TagColorManager, color: TagColor) {
        self.manager = manager
        self.color = color
        self.name = color.name
        self.slug = color.slug
        self.primary = color.background
        self.secondary = color.border
        self.secondaryAsBorder = color.useSecondaryBorder
        self.belongingNamespace = nil
    }
    
    init(manager: TagColorManager, belongingNamespace: String) {
        self.manager = manager
        self.color = nil
        self.name = "New Color"
        self.slug = "new-color"
        self.primary = TagColor.none.background
        self.secondary = TagColor.none.border
        self.secondaryAsBorder = false
        self.belongingNamespace = belongingNamespace
    }
    
    init(manager: TagColorManager, belongingNamespace: TagColorNamespace) {
        self.init(manager: manager, belongingNamespace: belongingNamespace.namespace)
    }
    
    var body: some View {
        NavigationView {
            List {
                HStack {
                    Text("Name")
                    TextField("Name", text: $name)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.trailing)
                }
                HStack {
                    Text("Slug")
                    TextField("Slug", text: $slug)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.trailing)
                        .disabled(true)
                }
                
                ColorPicker("Primary", selection: $primary)
                ColorPicker("Secondary", selection: $secondary)
                
                Toggle("Use secondary as border", isOn: $secondaryAsBorder)
            }.navigationTitle($name)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    CloseButton(dismiss: dismiss)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        do {
                            if let color = color{
                                try manager.updateColor(
                                    color: color,
                                    primary: primary,
                                    secondary: secondary,
                                    name: name,
                                    slug: slug,
                                    secondaryAsBorder: secondaryAsBorder
                                )
                            } else {
                                _ = try manager.newColor(
                                    namespace: belongingNamespace ?? "",
                                    primary: primary,
                                    secondary: secondary,
                                    name: name,
                                    slug: slug,
                                    secondaryAsBorder: secondaryAsBorder
                                )
                            }
                            dismiss()
                        } catch {
                            print(error)
                            saveError = true
                        }
                    } label: {
                        Label("Save", systemImage: "checkmark")
                    }
                    .buttonStyle(ProminentButtonStyle())
                    .alert("Save Error", isPresented: $saveError) {} message: {
                        Text("Failed to save color.")
                    }
                }
            }
        }.onChange(of: name) {
            let updatedSlug = name
                .replacingOccurrences(of: " ", with: "-")
                .lowercased()
            slug = updatedSlug
        }
    }
}
