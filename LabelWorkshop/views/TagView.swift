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
