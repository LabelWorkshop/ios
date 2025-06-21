import SwiftUI



struct TagView: View {
    let tag: Tag
    
    init(tag: Tag) {
        self.tag = tag
    }
    
    var body: some View {
        Text(tag.name)
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
