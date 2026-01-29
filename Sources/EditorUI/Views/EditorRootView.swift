import SwiftUI
import ViewEngine

public struct EditorRootView: View {
    @State var document: EditorDocument
    @State private var navigatorTab: NavigatorTab = .screens

    public init(document: EditorDocument) {
        self._document = State(initialValue: document)
    }

    public var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            NavigatorView(document: document, tab: $navigatorTab)
                .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 300)
        } content: {
            centerPanel
        } detail: {
            detailPanel
                .navigationSplitViewColumnWidth(min: 250, ideal: 300, max: 400)
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 900, minHeight: 600)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    save()
                } label: {
                    Label("Save", systemImage: "square.and.arrow.down")
                }
                .keyboardShortcut("s", modifiers: .command)
            }
            ToolbarItem(placement: .automatic) {
                Button {
                    document.undoManager.undo()
                } label: {
                    Label("Undo", systemImage: "arrow.uturn.backward")
                }
                .keyboardShortcut("z", modifiers: .command)
                .disabled(!document.undoManager.canUndo)
            }
            ToolbarItem(placement: .automatic) {
                Button {
                    document.undoManager.redo()
                } label: {
                    Label("Redo", systemImage: "arrow.uturn.forward")
                }
                .keyboardShortcut("z", modifiers: [.command, .shift])
                .disabled(!document.undoManager.canRedo)
            }
        }
    }

    @ViewBuilder
    private var centerPanel: some View {
        switch navigatorTab {
        case .screens:
            CanvasView(document: document)
        case .components:
            ComponentEditorView(document: document)
        case .theme:
            ThemeEditorView(document: document)
        }
    }

    @ViewBuilder
    private var detailPanel: some View {
        switch navigatorTab {
        case .screens, .components:
            InspectorView(document: document)
        case .theme:
            EmptyView()
        }
    }

    private func save() {
        let manager = ProjectManager(projectURL: document.projectURL)
        do {
            try manager.save(document: document)
        } catch {
            print("Save error: \(error)")
        }
    }
}
