import SwiftUI

struct CloseButton: View {
    let dismiss: DismissAction
    
    var body: some View {
        Button(action: {
            dismiss()
        }) {
            Image(systemName: "xmark.circle.fill")
        }
        .font(.system(size: 24))
        .tint(.secondary)
        .symbolRenderingMode(.hierarchical)
    }
}
