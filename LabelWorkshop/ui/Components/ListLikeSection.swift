import SwiftUI

struct ListLikeSection: View {
    var text: LocalizedStringKey
    var excludeLeadingPadding: Bool
    
    init(_ text: LocalizedStringKey, excludeLeadingPadding: Bool = false) {
        self.text = text
        self.excludeLeadingPadding = excludeLeadingPadding
    }
    
    var body: some View {
        Text(text)
            .font(.headline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, excludeLeadingPadding ? 0 : 16)
    }
}
