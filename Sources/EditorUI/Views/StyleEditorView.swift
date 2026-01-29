import SwiftUI
import ViewEngine

struct StyleEditorView: View {
    @Bindable var document: EditorDocument
    let node: EditableViewNode

    private var presetNames: [String] {
        Array(document.theme.presets.keys)
    }

    var body: some View {
        Section("Style") {
            // Preset picker
            Picker("Preset", selection: Binding(
                get: { node.style ?? "" },
                set: { document.setStyle(on: node, style: $0.isEmpty ? nil : $0) }
            )) {
                Text("(none)").tag("")
                ForEach(presetNames, id: \.self) { name in
                    Text(name).tag(name)
                }
            }
        }

        Section("Inline Style") {
            // Font
            inlineStylePicker(key: "font", label: "Font",
                              options: Array(document.theme.fonts.keys))

            // Foreground color
            inlineStylePicker(key: "foregroundColor", label: "Color",
                              options: Array(document.theme.colors.keys))

            // Background color
            inlineStylePicker(key: "backgroundColor", label: "Background",
                              options: Array(document.theme.colors.keys))

            // Padding
            numberField(key: "padding", label: "Padding")

            // Corner radius
            numberField(key: "cornerRadius", label: "Radius")

            // Width/height
            dimensionField(key: "width", label: "Width")
            dimensionField(key: "height", label: "Height")
            dimensionField(key: "maxWidth", label: "Max Width")
            dimensionField(key: "maxHeight", label: "Max Height")

            // Opacity
            numberField(key: "opacity", label: "Opacity")
        }
    }

    @ViewBuilder
    private func inlineStylePicker(key: String, label: String, options: [String]) -> some View {
        HStack {
            Text(label)
                .frame(width: 80, alignment: .leading)
            Picker("", selection: Binding(
                get: { node.inlineStyle[key]?.stringValue ?? "" },
                set: {
                    if $0.isEmpty {
                        document.setInlineStyle(on: node, key: key, value: nil)
                    } else {
                        document.setInlineStyle(on: node, key: key, value: .string($0))
                    }
                }
            )) {
                Text("(none)").tag("")
                ForEach(options, id: \.self) { opt in
                    Text(opt).tag(opt)
                }
            }
        }
    }

    @ViewBuilder
    private func numberField(key: String, label: String) -> some View {
        HStack {
            Text(label)
                .frame(width: 80, alignment: .leading)
            TextField("", text: Binding(
                get: {
                    guard let v = node.inlineStyle[key] else { return "" }
                    if let d = v.doubleValue { return d.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(d))" : "\(d)" }
                    return v.stringValue ?? ""
                },
                set: {
                    if $0.isEmpty {
                        document.setInlineStyle(on: node, key: key, value: nil)
                    } else if let d = Double($0) {
                        document.setInlineStyle(on: node, key: key, value: d == Double(Int(d)) ? .int(Int(d)) : .double(d))
                    } else {
                        document.setInlineStyle(on: node, key: key, value: .string($0))
                    }
                }
            ))
            .frame(width: 60)

            if node.inlineStyle[key] != nil {
                Button {
                    document.setInlineStyle(on: node, key: key, value: nil)
                } label: {
                    Image(systemName: "xmark.circle")
                }
                .buttonStyle(.borderless)
            }
        }
    }

    @ViewBuilder
    private func dimensionField(key: String, label: String) -> some View {
        HStack {
            Text(label)
                .frame(width: 80, alignment: .leading)
            TextField("", text: Binding(
                get: {
                    guard let v = node.inlineStyle[key] else { return "" }
                    if let s = v.stringValue, s == "infinity" { return "∞" }
                    if let d = v.doubleValue { return d.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(d))" : "\(d)" }
                    return v.stringValue ?? ""
                },
                set: {
                    if $0.isEmpty {
                        document.setInlineStyle(on: node, key: key, value: nil)
                    } else if $0 == "∞" || $0.lowercased() == "infinity" {
                        document.setInlineStyle(on: node, key: key, value: .string("infinity"))
                    } else if let d = Double($0) {
                        document.setInlineStyle(on: node, key: key, value: d == Double(Int(d)) ? .int(Int(d)) : .double(d))
                    }
                }
            ))
            .frame(width: 60)

            if node.inlineStyle[key] != nil {
                Button {
                    document.setInlineStyle(on: node, key: key, value: nil)
                } label: {
                    Image(systemName: "xmark.circle")
                }
                .buttonStyle(.borderless)
            }
        }
    }
}
