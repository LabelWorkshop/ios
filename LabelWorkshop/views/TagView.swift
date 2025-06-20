import SwiftUI



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
            .foregroundStyle(tag.textColor)
            .font(.body)
            .padding(8)
            .background(tag.color)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(tag.borderColor, lineWidth: 8)
            )
            .cornerRadius(8)
    }
}
