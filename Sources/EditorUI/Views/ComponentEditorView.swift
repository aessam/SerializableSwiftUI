import SwiftUI
import ViewEngine
import ActionSystem

struct ComponentEditorView: View {
    @Bindable var document: EditorDocument

    @State private var selectedComponent: String?
    @State private var newComponentName = ""

    var body: some View {
        HSplitView {
            componentList
                .frame(minWidth: 180, maxWidth: 250)

            if let name = selectedComponent, let comp = document.components[name] {
                componentDetail(name: name, component: comp)
            } else {
                ContentUnavailableView("No Component Selected", systemImage: "puzzlepiece",
                                       description: Text("Select a component to edit"))
            }
        }
    }

    private var componentList: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Components")
                    .font(.headline)
                Spacer()
            }
            .padding(8)

            Divider()

            List(selection: $selectedComponent) {
                ForEach(Array(document.components.keys), id: \.self) { name in
                    Label(name, systemImage: "puzzlepiece")
                        .tag(name)
                        .contextMenu {
                            Button("Delete", role: .destructive) {
                                document.components.removeValue(forKey: name)
                                if selectedComponent == name { selectedComponent = nil }
                            }
                        }
                }
            }
            .listStyle(.sidebar)

            Divider()

            HStack {
                TextField("Name", text: $newComponentName)
                Button("Add") {
                    guard !newComponentName.isEmpty, document.components[newComponentName] == nil else { return }
                    let node = EditableViewNode(type: "vstack")
                    document.components[newComponentName] = EditableComponentDef(parameters: [], body: node)
                    selectedComponent = newComponentName
                    newComponentName = ""
                }
            }
            .padding(8)
        }
    }

    @ViewBuilder
    private func componentDetail(name: String, component: EditableComponentDef) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(name).font(.headline)
                Spacer()
            }
            .padding(8)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ComponentParameterEditor(component: component)

                    Divider()

                    Section("Body") {
                        TreeOutlineView(document: document, root: component.body)
                            .frame(minHeight: 200)
                    }

                    Divider()

                    ComponentLivePreview(
                        component: component,
                        screenNames: Array(document.screens.keys)
                    )
                }
                .padding()
            }
        }
    }
}

// MARK: - Component preview backed by LiveDataCache

private struct ComponentLivePreview: View {
    let component: EditableComponentDef
    let screenNames: [String]

    private var cache: LiveDataCache { .shared }

    @State private var sourceScreen: String = ""
    @State private var currentIndex = 0
    @State private var isLoading = false
    @State private var errorMessage: String?

    private var items: [AnyCodableValue] {
        if sourceScreen.isEmpty {
            return cache.allCachedItems
        }
        return cache.cachedItems(sourceScreen)
    }

    var body: some View {
        Section {
            HStack {
                Text("Data source:")
                Picker("", selection: $sourceScreen) {
                    Text("All cached").tag("")
                    ForEach(screenNames, id: \.self) { name in
                        HStack {
                            Text(name)
                            if cache.hasCached(name) {
                                Image(systemName: "checkmark.circle.fill")
                            }
                        }
                        .tag(name)
                    }
                }
                .frame(width: 160)

                Button {
                    Task { await fetchData(force: false) }
                } label: {
                    Label("Fetch", systemImage: "arrow.down.circle")
                }
                .buttonStyle(.bordered)
                .disabled(sourceScreen.isEmpty || isLoading)

                if isLoading {
                    ProgressView().controlSize(.small)
                }
            }

            if !items.isEmpty {
                HStack {
                    Button {
                        randomize()
                    } label: {
                        Label("Randomize", systemImage: "dice")
                    }
                    .buttonStyle(.bordered)

                    Button {
                        currentIndex = max(0, currentIndex - 1)
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .buttonStyle(.borderless)
                    .disabled(currentIndex == 0)

                    Text("\(currentIndex + 1) / \(items.count)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(width: 60)

                    Button {
                        currentIndex = min(items.count - 1, currentIndex + 1)
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                    .buttonStyle(.borderless)
                    .disabled(currentIndex >= items.count - 1)

                    Spacer()

                    if cache.hasCached(sourceScreen.isEmpty ? "" : sourceScreen) || !cache.allCachedItems.isEmpty {
                        Image(systemName: "bolt.fill")
                            .foregroundStyle(.green)
                            .help("Serving from cache")
                    }
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            let viewNode = component.body.toViewNode()
            let context = previewContext()
            ViewRenderer(node: viewNode, context: context)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } header: {
            Text("Preview").font(.headline)
        }
    }

    private func previewContext() -> DataContext {
        let ctx = DataContext(data: ["env": .dictionary([:])])
        let pool = items
        guard !pool.isEmpty else { return ctx }
        let idx = currentIndex % pool.count
        let item = pool[idx]
        for param in component.parameters {
            ctx.set(param, value: item)
        }
        return ctx
    }

    private func randomize() {
        let pool = items
        guard pool.count > 1 else { return }
        var next = currentIndex
        while next == currentIndex {
            next = Int.random(in: 0..<pool.count)
        }
        currentIndex = next
    }

    @MainActor
    private func fetchData(force: Bool) async {
        guard !sourceScreen.isEmpty else { return }
        isLoading = true
        errorMessage = nil

        let result = await cache.fetch(screenName: sourceScreen, force: force)
        if let msg = result.errorMessage {
            errorMessage = msg
        } else {
            currentIndex = 0
        }

        isLoading = false
    }
}

// MARK: - Parameter editor with model awareness

private struct ComponentParameterEditor: View {
    @Bindable var component: EditableComponentDef

    private let registry = DataModelRegistry.shared

    var body: some View {
        Section {
            // Existing parameters
            ForEach(Array(component.parameters.enumerated()), id: \.offset) { idx, param in
                HStack {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 6))
                        .foregroundStyle(modelColor(for: param))

                    Text(param)
                        .fontWeight(.medium)

                    if let model = matchingModel(for: param) {
                        Text("(\(model.name))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Show fields this parameter exposes
                    if let model = matchingModel(for: param) {
                        Menu {
                            Text("Available fields via $.\(param).___")
                                .font(.caption)
                            Divider()
                            ForEach(model.fields, id: \.name) { field in
                                Button {} label: {
                                    Text("$.\(param).\(field.name)")
                                }
                                .disabled(true)
                            }
                        } label: {
                            Label("\(model.fields.count) fields", systemImage: "list.bullet")
                                .font(.caption)
                        }
                        .menuStyle(.borderlessButton)
                        .fixedSize()
                    }

                    Button {
                        component.parameters.remove(at: idx)
                    } label: {
                        Image(systemName: "xmark.circle")
                    }
                    .buttonStyle(.borderless)
                }
            }

            Divider()

            // Add from known models
            Text("Add parameter from model:")
                .font(.caption)
                .foregroundStyle(.secondary)

            ForEach(registry.models, id: \.name) { model in
                let paramName = model.name.lowercased()
                let alreadyAdded = component.parameters.contains(paramName)

                Button {
                    component.parameters.append(paramName)
                } label: {
                    HStack {
                        Image(systemName: "plus.circle")
                        Text(model.name)
                            .fontWeight(.medium)
                        Text("— \(model.fields.count) fields")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        if alreadyAdded {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.green)
                        }
                    }
                }
                .buttonStyle(.plain)
                .disabled(alreadyAdded)

                // Show all fields for this model
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(model.fields, id: \.name) { field in
                        HStack(spacing: 4) {
                            Text("$.\(paramName).\(field.name)")
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(fieldTypeName(field.type))
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
                .padding(.leading, 24)
            }

            Divider()

            // Manual add
            HStack {
                Text("Custom:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                CustomParamAdder(parameters: $component.parameters)
            }
        } header: {
            Label("Parameters", systemImage: "slider.horizontal.3")
                .font(.headline)
        }
    }

    private func matchingModel(for param: String) -> DataModelDescriptor? {
        registry.models.first { $0.name.lowercased() == param.lowercased() }
    }

    private func modelColor(for param: String) -> Color {
        if matchingModel(for: param) != nil { return .green }
        return .orange
    }

    private func fieldTypeName(_ type: FieldType) -> String {
        switch type {
        case .string: return "String"
        case .int: return "Int"
        case .double: return "Double"
        case .url: return "URL"
        case .bool: return "Bool"
        case .array(let of): return "[\(of)]"
        case .object: return "Object"
        }
    }
}

private struct CustomParamAdder: View {
    @Binding var parameters: [String]
    @State private var name = ""

    var body: some View {
        HStack {
            TextField("param name", text: $name)
                .frame(width: 120)
            Button("Add") {
                let trimmed = name.trimmingCharacters(in: .whitespaces).lowercased()
                guard !trimmed.isEmpty, !parameters.contains(trimmed) else { return }
                parameters.append(trimmed)
                name = ""
            }
            .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }
}
