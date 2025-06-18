import SwiftUI



struct TagView: View {
    let tag: Tag
    
    init(tag: Tag) {
        self.tag = tag
    }
    
    var body: some View {
        Text(tag.name)
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
