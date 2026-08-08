import SwiftUI

func LWConcentricRectangle() -> some Shape {
    if #available(iOS 26.0, *) {
        return ConcentricRectangle(corners: .concentric, isUniform: true)
    }
    return RoundedRectangle(cornerRadius: 16)
}
