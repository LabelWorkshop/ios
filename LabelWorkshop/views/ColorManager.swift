import SwiftUI
import Flow

struct ColorManager: View {
    let tagColors: TagColorManager
    
    @Environment(\.dismiss) private var dismiss
    
    init(tagColors: TagColorManager) {
        self.tagColors = tagColors
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                ForEach(tagColors.namespaces) { namespace in
                    Text(namespace.namespace)
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                        .foregroundStyle(.secondary)
                    HFlow {
                        ForEach(namespace.colors) { color in
                            TagPreView(name: .constant(color.name), colors: .constant(color))
                        }
                    }.frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal)
            }
            .navigationTitle("Color Manager")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    CloseButton(dismiss: dismiss)
                }
            }
        }
    }
}
