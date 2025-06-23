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

class Tag: Identifiable {
    var library: Library
    var realName: String
    var name: String
    var id: Int
    var colors: TagColor
    var shorthand: String?
    var isCategory: Bool
    var disambiguationId: Int?
    
    static var tagsTable: Table = Table("tags")
    static var idColumn = Expression<Int>("id")
    static var nameColumn = Expression<String>("name")
    static var shorthandColumn = Expression<String?>("shorthand")
    static var tagColorNamespaceColumn = Expression<String?>("color_namespace")
    static var tagColorSlugColumn = Expression<String?>("color_slug")
    static var isCategoryColumn = Expression<Bool>("is_category")
    static var disambiguationIdColumn = Expression<Int?>("disambiguation_id")
    
    static var tagParentsTable: Table = Table("tag_parents")
    // Yes these are meant to be flipped around.
    static var childIdColumn = Expression<Int>("parent_id")
    static var parentIdColumn = Expression<Int>("child_id")
    
    init(
        library: Library,
        name: String,
        id: Int,
        colors: TagColor,
        shorthand: String?,
        isCategory: Bool,
        disambiguationId: Int?
    ){
        self.library = library
        self.realName = name
        self.id = id
        self.colors = colors
        self.shorthand = shorthand
        self.isCategory = isCategory
        self.disambiguationId = disambiguationId
        self.name = realName
        if let disambiguationId = disambiguationId {
            if let tag = Tag.fetch(library: library, id: disambiguationId) {
                self.name = "\(self.realName) (\(tag.name))"
            }
        }
    }
    
    func delete() throws {
        let query = Tag.tagsTable.filter(Tag.idColumn == self.id).delete()
        let query2 = Entry.tagEntriesTable.filter(Entry.idColumn == self.id).delete()
        let query3 = TagAlias.tagAliasesTable.filter(TagAlias.tagIdColumn == self.id).delete()
        let query4 = Tag.tagParentsTable.filter(
            Tag.childIdColumn == self.id || Tag.parentIdColumn == self.id
        ).delete()
        if let db = self.library.db {
            try db.run(query)
            try db.run(query2)
            try db.run(query3)
            try db.run(query4)
        }
    }
    
    func setColumn<T: Value>(column: SQLite.Expression<T>, value: T) throws {
        let query = Tag.tagsTable.filter(Tag.idColumn == self.id)
        if let db = self.library.db {
            try db.run(query.update(column <- value))
        }
    }
    
    func setColumn<T: Value>(column: SQLite.Expression<T?>, value: T?) throws {
        let query = Tag.tagsTable.filter(Tag.idColumn == self.id)
        if let db = self.library.db {
            try db.run(query.update(column <- value))
        }
    }
    
    func setColor(_ color: TagColor) throws {
        try setColumn(column: Tag.tagColorSlugColumn, value: color.slug)
        try setColumn(column: Tag.tagColorNamespaceColumn, value: color.namespace)
        self.colors = color
    }
    
    func getAliases() -> [TagAlias] {
        let query = TagAlias.tagAliasesTable.select(*).filter(TagAlias.tagIdColumn == id)
        var tagAliases: [TagAlias] = []
        do {
            for rawAlias in try self.library.db!.prepare(query) {
                tagAliases.append(
                    TagAlias(
                        id: rawAlias[TagAlias.idColumn],
                        name: rawAlias[TagAlias.nameColumn],
                        tagId: rawAlias[TagAlias.tagIdColumn],
                        tag: self
                    )
                )
            }
        } catch {}
        return tagAliases
    }
    
    func newAlias(_ name: String) {
        let query = TagAlias.tagAliasesTable.insert(
            TagAlias.nameColumn <- name,
            TagAlias.tagIdColumn <- self.id
        )
        do {
            try library.db?.run(query)
        } catch {}
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
    
    func getParentTags() -> [Tag] {
        var parentTags: [Tag] = []
        let query = Tag.tagParentsTable
            .select(*)
            .filter(Tag.childIdColumn == self.id)
        do {
            for raw in try self.library.db!.prepare(query) {
                let tag = Tag.fetch(library: library, id: raw[Tag.parentIdColumn])
                if let tag = tag {
                    parentTags.append(tag)
                }
            }
        } catch {}
        return parentTags
    }
    
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
                let query = Tag.tagParentsTable.insert(
                    Tag.parentIdColumn <- parentTag.id,
                    Tag.childIdColumn <- self.id
                )
                do {
                    try self.library.db?.run(query)
                } catch {}
                continue
            }
        }
        for currentParentTag in currentParentTags {
            // Deleted Parent Tags
            if parentTags.filter({$0.id == currentParentTag.id}).count == 0 {
                let query = Tag.tagParentsTable
                    .filter(Tag.parentIdColumn == currentParentTag.id && Tag.childIdColumn == self.id)
                    .delete()
                do {
                    try self.library.db?.run(query)
                } catch {}
            }
        }
    }
    
    static func fetch(library: Library, id: Int) -> Tag? {
        let query = Tag.tagsTable.select(
            idColumn,
            nameColumn,
            tagColorSlugColumn,
            tagColorNamespaceColumn,
            shorthandColumn,
            isCategoryColumn,
            disambiguationIdColumn
        ).filter(Tag.idColumn == id)
        do {
            for rawTag in try library.db!.prepare(query) {
                let name = rawTag[Tag.nameColumn]
                let namespace = rawTag[Tag.tagColorNamespaceColumn] ?? ""
                let slug = rawTag[Tag.tagColorSlugColumn] ?? ""
                let colors = library.tagColors?.find(namespace: namespace, slug: slug) ?? TagColor.none
                let shorthand = rawTag[Tag.shorthandColumn]
                let isCategory = rawTag[Tag.isCategoryColumn]
                let disambiguationId = rawTag[Tag.disambiguationIdColumn]
                return Tag(
                    library: library,
                    name: name,
                    id: id,
                    colors: colors,
                    shorthand: shorthand,
                    isCategory: isCategory,
                    disambiguationId: disambiguationId
                )
            }
        } catch {print(error)}
        return nil
    }
    
    static func fetchAll(library: Library) -> [Tag] {
        var tags: [Tag] = []
        let query = Tag.tagsTable.select(idColumn)
        do {
            for rawPartialTag in try library.db!.prepare(query) {
                let tag = Tag.fetch(
                    library: library,
                    id: rawPartialTag[Tag.idColumn]
                )
                if let tag = tag { tags.append(tag) }
            }
        } catch {}
        return tags
    }
}
