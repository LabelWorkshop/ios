import struct SwiftUI.Color
import UIKit
import Foundation
import SQLite

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

class Tag {
    var library: Library
    var name: String
    var id: Int
    var color: Color
    var borderColor: Color
    var textColor: Color
    
    static var tagsTable: Table = Table("tags")
    static var idColumn = Expression<Int>("id")
    static var nameColumn = Expression<String>("name")
    static var tagColorNamespaceColumn = Expression<String?>("color_namespace")
    static var tagColorSlugColumn = Expression<String?>("color_slug")
    
    static var tagColorsTable: Table = Table("tag_colors")
    static var slugColumn = Expression<String>("slug")
    static var namespaceColumn = Expression<String>("namespace")
    static var primaryColumn = Expression<String>("primary")
    static var secondaryColumn = Expression<String?>("secondary")
    static var colorBorderColumn = Expression<Bool>("color_border")
    
    init(library: Library, name: String, id: Int, color: Color? = nil, borderColor: Color? = nil){
        self.library = library
        self.name = name
        self.id = id
        self.color = color ?? Color(UIColor.tertiarySystemFill)
        self.borderColor = borderColor ?? self.color
        var r, g, b, a: CGFloat
        (r, g, b, a) = (0, 0, 0, 0)
        UIColor(self.color).getRed(&r, green: &g, blue: &b, alpha: &a)
        let luminance = 0.2126 * r + 0.7152 * g + 0.0722 * b
        self.textColor = luminance < 0.6 ? .white : .black
        if borderColor != nil { self.textColor = self.borderColor }
    }
    
    func delete() throws {
        let query = Tag.tagsTable.filter(Tag.idColumn == self.id)
        if let db = self.library.db {
            try db.run(query.delete())
        }
    }
    
    func setName(name: String) throws {
        let query = Tag.tagsTable.filter(Tag.idColumn == self.id)
        if let db = self.library.db {
            try db.run(query.update(Tag.nameColumn <- name))
        }
    }
    
    static func fetch(library: Library, id: Int) -> Tag? {
        let query = Tag.tagsTable.select(
            idColumn,
            nameColumn,
            tagColorSlugColumn,
            tagColorNamespaceColumn
        ).filter(Tag.idColumn == id)
        do {
            for rawTag in try library.db!.prepare(query) {
                let name = rawTag[Tag.nameColumn]
                let namespace = rawTag[Tag.tagColorNamespaceColumn] ?? ""
                let slug = rawTag[Tag.tagColorSlugColumn] ?? ""
                let colorQuery = Tag.tagColorsTable.select(
                    primaryColumn,
                    secondaryColumn,
                    slugColumn,
                    namespaceColumn
                )
                .filter(Tag.slugColumn == slug)
                .filter(Tag.namespaceColumn == namespace)
                var color: Color?
                var borderColor: Color?
                for raw in try library.db!.prepare(colorQuery) {
                    color = Color.init(hex: raw[Tag.primaryColumn])
                    if let secondary = raw[Tag.secondaryColumn] {
                        borderColor = Color.init(hex: secondary)
                    }
                }
                return Tag(
                    library: library,
                    name: name,
                    id: id,
                    color: color,
                    borderColor: borderColor
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
