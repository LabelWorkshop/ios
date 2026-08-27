import SQLite
import Observation

struct TagOptions {
    let name: String?
    let shorthand: String?
    let isCategory: Bool?
    let isHidden: Bool?
    let disambiguationId: Int?
    let aliases: [TagAlias]?
    let color: TagColor?
    let parents: [Tag]?
}

@Observable
class LibraryTagManager {
    let library: Library
    var tags: [Tag] = []
    var count: Int {tags.count}
    
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
            try library.withDatabase { db in
                for rawTag in try db.prepare(query) {
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
            try self.library.withDatabase { db in
                for raw in try db.prepare(query) {
                    let tag = self.getById(id: raw[TagParentsTable.parentId])
                    if let tag = tag {
                        parentTags.append(tag)
                    }
                }
            }
        } catch {print(error)}
        return parentTags
    }
    
    func new(_ name: String) -> Tag? {
        do {
            let query = TagsTable.table.insert(
                TagsTable.name <- name,
                TagsTable.isCategory <- false,
                TagsTable.isHidden <- false
            )
            let rowId = try self.library.db.run(query)
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
    
    func setParentTags(tag: Tag, parentTags: [Tag]) throws {
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
                try self.library.db.run(query)
                continue
            }
        }
        for currentParentTag in currentParentTags {
            // Deleted Parent Tags
            if parentTags.filter({$0.id == currentParentTag.id}).count == 0 {
                let query = TagParentsTable.table
                    .filter(TagParentsTable.parentId == currentParentTag.id && TagParentsTable.childId == tag.id)
                    .delete()
                try self.library.db.run(query)
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
        
        try self.library.db.run(query)
        try self.library.db.run(query2)
        try self.library.db.run(query3)
        try self.library.db.run(query4)
        
        self.refresh()
    }
    
    func getUsageCount (of: Tag) -> Int {
        return self.tags.filter({$0.id == of.id}).count
    }
    
    func getAliases(of tag: Tag) throws -> [TagAlias] {
        let query = TagAliasesTable.table.select(*).filter(TagAliasesTable.tagId == tag.id)
        var tagAliases: [TagAlias] = []
        for rawAlias in try self.library.db.prepare(query) {
            tagAliases.append(
                TagAlias(
                    id: rawAlias[TagAliasesTable.id],
                    name: rawAlias[TagAliasesTable.name],
                    tagId: rawAlias[TagAliasesTable.tagId],
                    tag: tag
                )
            )
        }
        return tagAliases
    }
    
    func newAlias(for tag: Tag, _ name: String) throws {
        let query = TagAliasesTable.table.insert(
            TagAliasesTable.name <- name,
            TagAliasesTable.tagId <- tag.id
        )
        try self.library.db.run(query)
    }
    
    func setAliases(for tag: Tag, _ aliases: [TagAlias]) throws {
        let currentAliases = try self.getAliases(of: tag)
        for alias in aliases {
            // New Aliases
            if alias.tag == nil {
                try self.newAlias(for: tag, alias.name)
                continue
            }
            // Updated Aliases
            if var oldAlias = currentAliases.first(where: {$0.id == alias.id}) {
                oldAlias.setName(alias.name)
                continue
            }
        }
        // Deleted Aliases
        for alias in currentAliases {
            aliases.filter({$0.id == alias.id}).count == 0 ? alias.delete() : ()
        }
    }
    
    func setColor(for tag: Tag, _ color: TagColor) throws {
        try setColumn(for: tag, column: TagsTable.colorSlug, value: color.slug)
        try setColumn(for: tag, column: TagsTable.colorNamespace, value: color.namespace)
        tag.colors = color
    }
    
    func setColumn<T: Value>(
        for tag: Tag,
        column: SQLite.Expression<T>,
        value: T
    ) throws {
        let query = TagsTable.table.filter(TagsTable.id == tag.id)
        try self.library.db.run(query.update(column <- value))
    }
    
    func setColumn<T: Value>(
        for tag: Tag,
        column: SQLite.Expression<T?>,
        value: T
    ) throws {
        let query = TagsTable.table.filter(TagsTable.id == tag.id)
        try self.library.db.run(query.update(column <- value))
    }
    
    func updateTag(_ tag: Tag, options: TagOptions) throws {
        try self.library.db.transaction {
            if let name = options.name {
                try setColumn(for: tag, column: TagsTable.name, value: name)
                tag.name = name
            }
            if let shorthand = options.shorthand {
                try setColumn(for: tag, column: TagsTable.shorthand, value: shorthand)
                tag.shorthand = shorthand
            }
            if let isCategory = options.isCategory {
                try setColumn(for: tag, column: TagsTable.isCategory, value: isCategory)
                tag.isCategory = isCategory
            }
            if let isHidden = options.isHidden {
                try setColumn(for: tag, column: TagsTable.isHidden, value: isHidden)
                tag.isHidden = isHidden
            }
            if let disambiguationId = options.disambiguationId {
                try setColumn(for: tag, column: TagsTable.disambiguationId, value: disambiguationId)
                tag.disambiguationId = disambiguationId
            }
            if let parents = options.parents {
                try setParentTags(tag: tag, parentTags: parents)
            }
            if let aliases = options.aliases {
                try self.setAliases(for: tag, aliases)
            }
            if let color = options.color {
                try self.setColor(for: tag, color)
            }
        }
    }
}
