import SwiftUI

struct ColorEditor: View {
    let manager: TagColorManager
    let color: TagColor
    
    @Environment(\.dismiss) var dismiss
    
    @State var name: String
    @State var slug: String
    @State var primary: Color
    @State var secondary: Color
    @State var secondaryAsBorder: Bool
    
    init(manager: TagColorManager, color: TagColor) {
        self.manager = manager
        self.color = color
        self.name = color.name
        self.slug = color.slug
        self.primary = color.background
        self.secondary = color.border
        self.secondaryAsBorder = false // CHANGE THIS!!!
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
                }
                
                ColorPicker("Primary", selection: $primary)
                ColorPicker("Secondary", selection: $secondary)
                
                Toggle("Use secondary as border", isOn: $secondaryAsBorder)
            }.navigationTitle($name)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        CloseButton(dismiss: dismiss)
                    }
                }
        }
    }
}
