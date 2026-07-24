import SwiftUI
import Flow

struct ColorManager: View {
    let tagColors: TagColorManager
    
    @State var editingColor: TagColor?
    @State var newNamespace: Bool = false
    @State var namespaceInsertionError: Bool = false
    
    @State var newNamespaceName: String = ""
    @State var newNamespaceSlug: String = ""
    
    @Environment(\.dismiss) private var dismiss
    
    init(tagColors: TagColorManager) {
        self.tagColors = tagColors
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                ForEach(tagColors.namespaces) { namespace in
                    Text(
                        NSLocalizedString(
                            "colors.\(namespace.namespace)",
                            comment: ""
                        )
                    )
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                        .foregroundStyle(.secondary)
                    HFlow {
                        ForEach(namespace.colors) { color in
                            Button {
                                editingColor = color
                            } label: {
                                TagPreView(name: .constant(color.name), colors: .constant(color))
                            }
                            .disabled(namespace.namespace.starts(with: "tagstudio"))
                        }
                    }.frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal)
            }
            .navigationTitle("Color Manager")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    CloseButton(dismiss: dismiss)
                }
                ToolbarItem(placement: .bottomBar) {
                    Menu {
                        Menu {
                            ForEach(tagColors.namespaces) { namespace in
                                if !namespace.namespace.starts(with: "tagstudio") {
                                    Button {
                                        
                                    } label: {
                                        Text(namespace.namespace)
                                    }
                                }
                            }
                        } label: {
                            Label("Color", systemImage: "lightspectrum.horizontal")
                        }
                        Button {
                            newNamespace = true
                        } label: {
                            Label("Namespace", systemImage: "paintpalette")
                        }
                    } label: {
                        Label("New", systemImage: "plus")
                    }
                }
            }
        }
        .sheet(item: $editingColor) { editingColor in
            ColorEditor(
                manager: self.tagColors,
                color: editingColor
            )
        }
        .sheet(isPresented: $newNamespace) {
            NavigationStack {
                List {
                    HStack {
                        Text("Name")
                        TextField("Name", text: $newNamespaceName)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Slug")
                        TextField("Slug", text: $newNamespaceSlug)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.trailing)
                            .disabled(true)
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        CloseButton(dismiss: dismiss)
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            do {
                                try self.tagColors.newNamespace(name: newNamespaceName, namespace: newNamespaceSlug)
                            } catch {
                                print(error)
                                namespaceInsertionError = true
                            }
                            newNamespace = false
                        } label: {
                            Label("Save", systemImage: "checkmark")
                        }
                        .buttonStyle(ProminentButtonStyle())
                    }
                }
            }
        }
        .onChange(of: newNamespaceName){
            let updatedSlug = newNamespaceName
                .replacingOccurrences(of: " ", with: "-")
                .lowercased()
            newNamespaceSlug = updatedSlug
        }
        .alert("Namespace Creation Error", isPresented: $namespaceInsertionError) {
            
        } message: {
            Text("There was an error while trying to create your namespace.")
        }
    }
}

