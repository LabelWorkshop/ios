import SwiftUI

func ProminentButtonStyle() -> some PrimitiveButtonStyle {
    if #available(iOS 26.0, *) {
        return GlassProminentButtonStyle()
    } else {
        return DefaultButtonStyle()
    }
}
