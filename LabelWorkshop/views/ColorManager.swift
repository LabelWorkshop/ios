import SwiftUI
import Flow

struct ColorManager: View {
    let tagColors: TagColorManager
    
    @State var editingColor: TagColor?
    @State var newNamespace: Bool = false
    @State var namespaceInsertionError: Bool = false
    @State var namespaceDeletionError: Bool = false
    
    @State var newNamespaceName: String = ""
    @State var newNamespaceSlug: String = ""
    
    @State var renameNamespace: TagColorNamespace?
    
    @Environment(\.dismiss) private var dismiss
    
    init(tagColors: TagColorManager) {
        self.tagColors = tagColors
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                ForEach(tagColors.namespaces) { namespace in
                    HStack {
                        Text(namespace.displayName)
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                            .foregroundStyle(.secondary)
                        if !namespace.isReadOnly {
                            Menu {
                                Button {
                                    
                                } label: {
                                    Label("New Color", systemImage: "lightspectrum.horizontal")
                                }
                                Button {
                                    renameNamespace = namespace
                                } label: {
                                    Label("Rename", systemImage: "pencil")
                                }
                                Button(role: .destructive) {
                                    do {
                                        try tagColors.deleteNamespace(namespace: namespace)
                                    } catch {
                                        print(error)
                                        namespaceDeletionError = true
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            } label: {
                                Button {
                                    
                                } label: {
                                    Image(systemName: "ellipsis.circle.fill")
                                        .symbolRenderingMode(.hierarchical)
                                        .imageScale(.large)
                                }
                                .tint(.gray)
                            }
                        }
                    }
                    HFlow {
                        if namespace.colors.isEmpty {
                            Text("No Colors")
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .center)
                                .foregroundStyle(.secondary)
                                .font(.title3)
                        } else {
                            ForEach(namespace.colors) { color in
                                Button {
                                    editingColor = color
                                } label: {
                                    TagPreView(name: .constant(color.name), colors: .constant(color))
                                }
                                .disabled(namespace.isReadOnly)
                            }
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
                                if !namespace.isReadOnly {
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
                    if newNamespaceSlug.starts(with: "tagstudio") {
                        Section {
                            VStack {
                                HStack {
                                    Image(systemName: "exclamationmark.octagon.fill")
                                        .tint(.red)
                                        .symbolRenderingMode(.multicolor)
                                    Text("Namespace can't be created")
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                Text("This name is reserved for TagStudio")
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }.listRowBackground(Color.red.opacity(0.15))
                        }
                    }
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
                        .disabled(newNamespaceSlug.starts(with: "tagstudio"))
                    }
                }
                .navigationTitle("New Namespace")
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
        .alert("Namespace Delete Error", isPresented: $namespaceDeletionError) {
            
        } message: {
            Text("There was an error while trying to delete your namespace.")
        }
        .sheet(item: $renameNamespace) { renameNamespace in
            RenameNamespace(renameNamespace)
        }
    }
}

struct RenameNamespace: View {
    let renameNamespace: TagColorNamespace
    @State var name: String
    @Environment(\.dismiss) private var dismiss
    @State var namespaceRenameError: Bool = false
    
    init(_ renameNamespace: TagColorNamespace) {
        self.renameNamespace = renameNamespace
        self.name = renameNamespace.displayName
    }
    
    var body: some View {
        NavigationStack {
            List {
                TextField("Namespace", text: $name)
            }
            .presentationDetents([.fraction(0.2), .medium])
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CloseButton(dismiss: dismiss)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        do {
                            try renameNamespace.manager.renameNamespace(namespace: renameNamespace, to: name)
                            dismiss()
                        } catch {
                            namespaceRenameError = true
                        }
                    } label: {
                        Label("Save", systemImage: "checkmark")
                    }.buttonStyle(ProminentButtonStyle())
                }
            }
            .navigationTitle("Rename Namespace")
            .navigationBarTitleDisplayMode(.inline)
        }
        .alert("Namespace Rename Error", isPresented: $namespaceRenameError) {} message: {
            Text("There was an error while trying to rename your namespace.")
        }
    }
}
