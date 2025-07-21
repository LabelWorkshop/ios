import SwiftUI
import Flow

extension Bundle {
    public var icon: UIImage? {
        if let icons = infoDictionary?["CFBundleIcons"] as? [String: Any],
            let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
            let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
            let lastIcon = iconFiles.last {
            return UIImage(named: lastIcon)
        }
        return nil
    }
}

struct AboutView: View {
    let version: String = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack {
                    if let icon = Bundle.main.icon {
                        Image(uiImage: icon)
                            .resizable()
                            .frame(width: 150, height: 150)
                            .cornerRadius(40)
                            .padding(10)
                    }
                    Text("LabelWorkshop").font(.title).bold(true)
                    Text("version \(version)").font(.title3)
                    Text("© purpletennisball 2025").font(.body)
                    HFlow {
                        Link("about.link.github",
                             destination: URL(string: "https://github.com/LabelWorkshop/ios")!)
                        Link("about.link.contributors",
                             destination: URL(string: "https://github.com/LabelWorkshop/ios/graphs/contributors")!)
                    }.padding(.top, 5)
                }.frame(maxWidth: .infinity, alignment: .center)
            }
            .navigationTitle("about")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing){
                    CloseButton(dismiss: dismiss)
                }
            }
        }
    }
}
