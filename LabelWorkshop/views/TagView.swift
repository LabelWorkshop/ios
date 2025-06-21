import SwiftUI

struct TagPreView: View {
    @Binding public var name: String
    @Binding public var color: Color
    @Binding public var borderColor: Color
    @Binding public var textColor: Color
    
    var body: some View {
        Text(name)
            .foregroundStyle(textColor)
            .font(.body)
            .padding(8)
            .background(color)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: 8)
            )
            .cornerRadius(8)
    }
}

struct TagView: View {
    let tag: Tag
    let fullWidth: Bool
    
    init(tag: Tag, fullWidth: Bool = false) {
        self.tag = tag
        self.fullWidth = fullWidth
    }
    
    var body: some View {
        Text(tag.name)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .foregroundStyle(tag.colors.text)
            .font(.body)
            .padding(8)
            .background(tag.colors.background)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(tag.colors.border, lineWidth: 8)
            )
            .cornerRadius(8)
    }
}
