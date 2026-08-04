import SwiftUI

struct NewVersionTip: View {
    var icon: Image
    var title: LocalizedStringKey
    var description: LocalizedStringKey
    var iconTint: Color?
    
    var body: some View {
        HStack {
            if #available(iOS 26.0, *) {
                icon.font(.largeTitle)
                    .foregroundStyle(iconTint ?? .primary)
                    .frame(width: 40)
                    .symbolColorRenderingMode(.gradient)
            } else {
                icon.font(.largeTitle)
                    .foregroundStyle(iconTint ?? .primary)
                    .frame(width: 40)
            }
            VStack {
                Text(title)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .bold()
                Text(description)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
