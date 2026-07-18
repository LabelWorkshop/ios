import struct SwiftUI.Color
import UIKit
import Foundation
import SQLite
import struct SQLite.Expression

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

class Tag: Identifiable, Equatable {
    var library: Library?
    var realName: String
    var name: String
    var id: Int
    var colors: TagColor
    var shorthand: String?
    var isCategory: Bool
    var disambiguationId: Int?
    var isHidden: Bool?
    
    init(
        library: Library,
        name: String,
        id: Int,
        colors: TagColor,
        shorthand: String?,
        isCategory: Bool,
        disambiguationId: Int?,
        isHidden: Bool?
    ){
        self.library = library
        self.realName = name
        self.id = id
        self.colors = colors
        self.shorthand = shorthand
        self.isCategory = isCategory
        self.disambiguationId = disambiguationId
        self.isHidden = isHidden
        self.name = realName
        if let disambiguationId = disambiguationId {
            if let tag = Tag.fetch(library: library, id: disambiguationId) {
                self.name = "\(self.realName) (\(tag.name))"
            }
        }
    }
    
    init(
        name: String,
        id: Int,
        colors: TagColor,
        shorthand: String?,
        isCategory: Bool,
        disambiguationId: Int?,
        isHidden: Bool?
    ){
        self.realName = name
        self.id = id
        self.colors = colors
        self.shorthand = shorthand
        self.isCategory = isCategory
        self.disambiguationId = disambiguationId
        self.isHidden = isHidden
        self.name = realName
    }
    
    @available(*, deprecated)
    func delete() throws {
        let query = TagsTable.table.filter(TagsTable.id == self.id).delete()
        let query2 = TagEntriesTable.table.filter(TagEntriesTable.id == self.id).delete()
        let query3 = TagAliasesTable.table.filter(TagAliasesTable.tagId == self.id).delete()
        let query4 = TagParentsTable.table.filter(
            TagParentsTable.childId == self.id || TagParentsTable.parentId == self.id
        ).delete()
        if let db = self.library!.db {
            try db.run(query)
            try db.run(query2)
            try db.run(query3)
            try db.run(query4)
        }
    }
    
    func setColumn<T: Value>(column: SQLite.Expression<T>, value: T) throws {
        let query = TagsTable.table.filter(TagsTable.id == self.id)
        if let db = self.library!.db {
            try db.run(query.update(column <- value))
        }
    }
    
    func setColumn<T: Value>(column: SQLite.Expression<T?>, value: T?) throws {
        let query = TagsTable.table.filter(TagsTable.id == self.id)
        if let db = self.library!.db {
            try db.run(query.update(column <- value))
        }
    }
    
    func setColor(_ color: TagColor) throws {
        try setColumn(column: TagsTable.colorSlug, value: color.slug)
        try setColumn(column: TagsTable.colorNamespace, value: color.namespace)
        self.colors = color
    }
    
    func getAliases() -> [TagAlias] {
        let query = TagAliasesTable.table.select(*).filter(TagAliasesTable.tagId == id)
        var tagAliases: [TagAlias] = []
        do {
            for rawAlias in try self.library!.db!.prepare(query) {
                tagAliases.append(
                    TagAlias(
                        id: rawAlias[TagAliasesTable.id],
                        name: rawAlias[TagAliasesTable.name],
                        tagId: rawAlias[TagAliasesTable.tagId],
                        tag: self
                    )
                )
            }
        } catch {print(error)}
        return tagAliases
    }
    
    func newAlias(_ name: String) {
        let query = TagAliasesTable.table.insert(
            TagAliasesTable.name <- name,
            TagAliasesTable.tagId <- self.id
        )
        do {
            try library!.db?.run(query)
        } catch {print(error)}
    }
    
    func setAliases(_ aliases: [TagAlias]) {
        let currentAliases = self.getAliases()
        for alias in aliases {
            // New Aliases
            if alias.tag == nil {
                self.newAlias(alias.name)
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
    
    @available(*, deprecated)
    func getParentTags() -> [Tag] {
        var parentTags: [Tag] = []
        let query = TagParentsTable.table
            .select(*)
            .filter(TagParentsTable.childId == self.id)
        do {
            for raw in try self.library!.db!.prepare(query) {
                let tag = Tag.fetch(library: library!, id: raw[TagParentsTable.parentId])
                if let tag = tag {
                    parentTags.append(tag)
                }
            }
        } catch {print(error)}
        return parentTags
    }
    
    @available(*, deprecated)
    func setParentTags(_ parentTags: [Tag]) {
        let currentParentTags = self.getParentTags()
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
                    TagParentsTable.childId <- self.id
                )
                do {
                    try self.library!.db?.run(query)
                } catch {print(error)}
                continue
            }
        }
        for currentParentTag in currentParentTags {
            // Deleted Parent Tags
            if parentTags.filter({$0.id == currentParentTag.id}).count == 0 {
                let query = TagParentsTable.table
                    .filter(TagParentsTable.parentId == currentParentTag.id && TagParentsTable.childId == self.id)
                    .delete()
                do {
                    try self.library!.db?.run(query)
                } catch {print(error)}
            }
        }
    }
    
    @available(*, deprecated)
    func getCategories() -> [Tag] {
        var tags: [Tag] = []
        let parentTags: [Tag] = self.getParentTags()
        for parentTag in parentTags {
            if parentTag.isCategory {
                tags.append(parentTag)
            }
        }
        return tags
    }
    
    @available(*, deprecated)
    static func getNoCategoryTags(_ tags: [Tag]) -> [Tag] {
        var noCategoryTags: [Tag] = []
        for tag in tags {
            if tag.getCategories().isEmpty {
                noCategoryTags.append(tag)
            }
        }
        return noCategoryTags
    }
    
    static func getNoCategoryTags(library: Library, tags: [Tag]) -> [Tag] {
        var noCategoryTags: [Tag] = []
        for tag in tags {
            if library.tags.getCategories(of: tag).isEmpty {
                noCategoryTags.append(tag)
            }
        }
        return noCategoryTags
    }
    
    @available(*, deprecated)
    static func getAllCategories(_ tags: [Tag]) -> [TagCategorySet] {
        var categories: [TagCategorySet] = []
        for tag in tags {
            let tagCategories = tag.getCategories()
            for category in tagCategories {
                let existingCategory = categories.filter{ $0.parent.id == category.id }
                if (existingCategory.isEmpty) {
                    categories.append(TagCategorySet(parent: category, children: [tag]))
                } else {
                    existingCategory.first!.children.append(tag)
                }
            }
        }
        return categories
    }
    
    static func getAllCategories(library: Library, tags: [Tag]) -> [TagCategorySet] {
        var categories: [TagCategorySet] = []
        for tag in tags {
            let tagCategories = library.tags.getCategories(of: tag)
            for category in tagCategories {
                let existingCategory = categories.filter{ $0.parent.id == category.id }
                if (existingCategory.isEmpty) {
                    categories.append(TagCategorySet(parent: category, children: [tag]))
                } else {
                    existingCategory.first!.children.append(tag)
                }
            }
        }
        return categories
    }
    
    @available(*, deprecated)
    static func fetch(library: Library, id: Int) -> Tag? {
        let query = TagsTable.table.select(
            TagsTable.id,
            TagsTable.name,
            TagsTable.colorSlug,
            TagsTable.colorNamespace,
            TagsTable.shorthand,
            TagsTable.isCategory,
            TagsTable.disambiguationId,
            TagsTable.isHidden
        ).filter(TagsTable.id == id)
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
                return Tag(
                    library: library,
                    name: name,
                    id: id,
                    colors: colors,
                    shorthand: shorthand,
                    isCategory: isCategory,
                    disambiguationId: disambiguationId,
                    isHidden: isHidden
                )
            }
        } catch {print(error)}
        return nil
    }
    
    @available(*, deprecated)
    static func fetchAll(library: Library) -> [Tag] {
        var tags: [Tag] = []
        let query = TagsTable.table.select(TagsTable.id)
        do {
            for rawPartialTag in try library.db!.prepare(query) {
                let tag = Tag.fetch(
                    library: library,
                    id: rawPartialTag[TagsTable.id]
                )
                if let tag = tag { tags.append(tag) }
            }
        } catch {print(error)}
        return tags
    }
    
    static func == (lhs: Tag, rhs: Tag) -> Bool {
        return lhs.id == rhs.id
    }
    
    /*static func defaults() -> [Tag] {
        let metaTag = Tag(name: "Meta Tags", id: 2, colors: TagColor.none, shorthand: nil, isCategory: true, disambiguationId: nil, isHidden: nil)
        metaTag.setAliases(TagAlias(id: 2, name: "Meta"))
    }*/
}

