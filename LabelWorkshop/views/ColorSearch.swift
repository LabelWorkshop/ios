import SwiftUI
import Flow

extension ColorSearch where NamespaceActions == EmptyView {
    init(
        tagColors: TagColorManager,
        colorSelectAction: @escaping (TagColor) -> Void,
        dismissOnSelection: Bool = false
    ) {
        self.init(tagColors: tagColors, colorSelectAction: colorSelectAction, namespaceActions:  { _ in
            EmptyView()
        }, dismissOnSelection: dismissOnSelection)
    }
}

struct ColorSearch<NamespaceActions: View>: View {
    let tagColors: TagColorManager
    
    @Environment(\.dismiss) private var dismiss
    
    let colorSelectAction: (_: TagColor) -> Void
    let dismissOnSelection: Bool
    @ViewBuilder var namespaceActions: (_ namespace: TagColorNamespace) -> NamespaceActions
    
    @State var searchText: String = ""
    
    init(
        tagColors: TagColorManager,
        colorSelectAction: @escaping (_: TagColor) -> Void,
        @ViewBuilder namespaceActions: @escaping (_ namespace: TagColorNamespace) -> NamespaceActions,
        dismissOnSelection: Bool = false
    ) {
        self.tagColors = tagColors
        self.colorSelectAction = colorSelectAction
        self.namespaceActions = namespaceActions
        self.dismissOnSelection = dismissOnSelection
    }
    
    private func getFilteredColors(in namespace: TagColorNamespace) -> [TagColor] {
        if searchText.isEmpty {
            return namespace.colors
        }
        return namespace.colors.filter{$0.name.localizedCaseInsensitiveContains(searchText)}
    }
    
    private func isSearchEmpty() -> Bool {
        for namespace in tagColors.namespaces {
            if !getFilteredColors(in: namespace).isEmpty {
                return false
            }
        }
        return true
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if isSearchEmpty() {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    ScrollView {
                        ForEach(tagColors.namespaces) { namespace in
                            let colors = getFilteredColors(in: namespace)
                            if colors.isEmpty && !searchText.isEmpty {
                                EmptyView()
                            } else {
                                HStack {
                                    Text(namespace.displayName)
                                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                                        .foregroundStyle(.secondary)
                                    namespaceActions(namespace)
                                }
                                HFlow {
                                    if namespace.colors.isEmpty {
                                        Text("No Colors")
                                            .padding()
                                            .frame(maxWidth: .infinity, alignment: .center)
                                            .foregroundStyle(.secondary)
                                            .font(.title3)
                                    } else {
                                        ForEach(colors) { color in
                                            Button {
                                                self.colorSelectAction(color)
                                                if dismissOnSelection {
                                                    dismiss()
                                                }
                                            } label: {
                                                TagPreView(name: .constant(color.name), colors: .constant(color))
                                            }
                                        }
                                    }
                                }.frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
            .searchPresentationToolbarBehavior(.avoidHidingContent)
        }
    }
}
