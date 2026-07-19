import SwiftUI

struct TagDetailsView: View {
    let tag: Tag
    let library: Library
    
    @State private var name: String
    @State private var shorthand: String
    @State private var colors: TagColor
    @State private var isCategory: Bool
    @State private var isHidden: Bool
    @State var aliases: [TagAlias]
    @State var parentTags: [Tag]
    @State var disambiguationId: Int?
    @State var disambiguationName: String?
    @State var displayName: String = ""
    @State private var showTagParentSelector: Bool = false
    @State private var showTagColorSelector: Bool = false
    @State private var tagDeleteConfirmation: Bool = false
    @Environment(\.dismiss) private var dismiss
    @State private var tagColors: [TagColor]
    @State var tagDetailsTab = 0
    @State var usageCount: Int
    
    init(library: Library, tag: Tag) {
        self.tag = tag
        self.library = library
        self.name = tag.realName
        self.shorthand = tag.shorthand ?? ""
        self.colors = tag.colors
        self.isCategory = tag.isCategory
        self.isHidden = tag.isHidden ?? false
        self.tagColors = tag.library?.tagColors?.colors ?? []
        self.aliases = tag.getAliases()
        self.parentTags = self.library.tags.getParentTags(of: tag)
        self.usageCount = self.library.tags.getUsageCount(of: tag)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 8) {
                if #available(iOS 26.0, *) {
                    VisualTagEdit(displayName: $displayName, colors: $colors)
                        .clipShape(.rect(cornerRadius: 16))
                } else {
                    VisualTagEdit(displayName: $displayName, colors: $colors)
                        .clipShape(.rect(cornerRadius: 8))
                }
                Picker("", selection: $tagDetailsTab) {
                    Text("General").tag(0)
                    Text("Parents").tag(1)
                    Text("Aliases").tag(2)
                    Text("Info").tag(3)
                }.pickerStyle(SegmentedPickerStyle())
                if tagDetailsTab == 0 {
                    TagEditorGeneral(name: $name, shorthand: $shorthand, colors: $colors, tagColors: $tagColors, isCategory: $isCategory, isHidden: $isHidden)
                } else if tagDetailsTab == 1 {
                    TagEditorParents(parentTags: $parentTags, disambiguationId: $disambiguationId, tagId: tag.id, tags: self.library.tags.all)
                } else if tagDetailsTab == 2 {
                    TagEditorAlias(aliases: $aliases, tagId: tag.id)
                } else if tagDetailsTab == 3 {
                    TagEditorInfo(tagId: tag.id, usageCount: $usageCount)
                }
            }
            .padding(16)
            .padding(.bottom, 80)
            .navigationTitle(tag.name)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading){
                    CloseButton(dismiss: dismiss)
                }
                ToolbarItem(placement: .navigationBarTrailing){
                    if #available(iOS 26.0, *) {
                        Button(role: .confirm, action: confirmEdits) {
                            Image(systemName: "checkmark")
                        }
                    } else {
                        Button(action: confirmEdits) {
                            Image(systemName: "checkmark")
                        }.tint(.blue)
                    }
                }
                ToolbarItem(placement: .bottomBar){
                    Button(role: .destructive, action: {
                        tagDeleteConfirmation = true
                    }) {
                        Image(systemName: "trash")
                    }.tint(.red)
                    .confirmationDialog(
                        Text("This tag and all references of it will be deleted."),
                        isPresented: $tagDeleteConfirmation,
                        titleVisibility: .visible
                    ) {
                        Button(role: .destructive, action: {
                            do {
                                try self.library.tags.delete(tag)
                                tagDeleteConfirmation = false
                                dismiss()
                            } catch {print(error)}
                        }) {
                            Text("Delete Tag")
                        }
                    }
                }
            }
            .onAppear {
                self.parentTags = self.library.tags.getParentTags(of: tag)
                self.disambiguationId = tag.disambiguationId
                updateName()
            }
            .onChange(of: disambiguationId) {
                self.disambiguationName = nil
                if let disambiguationId = disambiguationId {
                    let tag: Tag? = self.library.tags.getById(id: disambiguationId)
                    if let tag = tag {
                        self.disambiguationName = tag.name
                    }
                }
                updateName()
            }
            .onChange(of: name) {
                updateName()
            }
        }
    }
    
    func updateName() {
        var suffix = ""
        if let disambiguationName = disambiguationName {
            suffix = " (\(disambiguationName))"
        }
        self.displayName = "\(name)\(suffix)"
    }
    
    func confirmEdits() {
        do {
            try tag.setColumn(column: TagsTable.name, value: self.name)
            try tag.setColumn(column: TagsTable.shorthand, value: self.shorthand)
            try tag.setColumn(column: TagsTable.isCategory, value: self.isCategory)
            try tag.setColumn(column: TagsTable.isHidden, value: self.isHidden)
            try tag.setColumn(column: TagsTable.disambiguationId, value: self.disambiguationId)
            tag.setAliases(self.aliases)
            try tag.setColor(self.colors)
            self.library.tags.setParentTags(tag: self.tag, parentTags: self.parentTags)
        } catch {print(error)}
        dismiss()
    }
}
