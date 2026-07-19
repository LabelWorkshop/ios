import SwiftUI

struct VisualTagEdit: View {
    @Binding var displayName: String
    @Binding var colors: TagColor
    
    var body: some View {
        TagPreView(
            name: $displayName,
            colors: $colors
        )
        .shadow(color: colors.border, radius: 16)
        .padding(50)
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.tertiarySystemFill))
        .background(
            Image("dots")
                .opacity(0.3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.black, lineWidth: 2)
                .blur(radius: 14)
        )
    }
}
