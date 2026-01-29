import SwiftUI
import ViewEngine

struct ThemeEditorView: View {
    @Bindable var document: EditorDocument

    @State private var newColorName = ""
    @State private var newFontName = ""
    @State private var newPresetName = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                colorsSection
                fontsSection
                presetsSection
            }
            .padding()
        }
    }

    // MARK: - Colors

    @ViewBuilder
    private var colorsSection: some View {
        Section {
            ForEach(Array(document.theme.colors.keys), id: \.self) { name in
                colorRow(name: name)
            }

            HStack {
                TextField("New color name", text: $newColorName)
                    .frame(width: 150)
                Button("Add") {
                    guard !newColorName.isEmpty else { return }
                    document.theme.colors[newColorName] = .string("#007AFF")
                    newColorName = ""
                }
            }
        } header: {
            Label("Colors", systemImage: "paintpalette")
                .font(.headline)
        }
    }

    @ViewBuilder
    private func colorRow(name: String) -> some View {
        let value = document.theme.colors[name]
        HStack {
            Text(name)
                .frame(width: 120, alignment: .leading)

            if let str = value?.stringValue {
                // Fixed color
                TextField("hex", text: Binding(
                    get: { str },
                    set: { document.theme.colors[name] = .string($0) }
                ))
                .frame(width: 100)
                Circle()
                    .fill(Color(hex: str))
                    .frame(width: 20, height: 20)
            } else if let dict = value?.dictionaryValue {
                // Adaptive
                let light = dict["light"]?.stringValue ?? ""
                let dark = dict["dark"]?.stringValue ?? ""
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text("L:")
                        TextField("light", text: Binding(
                            get: { light },
                            set: {
                                var d = dict
                                d["light"] = .string($0)
                                document.theme.colors[name] = .dictionary(d)
                            }
                        ))
                        .frame(width: 80)
                        Circle().fill(Color(hex: light)).frame(width: 16, height: 16)
                    }
                    HStack {
                        Text("D:")
                        TextField("dark", text: Binding(
                            get: { dark },
                            set: {
                                var d = dict
                                d["dark"] = .string($0)
                                document.theme.colors[name] = .dictionary(d)
                            }
                        ))
                        .frame(width: 80)
                        Circle().fill(Color(hex: dark)).frame(width: 16, height: 16)
                    }
                }
            }

            Spacer()

            Button {
                document.theme.colors.removeValue(forKey: name)
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
        }
    }

    // MARK: - Fonts

    @ViewBuilder
    private var fontsSection: some View {
        Section {
            ForEach(Array(document.theme.fonts.keys), id: \.self) { name in
                fontRow(name: name)
            }

            HStack {
                TextField("New font name", text: $newFontName)
                    .frame(width: 150)
                Button("Add") {
                    guard !newFontName.isEmpty else { return }
                    document.theme.fonts[newFontName] = .dictionary([
                        "size": .int(17),
                        "weight": .string("regular")
                    ])
                    newFontName = ""
                }
            }
        } header: {
            Label("Fonts", systemImage: "textformat.size")
                .font(.headline)
        }
    }

    @ViewBuilder
    private func fontRow(name: String) -> some View {
        let dict = document.theme.fonts[name]?.dictionaryValue ?? [:]
        HStack {
            Text(name)
                .frame(width: 100, alignment: .leading)

            Text("Size:")
            TextField("", text: Binding(
                get: { dict["size"]?.stringValue ?? "17" },
                set: {
                    var d = dict
                    if let v = Double($0) { d["size"] = .double(v) } else { d["size"] = .string($0) }
                    document.theme.fonts[name] = .dictionary(d)
                }
            ))
            .frame(width: 40)

            Text("Weight:")
            Picker("", selection: Binding(
                get: { dict["weight"]?.stringValue ?? "regular" },
                set: {
                    var d = dict
                    d["weight"] = .string($0)
                    document.theme.fonts[name] = .dictionary(d)
                }
            )) {
                ForEach(["ultraLight", "thin", "light", "regular", "medium", "semibold", "bold", "heavy", "black"], id: \.self) {
                    Text($0).tag($0)
                }
            }
            .frame(width: 100)

            Spacer()

            Button {
                document.theme.fonts.removeValue(forKey: name)
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
        }
    }

    // MARK: - Presets

    @ViewBuilder
    private var presetsSection: some View {
        Section {
            ForEach(Array(document.theme.presets.keys), id: \.self) { name in
                presetRow(name: name)
            }

            HStack {
                TextField("New preset name", text: $newPresetName)
                    .frame(width: 150)
                Button("Add") {
                    guard !newPresetName.isEmpty else { return }
                    document.theme.presets[newPresetName] = [:]
                    newPresetName = ""
                }
            }
        } header: {
            Label("Presets", systemImage: "paintbrush")
                .font(.headline)
        }
    }

    @ViewBuilder
    private func presetRow(name: String) -> some View {
        let props = document.theme.presets[name] ?? [:]
        DisclosureGroup(name) {
            ForEach(Array(props.keys.sorted()), id: \.self) { key in
                HStack {
                    Text(key)
                        .frame(width: 100, alignment: .leading)
                    TextField("value", text: Binding(
                        get: { props[key]?.stringValue ?? "\(props[key] ?? .null)" },
                        set: {
                            var p = props
                            if $0.isEmpty {
                                p.removeValue(forKey: key)
                            } else if let i = Int($0) {
                                p[key] = .int(i)
                            } else if let d = Double($0) {
                                p[key] = .double(d)
                            } else {
                                p[key] = .string($0)
                            }
                            document.theme.presets[name] = p
                        }
                    ))
                    Button {
                        var p = props
                        p.removeValue(forKey: key)
                        document.theme.presets[name] = p
                    } label: {
                        Image(systemName: "xmark.circle")
                    }
                    .buttonStyle(.borderless)
                }
            }

            Menu("Add property") {
                let styleKeys = ["font", "foregroundColor", "backgroundColor", "padding",
                                 "cornerRadius", "width", "height", "maxWidth", "maxHeight",
                                 "opacity", "shadow", "clipShape"]
                let available = styleKeys.filter { props[$0] == nil }
                ForEach(available, id: \.self) { key in
                    Button(key) {
                        var p = props
                        p[key] = .string("")
                        document.theme.presets[name] = p
                    }
                }
            }

            Button("Delete Preset", role: .destructive) {
                document.theme.presets.removeValue(forKey: name)
            }
        }
    }
}
