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
    
    func toHex() -> String? {
        let uiColor = UIColor(self)
        guard let components = uiColor.cgColor.components, components.count >= 3 else {
            return nil
        }

        let r = components[0]
        let g = components[1]
        let b = components[2]

        return String(
            format: "#%02lX%02lX%02lX",
            lroundf(Float(r * 255)),
            lroundf(Float(g * 255)),
            lroundf(Float(b * 255))
        )
    }
}

@Observable
class Tag: Identifiable, Equatable, Hashable {
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
        var computedName = name
        if let disambiguationId = disambiguationId, let tag = Tag.fetch(library: library, id: disambiguationId) {
            computedName = "\(name) (\(tag.name))"
        }
        self.library = library
        self.realName = name
        self.id = id
        self.colors = colors
        self.shorthand = shorthand
        self.isCategory = isCategory
        self.disambiguationId = disambiguationId
        self.isHidden = isHidden
        self.name = computedName
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
        self.name = name
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
    
    static func getAllCategories(library: Library, tags: [Tag]) -> [TagCategorySet] {
        var categories: [TagCategorySet] = []
        for tag in tags {
            let tagCategories = library.tags.getCategories(of: tag)
            for category in tagCategories {
                let existingCategory = categories.filter{ $0.parent.id == category.id }
                if let firstExistingCategory = existingCategory.first {
                    firstExistingCategory.children.append(tag)
                } else {
                    categories.append(TagCategorySet(parent: category, children: [tag]))
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
            for rawTag in try library.db.prepare(query) {
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
    
    static func == (lhs: Tag, rhs: Tag) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

