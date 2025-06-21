import SwiftUI
import Foundation

func getAccessibilityColor(bg: Color) -> Color {
    var r, g, b, a: CGFloat
    (r, g, b, a) = (0, 0, 0, 0)
    UIColor(bg).getRed(&r, green: &g, blue: &b, alpha: &a)
    let luminance = 0.2126 * r + 0.7152 * g + 0.0722 * b
    return luminance < 0.6 ? .white : .black
}
