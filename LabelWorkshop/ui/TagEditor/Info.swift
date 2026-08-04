import SwiftUI

struct TagEditorInfo: View {
    var tagId: Int
    @Binding var usageCount: Int
    
    var body: some View {
        List {
            HStack {
                Text("ID")
                Text(String(tagId))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            HStack {
                Text("Usage Count")
                Text(String(usageCount))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .listStyle(.plain)
    }
}
