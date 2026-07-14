import SwiftUI

struct TagSearch: View {
    let selectAction: (_: Tag) -> Void
    let multiSelect: Bool
    let library: Library?
    var tags: [Tag]
    @State var visableTags: [Tag]
    @State var searchQuery: String = ""
    @State var selected: [Tag]
    
    @Environment(\.dismiss) private var dismiss
    
    init(tags: [Tag], selectAction: @escaping (_: Tag) -> Void, multiSelect: Bool, selected: [Tag]) {
        self.tags = tags
        self.visableTags = tags
        self.multiSelect = multiSelect
        self.selectAction = selectAction
        self.selected = selected
        self.library = nil
        self.updateTags()
    }
    
    init(library: Library, tags: [Tag], selectAction: @escaping (_: Tag) -> Void, multiSelect: Bool, selected: [Tag]) {
        self.tags = tags
        self.visableTags = tags
        self.multiSelect = multiSelect
        self.selectAction = selectAction
        self.selected = selected
        self.library = library
        self.updateTags()
    }
    
    func updateTags() {
        if searchQuery.isEmpty {
            self.visableTags = self.tags
            return
        }
        self.visableTags = self.tags.filter { tag in
            var fullName = tag.name
            if let library = self.library {
                var parentNames: String = " "
                for parent in library.tags.getParentTags(of: tag) {
                    parentNames.append("\(parent.name) ")
                }
                fullName.append(parentNames)
            }
            return fullName.lowercased().contains(searchQuery.lowercased())
        }
    }
    
    func isTagSelected(_ tag: Tag) -> Bool {
        self.selected.contains(tag)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    ForEach(visableTags) { tag in
                        let tagSelectionBinding = Binding<Bool>(
                            get: { self.isTagSelected(tag) },
                            set: { newValue in
                                if newValue {
                                    if !self.selected.contains(tag) {
                                        self.selected.append(tag)
                                    }
                                } else {
                                    if let index = self.selected.firstIndex(of: tag) {
                                        self.selected.remove(at: index)
                                    }
                                }
                                self.selectAction(tag)
                            }
                        )
                        HStack {
                            if multiSelect {
                                Toggle("Selected", isOn: tagSelectionBinding).labelsHidden()
                            }
                            Button(action: {
                                if !multiSelect {
                                    self.selectAction(tag)
                                    self.dismiss()
                                } else {
                                    tagSelectionBinding.wrappedValue = !self.isTagSelected(tag)
                                }
                            }) {
                                TagView(tag: tag, fullWidth: true)
                            }
                        }
                    }
                }
                .padding(16)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        self.dismiss()
                    }) {
                        Image(systemName: "chevron.backward")
                    }
                }
            }
        }
        .searchable(text: $searchQuery)
        .onChange(of: searchQuery) {
            print("[Search] Query changed")
            self.updateTags()
        }
    }
}
