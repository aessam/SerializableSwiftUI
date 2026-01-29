import SwiftUI
import ViewEngine

struct InspectorView: View {
    @Bindable var document: EditorDocument

    var body: some View {
        if let node = document.selectedNode {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    nodeTypeSection(node)
                    identitySection(node)
                    PropertyEditorView(document: document, node: node)
                    StyleEditorView(document: document, node: node)
                    conditionSection(node)
                }
                .padding()
            }
        } else {
            ContentUnavailableView("No Selection", systemImage: "sidebar.right",
                                   description: Text("Select a node in the tree"))
        }
    }

    @ViewBuilder
    private func nodeTypeSection(_ node: EditableViewNode) -> some View {
        Section {
            Picker("Type", selection: Binding(
                get: { node.type },
                set: { document.setType(on: node, type: $0) }
            )) {
                ForEach(NodeTypeInfo.allTypeNames, id: \.self) { t in
                    Text(t).tag(t)
                }
            }
        } header: {
            Label("Node Type", systemImage: NodeTypeInfo.icon(for: node.type))
                .font(.headline)
        }
    }

    @ViewBuilder
    private func identitySection(_ node: EditableViewNode) -> some View {
        Section("Identity") {
            TextField("Node ID", text: Binding(
                get: { node.nodeId ?? "" },
                set: { document.setNodeId(on: node, nodeId: $0.isEmpty ? nil : $0) }
            ))
        }
    }

    @ViewBuilder
    private func conditionSection(_ node: EditableViewNode) -> some View {
        Section("Condition") {
            TextField("e.g. $.items | !empty", text: Binding(
                get: { node.condition ?? "" },
                set: { document.setCondition(on: node, condition: $0.isEmpty ? nil : $0) }
            ))
        }
    }
}
