import SQLite

class LibraryTagManager {
    let library: Library
    private var tags: [Tag] = []
    var all: [Tag] {
        get {
            return self.tags
        }
    }
    
    init(library: Library) {
        self.library = library
        self.refresh()
    }
    
    func refresh() {
        var newTags: [Tag] = []
        let query = TagsTable.table.select(
            TagsTable.id,
            TagsTable.name,
            TagsTable.shorthand,
            TagsTable.colorNamespace,
            TagsTable.colorSlug,
            TagsTable.isCategory,
            TagsTable.disambiguationId,
            TagsTable.isHidden
        )
        do {
            for rawTag in try library.db!.prepare(query) {
                let name = rawTag[TagsTable.name]
                let namespace = rawTag[TagsTable.colorNamespace] ?? ""
                let slug = rawTag[TagsTable.colorSlug] ?? ""
                let colors = library.tagColors?.find(namespace: namespace, slug: slug) ?? TagColor.none
                let shorthand = rawTag[TagsTable.shorthand]
                let isCategory = rawTag[TagsTable.isCategory]
                let disambiguationId = rawTag[TagsTable.disambiguationId]
                let isHidden = rawTag[TagsTable.isHidden]
                let id = rawTag[TagsTable.id]
                let tag = Tag(
                    library: self.library,
                    name: name,
                    id: id,
                    colors: colors,
                    shorthand: shorthand,
                    isCategory: isCategory,
                    disambiguationId: disambiguationId,
                    isHidden: isHidden
                )
                newTags.append(tag)
            }
        } catch {print(error)}
        self.tags = newTags
    }
    
    func getById(id: Int) -> Tag? {
        return self.tags.filter { tag in
            tag.id == id
        }.first
    }
    
    func getParentTags(of: Tag) -> [Tag] {
        var parentTags: [Tag] = []
        let query = TagParentsTable.table
            .select(TagParentsTable.childId, TagParentsTable.parentId)
            .filter(TagParentsTable.childId == of.id)
        do {
            for raw in try self.library.db!.prepare(query) {
                let tag = self.getById(id: raw[TagParentsTable.parentId])
                if let tag = tag {
                    parentTags.append(tag)
                }
            }
        } catch {print(error)}
        return parentTags
    }
    
    func new(_ name: String) -> Tag? {
        let sequenceQuery = SequenceTable.table.filter(SequenceTable.name == "tags")
        do {
            if let raw = try self.library.db?.pluck(sequenceQuery) {
                let sequence = raw[SequenceTable.sequence]
                if let sequence = sequence {
                    let query = TagsTable.table.insert(
                        TagsTable.name <- name,
                        TagsTable.isCategory <- false,
                        TagsTable.isHidden <- false
                    )
                    try self.library.db?.run(query)
                    return Tag (
                        library: self.library,
                        name: name,
                        id: sequence,
                        colors: TagColor.none,
                        shorthand: nil,
                        isCategory: false,
                        disambiguationId: nil,
                        isHidden: false
                    )
                }
            }
        } catch {print(error)}
        return nil
        self.refresh()
    }
    
    func setParentTags(tag: Tag, parentTags: [Tag]) {
        let currentParentTags = self.getParentTags(of: tag)
        for parentTag in parentTags {
            // New Parent Tags
            var isNew = true
            for currentParentTag in currentParentTags {
                if currentParentTag.id == parentTag.id {
                    isNew = false
                }
            }
            if isNew {
                let query = TagParentsTable.table.insert(
                    TagParentsTable.parentId <- parentTag.id,
                    TagParentsTable.childId <- tag.id
                )
                do {
                    try self.library.db?.run(query)
                } catch {print(error)}
                continue
            }
        }
        for currentParentTag in currentParentTags {
            // Deleted Parent Tags
            if parentTags.filter({$0.id == currentParentTag.id}).count == 0 {
                let query = TagParentsTable.table
                    .filter(TagParentsTable.parentId == currentParentTag.id && TagParentsTable.childId == tag.id)
                    .delete()
                do {
                    try self.library.db?.run(query)
                } catch {print(error)}
            }
        }
    }
    
    func getCategories(of: Tag) -> [Tag] {
        var tags: [Tag] = []
        let parentTags: [Tag] = self.getParentTags(of: of)
        for parentTag in parentTags {
            if parentTag.isCategory {
                tags.append(parentTag)
            }
        }
        return tags
    }
    
    func delete(_ tag: Tag) throws {
        let query = TagsTable.table.filter(TagsTable.id == tag.id).delete()
        let query2 = TagEntriesTable.table.filter(TagEntriesTable.entryId == tag.id).delete()
        let query3 = TagAliasesTable.table.filter(TagAliasesTable.tagId == tag.id).delete()
        let query4 = TagParentsTable.table.filter(
            TagParentsTable.childId == tag.id || TagParentsTable.parentId == tag.id
        ).delete()
        if let db = self.library.db {
            try db.run(query)
            try db.run(query2)
            try db.run(query3)
            try db.run(query4)
        }
        self.refresh()
    }
}

