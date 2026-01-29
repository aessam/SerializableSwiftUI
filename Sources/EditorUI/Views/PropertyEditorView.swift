import SwiftUI
import ViewEngine

/// Type-specific property editor that replaces the generic text-field approach.
struct PropertyEditorView: View {
    @Bindable var document: EditorDocument
    let node: EditableViewNode

    private var typeInfo: NodeTypeInfo? {
        NodeTypeInfo.byType[node.type]
    }

    private var screenNames: [String] {
        Array(document.screens.keys)
    }

    var body: some View {
        Section("Properties") {
            if let typeInfo {
                ForEach(typeInfo.validProps, id: \.key) { def in
                    editorFor(def)
                }

                // Extra props not defined in type info
                let definedKeys = Set(typeInfo.validProps.map(\.key))
                let extras = node.props.keys.filter { !definedKeys.contains($0) }.sorted()
                ForEach(extras, id: \.self) { key in
                    genericField(key: key)
                }
            } else {
                ForEach(Array(node.props.keys.sorted()), id: \.self) { key in
                    genericField(key: key)
                }
            }

            addPropButton
        }
    }

    @ViewBuilder
    private func editorFor(_ def: PropDef) -> some View {
        switch def.editor {
        case .text:
            HStack {
                Text(def.label)
                    .frame(width: 100, alignment: .leading)
                TextField(def.label, text: stringBinding(def.key))
            }

        case .number:
            HStack {
                Text(def.label)
                    .frame(width: 100, alignment: .leading)
                TextField(def.label, text: numberStringBinding(def.key))
                    .frame(width: 80)
            }

        case .toggle:
            Toggle(def.label, isOn: Binding(
                get: { node.props[def.key]?.boolValue ?? false },
                set: { document.setProperty(on: node, key: def.key, value: .bool($0)) }
            ))

        case .dropdown(let options):
            HStack {
                Text(def.label)
                    .frame(width: 100, alignment: .leading)
                Picker("", selection: Binding(
                    get: { node.props[def.key]?.stringValue ?? options.first ?? "" },
                    set: { document.setProperty(on: node, key: def.key, value: .string($0)) }
                )) {
                    ForEach(options, id: \.self) { opt in
                        Text(opt).tag(opt)
                    }
                }
            }

        case .binding:
            BindingPickerView(
                label: def.label,
                value: stringBinding(def.key),
                screenName: document.selectedScreenName ?? ""
            )

        case .action:
            ActionBuilderView(
                label: def.label,
                action: Binding(
                    get: { node.props[def.key] },
                    set: { document.setProperty(on: node, key: def.key, value: $0) }
                ),
                availableScreens: screenNames
            )

        case .node:
            HStack {
                Text(def.label)
                    .frame(width: 100, alignment: .leading)
                Text("(embedded node)")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }

        case .nodeArray:
            HStack {
                Text(def.label)
                    .frame(width: 100, alignment: .leading)
                Text("(node array)")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
        }
    }

    @ViewBuilder
    private func genericField(key: String) -> some View {
        HStack {
            Text(key)
                .frame(width: 100, alignment: .leading)
            TextField("value", text: Binding(
                get: { propString(node.props[key]) },
                set: { document.setProperty(on: node, key: key, value: parseValue($0)) }
            ))
            Button {
                document.setProperty(on: node, key: key, value: nil)
            } label: {
                Image(systemName: "xmark.circle")
            }
            .buttonStyle(.borderless)
        }
    }

    private var addPropButton: some View {
        HStack {
            Spacer()
            Menu {
                Button("Custom Key...") {
                    document.setProperty(on: node, key: "newProp", value: .string(""))
                }
                if let typeInfo {
                    let existing = Set(node.props.keys)
                    let missing = typeInfo.validProps.filter { !existing.contains($0.key) }
                    if !missing.isEmpty {
                        Divider()
                        ForEach(missing, id: \.key) { def in
                            Button(def.label) {
                                document.setProperty(on: node, key: def.key, value: .string(""))
                            }
                        }
                    }
                }
            } label: {
                Label("Add Property", systemImage: "plus.circle")
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
    }

    // MARK: - Bindings

    private func stringBinding(_ key: String) -> Binding<String> {
        Binding(
            get: { node.props[key]?.stringValue ?? "" },
            set: { document.setProperty(on: node, key: key, value: $0.isEmpty ? nil : .string($0)) }
        )
    }

    private func numberStringBinding(_ key: String) -> Binding<String> {
        Binding(
            get: { propString(node.props[key]) },
            set: { document.setProperty(on: node, key: key, value: parseValue($0)) }
        )
    }

    private func propString(_ value: AnyCodableValue?) -> String {
        guard let value else { return "" }
        switch value {
        case .string(let s): return s
        case .int(let i): return "\(i)"
        case .double(let d): return "\(d)"
        case .bool(let b): return b ? "true" : "false"
        default: return "\(value)"
        }
    }

    private func parseValue(_ str: String) -> AnyCodableValue? {
        if str.isEmpty { return nil }
        if str == "true" { return .bool(true) }
        if str == "false" { return .bool(false) }
        if let i = Int(str) { return .int(i) }
        if let d = Double(str) { return .double(d) }
        return .string(str)
    }
}
