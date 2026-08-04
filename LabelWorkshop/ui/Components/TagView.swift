import SwiftUI

struct TagPreView: View {
    @Binding public var name: String
    @Binding public var colors: TagColor
    public var fullWidth: Bool = false
    
    var body: some View {
        Text(name)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .foregroundStyle(colors.text)
            .font(.body)
            .padding(8)
            .background(colors.background)
            .overlay(
                Capsule()
                    .stroke(colors.border, lineWidth: 2)
            )
            .containerShape(Capsule())
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
                Capsule()
                    .stroke(tag.colors.border, lineWidth: 2)
            )
            .containerShape(Capsule())
    }
}
