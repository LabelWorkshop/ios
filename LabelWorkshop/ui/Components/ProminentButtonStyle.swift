import SwiftUI

@available(*, deprecated, renamed: "GlassButtonStyle")
func ProminentButtonStyle(
    fallback: some PrimitiveButtonStyle = .automatic
) -> some PrimitiveButtonStyle {
    if #available(iOS 26.0, *) {
        return GlassProminentButtonStyle()
    } else {
        return fallback
    }
}



struct CompatibleGlassButtonStyle<Fallback: PrimitiveButtonStyle>: ViewModifier {
    var prominent: Bool = false
    var fallback: Fallback
    
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            if prominent {
                content.buttonStyle(.glassProminent)
            } else {
                content.buttonStyle(.glass)
            }
        } else {
            content.buttonStyle(fallback)
        }
    }

}

extension View {
    func compatibleGlassButtonStyle<Fallback: PrimitiveButtonStyle>(
        prominent: Bool = false,
        fallback: Fallback = .automatic
    ) -> some View {
        modifier(CompatibleGlassButtonStyle(prominent: prominent, fallback: fallback))
    }
}
