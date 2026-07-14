import SwiftUI

extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, modifier: (Self) -> Content) -> some View {
        if condition {
            modifier(self)
        } else {
            self
        }
    }
}

struct TagSearch: View {
    let selectAction: (_: Tag) -> Void
    let multiSelect: Bool
    let library: Library?
    let closeButton: Bool
    var tags: [Tag]
    @State var visableTags: [Tag]
    @State var searchQuery: String = ""
    @State var selected: [Tag]
    
    @Environment(\.dismiss) private var dismiss
    
    init(tags: [Tag], selectAction: @escaping (_: Tag) -> Void, multiSelect: Bool, selected: [Tag], closeButton: Bool) {
        self.tags = tags
        self.visableTags = tags
        self.multiSelect = multiSelect
        self.selectAction = selectAction
        self.selected = selected
        self.library = nil
        self.closeButton = closeButton
        self.updateTags()
    }
    
    init(library: Library, tags: [Tag], selectAction: @escaping (_: Tag) -> Void, multiSelect: Bool, selected: [Tag], closeButton: Bool) {
        self.tags = tags
        self.visableTags = tags
        self.multiSelect = multiSelect
        self.selectAction = selectAction
        self.selected = selected
        self.library = library
        self.closeButton = closeButton
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
        let scroller = ScrollView {
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
        .searchable(text: $searchQuery)
        .onChange(of: searchQuery) {
            print("[Search] Query changed")
            self.updateTags()
        }
        .if(multiSelect || closeButton) { view in
            view.toolbar {
                if closeButton {
                    ToolbarItem(placement: .navigationBarLeading) {
                        CloseButton(dismiss: dismiss)
                    }
                }
                if multiSelect {
                    ToolbarItem(placement: .bottomBar){
                        Button(action: {
                            for selection in self.selected {
                                self.selectAction(selection)
                                self.selected.removeAll()
                            }
                        }) {
                            Text("Deselect All")
                        }
                    }
                }
            }
        }
        if (multiSelect || closeButton) {
            NavigationView {
                scroller
            }
        } else {
            scroller
        }
    }
}
