import SwiftUI
import ViewEngine

struct TreeOutlineView: View {
    @Bindable var document: EditorDocument
    let root: EditableViewNode

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Tree")
                    .font(.headline)
                Spacer()
                addNodeMenu(parent: root)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)

            Divider()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    TreeNodeRow(node: root, depth: 0, document: document)
                }
                .padding(.vertical, 4)
            }
        }
    }

    private func addNodeMenu(parent: EditableViewNode) -> some View {
        Menu {
            ForEach(NodeCategory.allCases, id: \.rawValue) { category in
                let types = NodeTypeInfo.all.filter { $0.category == category }
                Section(category.rawValue) {
                    ForEach(types, id: \.type) { info in
                        Button {
                            let newNode = EditableViewNode(type: info.type)
                            document.addChild(to: parent, node: newNode, at: parent.children.count)
                            document.selectedNode = newNode
                        } label: {
                            Label(info.type, systemImage: info.icon)
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "plus.circle")
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }
}

private struct TreeNodeRow: View {
    let node: EditableViewNode
    let depth: Int
    @Bindable var document: EditorDocument

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            rowContent

            ForEach(node.children) { child in
                TreeNodeRow(node: child, depth: depth + 1, document: document)
            }
        }
    }

    private var rowContent: some View {
        let isSelected = document.selectedNode?.id == node.id

        return HStack(spacing: 4) {
            Image(systemName: NodeTypeInfo.icon(for: node.type))
                .foregroundStyle(.secondary)
                .frame(width: 16)
            Text(node.displayLabel)
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer()
        }
        .padding(.leading, CGFloat(depth * 16) + 8)
        .padding(.vertical, 3)
        .padding(.trailing, 8)
        .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            document.selectedNode = node
        }
        .contextMenu {
            contextMenuContent
        }
    }

    @ViewBuilder
    private var contextMenuContent: some View {
        Menu("Add Child") {
            ForEach(NodeCategory.allCases, id: \.rawValue) { category in
                let types = NodeTypeInfo.all.filter { $0.category == category }
                Section(category.rawValue) {
                    ForEach(types, id: \.type) { info in
                        Button {
                            let newNode = EditableViewNode(type: info.type)
                            document.addChild(to: node, node: newNode, at: node.children.count)
                            document.selectedNode = newNode
                        } label: {
                            Label(info.type, systemImage: info.icon)
                        }
                    }
                }
            }
        }

        if let parent = node.parent {
            Button("Delete", role: .destructive) {
                if let idx = parent.children.firstIndex(where: { $0.id == node.id }) {
                    document.removeChild(from: parent, at: idx)
                }
            }
        }

        Button("Duplicate") {
            guard let parent = node.parent,
                  let idx = parent.children.firstIndex(where: { $0.id == node.id }) else { return }
            let copy = node.duplicate()
            document.addChild(to: parent, node: copy, at: idx + 1)
        }
    }
}
