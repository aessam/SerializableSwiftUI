import SwiftUI

public struct ViewRenderer: View {
    let node: ViewNode
    let context: DataContext
    let onAction: ((ActionDefinition, DataContext) -> Void)?
    let componentRegistry: ComponentRegistry
    let themeEngine: ThemeEngine

    public init(node: ViewNode, context: DataContext,
                themeEngine: ThemeEngine = .shared,
                componentRegistry: ComponentRegistry = .shared,
                onAction: ((ActionDefinition, DataContext) -> Void)? = nil) {
        self.node = node
        self.context = context
        self.themeEngine = themeEngine
        self.componentRegistry = componentRegistry
        self.onAction = onAction
    }

    public var body: some View {
        if let condition = node.condition {
            if ConditionEvaluator.evaluate(condition, context: context) {
                styledContent
            }
        } else {
            styledContent
        }
    }

    @ViewBuilder
    private var styledContent: some View {
        themeEngine.applyStyle(rawContent, style: node.style, inlineStyle: node.inlineStyle)
    }

    @ViewBuilder
    private var rawContent: some View {
        switch node.type {
        case "vstack":
            let spacing = node.doubleProp("spacing").map { CGFloat($0) }
            let alignment = horizontalAlignment(node.stringProp("alignment"))
            VStack(alignment: alignment, spacing: spacing) {
                renderChildren()
            }
        case "hstack":
            let spacing = node.doubleProp("spacing").map { CGFloat($0) }
            let alignment = verticalAlignment(node.stringProp("alignment"))
            HStack(alignment: alignment, spacing: spacing) {
                renderChildren()
            }
        case "zstack":
            ZStack {
                renderChildren()
            }
        case "scroll":
            let axis: Axis.Set = node.stringProp("axis") == "horizontal" ? .horizontal : .vertical
            ScrollView(axis) {
                renderChildren()
            }
        case "lazy_vstack":
            let spacing = node.doubleProp("spacing").map { CGFloat($0) }
            let alignment = horizontalAlignment(node.stringProp("alignment"))
            LazyVStack(alignment: alignment, spacing: spacing) {
                renderChildren()
            }
        case "lazy_hstack":
            let spacing = node.doubleProp("spacing").map { CGFloat($0) }
            let alignment = verticalAlignment(node.stringProp("alignment"))
            LazyHStack(alignment: alignment, spacing: spacing) {
                renderChildren()
            }
        case "spacer":
            if let minLength = node.doubleProp("minLength") {
                Spacer(minLength: CGFloat(minLength))
            } else {
                Spacer()
            }
        case "grid":
            let cols = node.intProp("columns") ?? 2
            let spacing = node.doubleProp("spacing").map { CGFloat($0) } ?? 8
            let columns = Array(repeating: GridItem(.flexible(), spacing: spacing), count: cols)
            LazyVGrid(columns: columns, spacing: spacing) {
                renderChildren()
            }
        case "text":
            renderText()
        case "image":
            renderImage()
        case "divider":
            Divider()
        case "button":
            renderButton()
        case "navigation_link":
            renderChildren() // handled at JSONDrivenView level
        case "text_field":
            renderTextField()
        case "search_bar":
            renderSearchBar()
        case "tab_view":
            EmptyView() // handled at JSONDrivenView level
        case "navigation_stack":
            renderChildren()
        case "screen":
            renderChildren()
        case "list":
            renderList()
        case "component":
            renderComponent()
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private func renderChildren() -> some View {
        if let children = node.children {
            ForEach(Array(children.enumerated()), id: \.offset) { _, child in
                ViewRenderer(node: child, context: context,
                           themeEngine: themeEngine, componentRegistry: componentRegistry,
                           onAction: onAction)
            }
        }
    }

    @ViewBuilder
    private func renderText() -> some View {
        let content = node.stringProp("content") ?? ""
        let resolved = context.resolveString(content)
        let lineLimit = node.intProp("lineLimit")
        if let lineLimit {
            Text(resolved).lineLimit(lineLimit)
        } else {
            Text(resolved)
        }
    }

    @ViewBuilder
    private func renderImage() -> some View {
        let source = node.stringProp("source") ?? ""
        let resolved = context.resolveString(source)
        let contentMode: ContentMode = node.stringProp("contentMode") == "fill" ? .fill : .fit

        if resolved.hasPrefix("http") {
            AsyncImage(url: URL(string: resolved)) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: contentMode)
                case .failure:
                    Image(systemName: "photo").foregroundStyle(.secondary)
                case .empty:
                    ProgressView()
                @unknown default:
                    EmptyView()
                }
            }
        } else {
            Image(systemName: resolved)
                .resizable()
                .aspectRatio(contentMode: contentMode)
        }
    }

    @ViewBuilder
    private func renderButton() -> some View {
        let action = node.actionProp("action")
        let labelNode = node.nodeProp("label")

        Button {
            if let action {
                onAction?(action, context)
            }
        } label: {
            if let labelNode {
                ViewRenderer(node: labelNode, context: context,
                           themeEngine: themeEngine, componentRegistry: componentRegistry,
                           onAction: onAction)
            } else {
                renderChildren()
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func renderTextField() -> some View {
        let placeholder = node.stringProp("placeholder") ?? ""
        let bindingPath = node.stringProp("binding") ?? ""
        let ctx = context

        let binding = Binding<String>(
            get: { ctx.resolve(bindingPath)?.stringValue ?? "" },
            set: { newValue in
                setNestedBinding(bindingPath, value: .string(newValue), context: ctx)
            }
        )
        TextField(placeholder, text: binding)
    }

    @ViewBuilder
    private func renderSearchBar() -> some View {
        let placeholder = node.stringProp("placeholder") ?? "Search..."
        let bindingPath = node.stringProp("binding") ?? ""
        let ctx = context
        let submitAction = node.actionProp("onSubmit")

        let binding = Binding<String>(
            get: { ctx.resolve(bindingPath)?.stringValue ?? "" },
            set: { newValue in
                setNestedBinding(bindingPath, value: .string(newValue), context: ctx)
            }
        )

        HStack {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            TextField(placeholder, text: binding)
                .onSubmit {
                    if let submitAction {
                        onAction?(submitAction, ctx)
                    }
                }
                .textFieldStyle(.plain)
        }
        .padding(8)
        .background(ThemeEngine.shared.resolveColor("surface"))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private func renderList() -> some View {
        let itemsPath = node.stringProp("items") ?? ""
        let templateNode = node.nodeProp("itemTemplate")
        if let items = context.resolve(itemsPath)?.arrayValue, let templateNode {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                let childContext = context.child(with: [
                    "item": item,
                    "index": .int(index)
                ])
                ViewRenderer(node: templateNode, context: childContext,
                           themeEngine: themeEngine, componentRegistry: componentRegistry,
                           onAction: onAction)
            }
        }
    }

    @ViewBuilder
    private func renderComponent() -> some View {
        let name = node.stringProp("name") ?? ""
        let params = node.prop("parameters")?.dictionaryValue ?? [:]

        if let (body, childCtx) = componentRegistry.resolve(name, parameters: params, context: context) {
            ViewRenderer(node: body, context: childCtx,
                       themeEngine: themeEngine, componentRegistry: componentRegistry,
                       onAction: onAction)
        }
    }

    private func horizontalAlignment(_ str: String?) -> HorizontalAlignment {
        switch str {
        case "leading": return .leading
        case "trailing": return .trailing
        case "center": return .center
        default: return .center
        }
    }

    private func verticalAlignment(_ str: String?) -> VerticalAlignment {
        switch str {
        case "top": return .top
        case "bottom": return .bottom
        case "center": return .center
        default: return .center
        }
    }

    private func setNestedBinding(_ path: String, value: AnyCodableValue, context: DataContext) {
        // path like "$.env.searchQuery" -> set context.data["env"] dict's "searchQuery" key
        let trimmed = path.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("$.") else { return }
        let keyPath = String(trimmed.dropFirst(2))
        let parts = keyPath.split(separator: ".").map(String.init)

        if parts.count == 1 {
            context.set(parts[0], value: value)
        } else if parts.count == 2 {
            var dict = context.data[parts[0]]?.dictionaryValue ?? [:]
            dict[parts[1]] = value
            context.set(parts[0], value: .dictionary(dict))
        } else {
            // Fallback: set the last component at root
            context.set(parts.last!, value: value)
        }
    }
}
