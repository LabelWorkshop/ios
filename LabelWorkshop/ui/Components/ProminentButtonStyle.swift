import SwiftUI

func ProminentButtonStyle(
    fallback: some PrimitiveButtonStyle = .automatic
) -> some PrimitiveButtonStyle {
    if #available(iOS 26.0, *) {
        return GlassProminentButtonStyle()
    } else {
        return fallback
    }
}
