import SwiftUI

struct CloseButton: View {
    let dismiss: DismissAction
    
    var body: some View {
        if #available(iOS 26.0, *) {
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "xmark")
            }
        } else {
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
}
