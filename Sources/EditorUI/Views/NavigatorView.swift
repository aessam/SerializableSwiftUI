import SwiftUI

enum NavigatorTab: String, CaseIterable {
    case screens = "Screens"
    case components = "Components"
    case theme = "Theme"
}

struct NavigatorView: View {
    @Bindable var document: EditorDocument
    @Binding var tab: NavigatorTab

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $tab) {
                ForEach(NavigatorTab.allCases, id: \.self) { t in
                    Text(t.rawValue).tag(t)
                }
            }
            .pickerStyle(.segmented)
            .padding(8)

            Divider()

            switch tab {
            case .screens:
                screensList
            case .components:
                componentsList
            case .theme:
                themeSummary
            }
        }
    }

    private var screensList: some View {
        VStack(spacing: 0) {
            List(selection: $document.selectedScreenName) {
                ForEach(Array(document.screens.keys), id: \.self) { name in
                    Label(name, systemImage: "rectangle.portrait")
                        .tag(name)
                }
            }
            .listStyle(.sidebar)

            Divider()

            ScreenCreateBar(document: document)
                .padding(8)
        }
        .onChange(of: document.selectedScreenName) { _, newValue in
            if newValue != nil {
                document.selectedNode = nil
            }
        }
    }

    private var componentsList: some View {
        List {
            ForEach(Array(document.components.keys), id: \.self) { name in
                Label(name, systemImage: "puzzlepiece")
                    .contextMenu {
                        Button("Delete", role: .destructive) {
                            document.components.removeValue(forKey: name)
                        }
                    }
            }
        }
        .listStyle(.sidebar)
    }

    private var themeSummary: some View {
        List {
            Section("Colors") {
                ForEach(Array(document.theme.colors.keys), id: \.self) { name in
                    Label(name, systemImage: "circle.fill")
                }
            }
            Section("Fonts") {
                ForEach(Array(document.theme.fonts.keys), id: \.self) { name in
                    Label(name, systemImage: "textformat")
                }
            }
            Section("Presets") {
                ForEach(Array(document.theme.presets.keys), id: \.self) { name in
                    Label(name, systemImage: "paintbrush")
                }
            }
        }
        .listStyle(.sidebar)
    }
}

private struct ScreenCreateBar: View {
    @Bindable var document: EditorDocument
    @State private var name = ""

    var body: some View {
        HStack {
            TextField("New screen", text: $name)
                .textFieldStyle(.roundedBorder)
            Button {
                createScreen()
            } label: {
                Image(systemName: "plus")
            }
            .disabled(name.isEmpty)
        }
    }

    private func createScreen() {
        let key = name.trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: " ", with: "_")
            .lowercased()
        guard !key.isEmpty, document.screens[key] == nil else { return }
        let root = EditableViewNode(type: "screen", props: ["title": .string(name)])
        document.screens[key] = root
        document.selectedScreenName = key
        self.name = ""
    }
}
