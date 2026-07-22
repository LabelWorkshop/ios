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
                HFlow {
                    ForEach(tagColors.colors) { color in
                        TagPreView(name: .constant(color.name), colors: .constant(color))
                    }
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
