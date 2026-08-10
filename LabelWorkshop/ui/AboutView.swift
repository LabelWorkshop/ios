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

struct AboutLink: Identifiable {
    let id: UUID = UUID()
    let name: LocalizedStringKey
    let url: URL?
}

struct AboutView: View {
    let version: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    @Environment(\.dismiss) private var dismiss
    
    let links: [AboutLink] = [
        AboutLink(
            name: "GitHub Repository",
            url: URL(string: "https://github.com/LabelWorkshop/ios")
        ),
        AboutLink(
            name: "Contributors",
            url: URL(string: "https://github.com/LabelWorkshop/ios/graphs/contributors")
        )
    ]
    
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
                    Text("© purpletennisball 2026").font(.body)
                    HFlow {
                        ForEach(links) { link in
                            if let url = link.url {
                                Link(
                                    link.name,
                                    destination: url
                                )
                            }
                        }
                    }.padding(.top, 5)
                }.frame(maxWidth: .infinity, alignment: .center)
            }
            .navigationTitle("About")
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                ToolbarItem(placement: .primaryAction){
                    CloseButton(dismiss: dismiss)
                }
            }.preferredColorScheme(.dark)
        }
        .background {
            VStack {
                Image("LabelSky")
                    .resizable()
                    .frame(maxWidth: .infinity)
                    .opacity(0.5)
                    .scaledToFit()
                Spacer()
            }
            .background(.black)
        }
    }
}
