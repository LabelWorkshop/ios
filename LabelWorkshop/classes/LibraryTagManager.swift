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
}

