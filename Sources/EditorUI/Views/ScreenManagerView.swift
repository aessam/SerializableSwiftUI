import SwiftUI
import ViewEngine

struct ScreenManagerView: View {
    @Bindable var document: EditorDocument

    @State private var newScreenName = ""
    @State private var showDeleteConfirm = false
    @State private var screenToDelete: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Screens")
                    .font(.headline)
                Spacer()
            }
            .padding(8)

            Divider()

            List {
                ForEach(Array(document.screens.keys), id: \.self) { name in
                    HStack {
                        Image(systemName: "rectangle.portrait")
                        Text(name)
                        Spacer()
                        if let root = document.screens[name] {
                            Text(root.type)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .contextMenu {
                        Button("Rename...") {
                            // Rename handled inline
                        }
                        Button("Duplicate") {
                            duplicateScreen(name)
                        }
                        Button("Delete", role: .destructive) {
                            screenToDelete = name
                            showDeleteConfirm = true
                        }
                    }
                }
            }

            Divider()

            HStack {
                TextField("New screen name", text: $newScreenName)
                Button("Create") {
                    createScreen()
                }
                .disabled(newScreenName.isEmpty)
            }
            .padding(8)

            // App root section
            if let appRoot = document.appRoot {
                Divider()
                VStack(alignment: .leading, spacing: 4) {
                    Text("App Root")
                        .font(.headline)
                    Text("Type: \(appRoot.type)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if appRoot.type == "tab_view" {
                        tabEditor(appRoot)
                    }
                }
                .padding(8)
            }
        }
        .alert("Delete Screen?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                if let name = screenToDelete {
                    deleteScreen(name)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove \"\(screenToDelete ?? "")\" and its JSON file.")
        }
    }

    // MARK: - Actions

    private func createScreen() {
        let name = newScreenName.trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: " ", with: "_")
            .lowercased()
        guard !name.isEmpty, document.screens[name] == nil else { return }

        let root = EditableViewNode(
            type: "screen",
            props: ["title": .string(newScreenName)]
        )
        let body = EditableViewNode(type: "vstack", props: ["alignment": .string("leading")])
        document.addChild(to: root, node: body, at: 0)
        document.screens[name] = root
        document.selectedScreenName = name
        newScreenName = ""
    }

    private func deleteScreen(_ name: String) {
        document.screens.removeValue(forKey: name)
        if document.selectedScreenName == name {
            document.selectedScreenName = document.screens.keys.first
        }
        // Also delete the file
        let url = document.projectURL.appendingPathComponent("\(name).json")
        try? FileManager.default.removeItem(at: url)
    }

    private func duplicateScreen(_ name: String) {
        guard let original = document.screens[name] else { return }
        let newName = "\(name)_copy"
        document.screens[newName] = original.duplicate()
        document.selectedScreenName = newName
    }

    @ViewBuilder
    private func tabEditor(_ appRoot: EditableViewNode) -> some View {
        let tabsValue = appRoot.props["tabs"]
        let tabs = tabsValue?.arrayValue ?? []

        ForEach(Array(tabs.enumerated()), id: \.offset) { idx, tab in
            let dict = tab.dictionaryValue ?? [:]
            HStack {
                Image(systemName: dict["icon"]?.stringValue ?? "questionmark")
                Text(dict["title"]?.stringValue ?? "")
                Text("→ \(dict["screen"]?.stringValue ?? "")")
                    .foregroundStyle(.secondary)
            }
            .font(.caption)
        }

        Button("Add Tab") {
            var tabs = tabsValue?.arrayValue ?? []
            let screenNames = Array(document.screens.keys)
            let screen = screenNames.first ?? "new_screen"
            tabs.append(.dictionary([
                "title": .string("New"),
                "icon": .string("star"),
                "screen": .string(screen)
            ]))
            document.setProperty(on: appRoot, key: "tabs", value: .array(tabs))
        }
        .font(.caption)
    }
}
