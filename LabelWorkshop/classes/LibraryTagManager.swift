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
        let query = Tag.tagsTable.select(
            Tag.idColumn,
            Tag.nameColumn,
            Tag.shorthandColumn,
            Tag.tagColorNamespaceColumn,
            Tag.tagColorSlugColumn,
            Tag.isCategoryColumn,
            Tag.disambiguationIdColumn,
            Tag.isHiddenColumn
        )
        do {
            for rawTag in try library.db!.prepare(query) {
                let name = rawTag[Tag.nameColumn]
                let namespace = rawTag[Tag.tagColorNamespaceColumn] ?? ""
                let slug = rawTag[Tag.tagColorSlugColumn] ?? ""
                let colors = library.tagColors?.find(namespace: namespace, slug: slug) ?? TagColor.none
                let shorthand = rawTag[Tag.shorthandColumn]
                let isCategory = rawTag[Tag.isCategoryColumn]
                let disambiguationId = rawTag[Tag.disambiguationIdColumn]
                let isHidden = rawTag[Tag.isHiddenColumn]
                let id = rawTag[Tag.idColumn]
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
        let query = Tag.tagParentsTable
            .select(Tag.childIdColumn, Tag.parentIdColumn)
            .filter(Tag.childIdColumn == of.id)
        do {
            for raw in try self.library.db!.prepare(query) {
                let tag = self.getById(id: raw[Tag.parentIdColumn])
                if let tag = tag {
                    parentTags.append(tag)
                }
            }
        } catch {print(error)}
        return parentTags
    }
    
    func new(_ name: String) -> Tag? {
        do {
            let query = Tag.tagsTable.insert(
                Tag.nameColumn <- name,
                Tag.isCategoryColumn <- false,
                Tag.isHiddenColumn <- false
            )
            guard let rowId = try self.library.db?.run(query) else {return nil}
            self.refresh()
            return Tag (
                library: self.library,
                name: name,
                id: Int(rowId),
                colors: TagColor.none,
                shorthand: nil,
                isCategory: false,
                disambiguationId: nil,
                isHidden: false
            )
        } catch {
            print(error)
            return nil
        }
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
                let query = Tag.tagParentsTable.insert(
                    Tag.parentIdColumn <- parentTag.id,
                    Tag.childIdColumn <- tag.id
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
                let query = Tag.tagParentsTable
                    .filter(Tag.parentIdColumn == currentParentTag.id && Tag.childIdColumn == tag.id)
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
        let query = Tag.tagsTable.filter(Tag.idColumn == tag.id).delete()
        let query2 = Entry.tagEntriesTable.filter(Entry.idColumn == tag.id).delete()
        let query3 = TagAlias.tagAliasesTable.filter(TagAlias.tagIdColumn == tag.id).delete()
        let query4 = Tag.tagParentsTable.filter(
            Tag.childIdColumn == tag.id || Tag.parentIdColumn == tag.id
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

