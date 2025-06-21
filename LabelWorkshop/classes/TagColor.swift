import SQLite
import struct SwiftUI.Color
import class SwiftUI.UIColor
import Foundation

class TagColor {
    let namespace: String
    let slug: String
    var background: Color
    var border: Color
    var text: Color
    private let primaryColor: String?
    private let secondaryColor: String?
    
    static var none: TagColor = TagColor(
        namespace: "",
        slug: "",
        primaryColor: nil,
        secondaryColor: nil
    )
    
    static var tagColorsTable: Table = Table("tag_colors")
    static var slugColumn = Expression<String>("slug")
    static var namespaceColumn = Expression<String>("namespace")
    static var primaryColumn = Expression<String>("primary")
    static var secondaryColumn = Expression<String?>("secondary")
    static var colorBorderColumn = Expression<Bool>("color_border")
    
    init(namespace: String, slug: String, primaryColor: String?, secondaryColor: String?){
        self.namespace = namespace
        self.slug = slug
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
        if let primaryColor = primaryColor {
            self.background = Color(hex: primaryColor)
        } else {
            self.background = Color(UIColor.tertiarySystemGroupedBackground)
        }
        if let secondaryColor = secondaryColor {
            self.border = Color(hex: secondaryColor)
        } else {
            self.border = self.background
        }
        self.text = self.border == self.background ? TagColor.getTextColor(bg: self.background) : self.border
    }
    
    static func getTextColor(bg: Color) -> Color {
        var r, g, b, a: CGFloat
        (r, g, b, a) = (0, 0, 0, 0)
        UIColor(bg).getRed(&r, green: &g, blue: &b, alpha: &a)
        let luminance = 0.2126 * r + 0.7152 * g + 0.0722 * b
        return luminance < 0.6 ? .white : .black
    }
}
