import SwiftUI

struct TextBox: View {
    let title: String
    var value: Binding<String>
    
    init(title: String, value: Binding<String>) {
        self.title = title
        self.value = value
    }
    
    var body: some View {
        VStack {
            Text(self.title).font(.caption2).frame(maxWidth: .infinity, alignment: .leading)
            TextField(self.title, text: self.value)
        }
    }
}
