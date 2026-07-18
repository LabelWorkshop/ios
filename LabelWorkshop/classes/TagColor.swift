import SQLite
import struct SwiftUI.Color
import class SwiftUI.UIColor
import Foundation

class TagColor: Hashable, Identifiable {
    static func == (lhs: TagColor, rhs: TagColor) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
      hasher.combine(id)
    }
    
    let namespace: String
    let slug: String
    let id: UUID
    var background: Color
    var border: Color
    var text: Color {
        get {
            return self.border == self.background ? TagColor.getTextColor(bg: self.background) : self.border
        }
    }
    var name: String
    private let primaryColor: String?
    private let secondaryColor: String?
    
    static var none: TagColor = TagColor(
        namespace: nil,
        slug: nil,
        primaryColor: nil,
        secondaryColor: nil
    )
    
    
    
    static var defaults = [
        [
            "color_border": false,
            "name": "Red",
            "namespace": "tagstudio-standard",
            "primary": "#E22C3C",
            "secondary": nil,
            "slug": "red"
        ],
        [
            "color_border": false,
            "name": "Red Orange",
            "namespace": "tagstudio-standard",
            "primary": "#E83726",
            "secondary": nil,
            "slug": "red-orange"
        ],
        [
            "color_border": false,
            "name": "Orange",
            "namespace": "tagstudio-standard",
            "primary": "#ED6022",
            "secondary": nil,
            "slug": "orange"
        ],
        [
            "color_border": false,
            "name": "Amber",
            "namespace": "tagstudio-standard",
            "primary": "#FA9A2C",
            "secondary": nil,
            "slug": "amber"
        ],
        [
            "color_border": false,
            "name": "Yellow",
            "namespace": "tagstudio-standard",
            "primary": "#FFD63D",
            "secondary": nil,
            "slug": "yellow"
        ],
        [
            "color_border": false,
            "name": "Lime",
            "namespace": "tagstudio-standard",
            "primary": "#92E649",
            "secondary": nil,
            "slug": "lime"
        ],
        [
            "color_border": false,
            "name": "Green",
            "namespace": "tagstudio-standard",
            "primary": "#45D649",
            "secondary": nil,
            "slug": "green"
        ],
        [
            "color_border": false,
            "name": "Teal",
            "namespace": "tagstudio-standard",
            "primary": "#22D589",
            "secondary": nil,
            "slug": "teal"
        ],
        [
            "color_border": false,
            "name": "Cyan",
            "namespace": "tagstudio-standard",
            "primary": "#3DDBDB",
            "secondary": nil,
            "slug": "cyan"
        ],
        [
            "color_border": false,
            "name": "Blue",
            "namespace": "tagstudio-standard",
            "primary": "#3B87F0",
            "secondary": nil,
            "slug": "blue"
        ],
        [
            "color_border": false,
            "name": "Indigo",
            "namespace": "tagstudio-standard",
            "primary": "#874FF5",
            "secondary": nil,
            "slug": "indigo"
        ],
        [
            "color_border": false,
            "name": "Purple",
            "namespace": "tagstudio-standard",
            "primary": "#BB4FF0",
            "secondary": nil,
            "slug": "purple"
        ],
        [
            "color_border": false,
            "name": "Pink",
            "namespace": "tagstudio-standard",
            "primary": "#FF62AF",
            "secondary": nil,
            "slug": "pink"
        ],
        [
            "color_border": false,
            "name": "Magenta",
            "namespace": "tagstudio-standard",
            "primary": "#F64680",
            "secondary": nil,
            "slug": "magenta"
        ],
        [
            "color_border": false,
            "name": "Coral",
            "namespace": "tagstudio-pastels",
            "primary": "#F2525F",
            "secondary": nil,
            "slug": "coral"
        ],
        [
            "color_border": false,
            "name": "Salmon",
            "namespace": "tagstudio-pastels",
            "primary": "#F66348",
            "secondary": nil,
            "slug": "salmon"
        ],
        [
            "color_border": false,
            "name": "Light Orange",
            "namespace": "tagstudio-pastels",
            "primary": "#FF9450",
            "secondary": nil,
            "slug": "light-orange"
        ],
        [
            "color_border": false,
            "name": "Light Amber",
            "namespace": "tagstudio-pastels",
            "primary": "#FFBA57",
            "secondary": nil,
            "slug": "light-amber"
        ],
        [
            "color_border": false,
            "name": "Light Yellow",
            "namespace": "tagstudio-pastels",
            "primary": "#FFE173",
            "secondary": nil,
            "slug": "light-yellow"
        ],
        [
            "color_border": false,
            "name": "Light Lime",
            "namespace": "tagstudio-pastels",
            "primary": "#C9FF7A",
            "secondary": nil,
            "slug": "light-lime"
        ],
        [
            "color_border": false,
            "name": "Light Green",
            "namespace": "tagstudio-pastels",
            "primary": "#81FF76",
            "secondary": nil,
            "slug": "light-green"
        ],
        [
            "color_border": false,
            "name": "Mint",
            "namespace": "tagstudio-pastels",
            "primary": "#68FFB4",
            "secondary": nil,
            "slug": "mint"
        ],
        [
            "color_border": false,
            "name": "Sky Blue",
            "namespace": "tagstudio-pastels",
            "primary": "#8EFFF4",
            "secondary": nil,
            "slug": "sky-blue"
        ],
        [
            "color_border": false,
            "name": "Light Blue",
            "namespace": "tagstudio-pastels",
            "primary": "#64C6FF",
            "secondary": nil,
            "slug": "light-blue"
        ],
        [
            "color_border": false,
            "name": "Lavender",
            "namespace": "tagstudio-pastels",
            "primary": "#908AF6",
            "secondary": nil,
            "slug": "lavender"
        ],
        [
            "color_border": false,
            "name": "Lilac",
            "namespace": "tagstudio-pastels",
            "primary": "#DF95FF",
            "secondary": nil,
            "slug": "lilac"
        ],
        [
            "color_border": false,
            "name": "Light Pink",
            "namespace": "tagstudio-pastels",
            "primary": "#FF87BA",
            "secondary": nil,
            "slug": "light-pink"
        ],
        [
            "color_border": false,
            "name": "Burgundy",
            "namespace": "tagstudio-shades",
            "primary": "#6E1C24",
            "secondary": nil,
            "slug": "burgundy"
        ],
        [
            "color_border": false,
            "name": "Auburn",
            "namespace": "tagstudio-shades",
            "primary": "#A13220",
            "secondary": nil,
            "slug": "auburn"
        ],
        [
            "color_border": false,
            "name": "Olive",
            "namespace": "tagstudio-shades",
            "primary": "#4C652E",
            "secondary": nil,
            "slug": "olive"
        ],
        [
            "color_border": false,
            "name": "Dark Teal",
            "namespace": "tagstudio-shades",
            "primary": "#1F5E47",
            "secondary": nil,
            "slug": "dark-teal"
        ],
        [
            "color_border": false,
            "name": "Navy",
            "namespace": "tagstudio-shades",
            "primary": "#104B98",
            "secondary": nil,
            "slug": "navy"
        ],
        [
            "color_border": false,
            "name": "Dark Lavender",
            "namespace": "tagstudio-shades",
            "primary": "#3D3B6C",
            "secondary": nil,
            "slug": "dark_lavender"
        ],
        [
            "color_border": false,
            "name": "Berry",
            "namespace": "tagstudio-shades",
            "primary": "#9F2AA7",
            "secondary": nil,
            "slug": "berry"
        ],
        [
            "color_border": false,
            "name": "Black",
            "namespace": "tagstudio-grayscale",
            "primary": "#111018",
            "secondary": nil,
            "slug": "black"
        ],
        [
            "color_border": false,
            "name": "Dark Gray",
            "namespace": "tagstudio-grayscale",
            "primary": "#242424",
            "secondary": nil,
            "slug": "dark-gray"
        ],
        [
            "color_border": false,
            "name": "Gray",
            "namespace": "tagstudio-grayscale",
            "primary": "#53525A",
            "secondary": nil,
            "slug": "gray"
        ],
        [
            "color_border": false,
            "name": "Light Gray",
            "namespace": "tagstudio-grayscale",
            "primary": "#AAAAAA",
            "secondary": nil,
            "slug": "light-gray"
        ],
        [
            "color_border": false,
            "name": "White",
            "namespace": "tagstudio-grayscale",
            "primary": "#F2F1F8",
            "secondary": nil,
            "slug": "white"
        ],
        [
            "color_border": false,
            "name": "Dark Brown",
            "namespace": "tagstudio-earth-tones",
            "primary": "#4C2315",
            "secondary": nil,
            "slug": "dark-brown"
        ],
        [
            "color_border": false,
            "name": "Brown",
            "namespace": "tagstudio-earth-tones",
            "primary": "#823216",
            "secondary": nil,
            "slug": "brown"
        ],
        [
            "color_border": false,
            "name": "Light Brown",
            "namespace": "tagstudio-earth-tones",
            "primary": "#BE5B2D",
            "secondary": nil,
            "slug": "light-brown"
        ],
        [
            "color_border": false,
            "name": "Blonde",
            "namespace": "tagstudio-earth-tones",
            "primary": "#EFC664",
            "secondary": nil,
            "slug": "blonde"
        ],
        [
            "color_border": false,
            "name": "Peach",
            "namespace": "tagstudio-earth-tones",
            "primary": "#F1C69C",
            "secondary": nil,
            "slug": "peach"
        ],
        [
            "color_border": false,
            "name": "Warm Gray",
            "namespace": "tagstudio-earth-tones",
            "primary": "#625550",
            "secondary": nil,
            "slug": "warm-gray"
        ],
        [
            "color_border": false,
            "name": "Cool Gray",
            "namespace": "tagstudio-earth-tones",
            "primary": "#515768",
            "secondary": nil,
            "slug": "cool-gray"
        ],
        [
            "color_border": true,
            "name": "Neon Red",
            "namespace": "tagstudio-neon",
            "primary": "#180607",
            "secondary": "#E22C3C",
            "slug": "neon-red"
        ],
        [
            "color_border": true,
            "name": "Neon Red Orange",
            "namespace": "tagstudio-neon",
            "primary": "#220905",
            "secondary": "#E83726",
            "slug": "neon-red-orange"
        ],
        [
            "color_border": true,
            "name": "Neon Orange",
            "namespace": "tagstudio-neon",
            "primary": "#1F0D05",
            "secondary": "#ED6022",
            "slug": "neon-orange"
        ],
        [
            "color_border": true,
            "name": "Neon Amber",
            "namespace": "tagstudio-neon",
            "primary": "#251507",
            "secondary": "#FA9A2C",
            "slug": "neon-amber"
        ],
        [
            "color_border": true,
            "name": "Neon Yellow",
            "namespace": "tagstudio-neon",
            "primary": "#2B1C0B",
            "secondary": "#FFD63D",
            "slug": "neon-yellow"
        ],
        [
            "color_border": true,
            "name": "Neon Lime",
            "namespace": "tagstudio-neon",
            "primary": "#1B220C",
            "secondary": "#92E649",
            "slug": "neon-lime"
        ],
        [
            "color_border": true,
            "name": "Neon Green",
            "namespace": "tagstudio-neon",
            "primary": "#091610",
            "secondary": "#45D649",
            "slug": "neon-green"
        ],
        [
            "color_border": true,
            "name": "Neon Teal",
            "namespace": "tagstudio-neon",
            "primary": "#09191D",
            "secondary": "#22D589",
            "slug": "neon-teal"
        ],
        [
            "color_border": true,
            "name": "Neon Cyan",
            "namespace": "tagstudio-neon",
            "primary": "#0B191C",
            "secondary": "#3DDBDB",
            "slug": "neon-cyan"
        ],
        [
            "color_border": true,
            "name": "Neon Blue",
            "namespace": "tagstudio-neon",
            "primary": "#09101C",
            "secondary": "#3B87F0",
            "slug": "neon-blue"
        ],
        [
            "color_border": true,
            "name": "Neon Indigo",
            "namespace": "tagstudio-neon",
            "primary": "#150B24",
            "secondary": "#874FF5",
            "slug": "neon-indigo"
        ],
        [
            "color_border": true,
            "name": "Neon Purple",
            "namespace": "tagstudio-neon",
            "primary": "#1E0B26",
            "secondary": "#BB4FF0",
            "slug": "neon-purple"
        ],
        [
            "color_border": true,
            "name": "Neon Pink",
            "namespace": "tagstudio-neon",
            "primary": "#210E15",
            "secondary": "#FF62AF",
            "slug": "neon-pink"
        ],
        [
            "color_border": true,
            "name": "Neon Magenta",
            "namespace": "tagstudio-neon",
            "primary": "#220A13",
            "secondary": "#F64680",
            "slug": "neon-magenta"
        ],
        [
            "color_border": true,
            "name": "Neon White",
            "namespace": "tagstudio-neon",
            "primary": "#131315",
            "secondary": "#F2F1F8",
            "slug": "neon-white"
        ]
    ]
    
    init(
        namespace: String?,
        slug: String?,
        primaryColor: String?,
        secondaryColor: String?
    ){
        self.namespace = namespace ?? "none"
        self.slug = slug ?? "none"
        self.name = NSLocalizedString("colors.\(self.namespace).\(self.slug)", comment: "")
        self.id = UUID()
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
    }
    
    static func getTextColor(bg: Color) -> Color {
        var r, g, b, a: CGFloat
        (r, g, b, a) = (0, 0, 0, 0)
        UIColor(bg).getRed(&r, green: &g, blue: &b, alpha: &a)
        let luminance = 0.2126 * r + 0.7152 * g + 0.0722 * b
        return luminance < 0.6 ? .white : .black
    }
}
