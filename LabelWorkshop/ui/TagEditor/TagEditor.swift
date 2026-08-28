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
    @State private var tagColors: TagColorManager
    @State var tagDetailsTab = 0
    @State var usageCount: Int
    @State var editSaveFailed: Bool = false
    
    init(library: Library, tag: Tag) {
        self.tag = tag
        self.library = library
        self.name = tag.realName
        self.shorthand = tag.shorthand ?? ""
        self.colors = tag.colors
        self.isCategory = tag.isCategory
        self.isHidden = tag.isHidden ?? false
        self.tagColors = library.tagColors
        do {
            self.aliases = try library.tags.getAliases(of: tag)
        } catch {
            self.aliases = []
        }
        self.parentTags = self.library.tags.getParentTags(of: tag)
        self.usageCount = self.library.tags.getUsageCount(of: tag)
    }
    
    var body: some View {
        NavigationStack {
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
                    TagEditorParents(parentTags: $parentTags, disambiguationId: $disambiguationId, tagId: tag.id, tags: self.library.tags.tags)
                } else if tagDetailsTab == 2 {
                    TagEditorAlias(aliases: $aliases, tagId: tag.id)
                } else if tagDetailsTab == 3 {
                    TagEditorInfo(tagId: tag.id, usageCount: $usageCount)
                }
            }
            .padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
            .navigationTitle(tag.name)
            .toolbar {
                if UIDevice.current.userInterfaceIdiom == .phone {
                    ToolbarItem(placement: .navigationBarLeading){
                        CloseButton(dismiss: dismiss)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing){
                    Button {
                        do {
                            try confirmEdits()
                        } catch {
                            editSaveFailed = true
                        }
                    } label: {
                        Label("Save", systemImage: "checkmark")
                    }
                    .buttonStyle(ProminentButtonStyle())
                }
                if tag.isDeletable {
                    ToolbarItem(placement: .bottomBar){
                        Button(role: .destructive, action: {
                            tagDeleteConfirmation = true
                        }) {
                            Label("Delete Tag", systemImage: "trash")
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
            .alert("Save Failed", isPresented: $editSaveFailed) {} message: {
                Text("Failed to save changes.")
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
    
    func confirmEdits() throws {
        try library.tags.updateTag(
            tag, options: .init(
                name: self.name,
                shorthand: self.shorthand,
                isCategory: self.isCategory,
                isHidden: self.isHidden,
                disambiguationId: self.disambiguationId,
                aliases: self.aliases,
                color: self.colors,
                parents: self.parentTags
            )
        )
        dismiss()
    }
}
