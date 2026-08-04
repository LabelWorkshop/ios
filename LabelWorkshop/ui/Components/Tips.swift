import TipKit

struct TagFilterTip: Tip {
    var title: Text {
        Text("Filter by Tag")
    }
    
    var message: Text? {
        Text("Tap the tag icon to filter through entries with the selected tags.")
    }
    
    var image: Image? {
        Image(systemName: "line.3.horizontal.decrease")
    }
}
