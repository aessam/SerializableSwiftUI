import Foundation

public enum NodeCategory: String, CaseIterable {
    case layout = "Layout"
    case content = "Content"
    case interactive = "Interactive"
    case data = "Data"
    case navigation = "Navigation"
}

public struct PropDef {
    public let key: String
    public let label: String
    public let editor: PropEditor
    public let required: Bool

    public init(key: String, label: String, editor: PropEditor, required: Bool = false) {
        self.key = key; self.label = label; self.editor = editor; self.required = required
    }
}

public enum PropEditor {
    case text
    case number
    case toggle
    case dropdown([String])
    case binding
    case action
    case node
    case nodeArray
}

public struct NodeTypeInfo {
    public let type: String
    public let category: NodeCategory
    public let icon: String
    public let validProps: [PropDef]

    public static let all: [NodeTypeInfo] = [
        // Layout
        NodeTypeInfo(type: "vstack", category: .layout, icon: "rectangle.split.1x2", validProps: [
            PropDef(key: "spacing", label: "Spacing", editor: .number),
            PropDef(key: "alignment", label: "Alignment", editor: .dropdown(["center", "leading", "trailing"])),
        ]),
        NodeTypeInfo(type: "hstack", category: .layout, icon: "rectangle.split.2x1", validProps: [
            PropDef(key: "spacing", label: "Spacing", editor: .number),
            PropDef(key: "alignment", label: "Alignment", editor: .dropdown(["center", "top", "bottom"])),
        ]),
        NodeTypeInfo(type: "zstack", category: .layout, icon: "square.stack", validProps: []),
        NodeTypeInfo(type: "scroll", category: .layout, icon: "scroll", validProps: [
            PropDef(key: "axis", label: "Axis", editor: .dropdown(["vertical", "horizontal"])),
        ]),
        NodeTypeInfo(type: "lazy_vstack", category: .layout, icon: "rectangle.split.1x2", validProps: [
            PropDef(key: "spacing", label: "Spacing", editor: .number),
            PropDef(key: "alignment", label: "Alignment", editor: .dropdown(["center", "leading", "trailing"])),
        ]),
        NodeTypeInfo(type: "lazy_hstack", category: .layout, icon: "rectangle.split.2x1", validProps: [
            PropDef(key: "spacing", label: "Spacing", editor: .number),
            PropDef(key: "alignment", label: "Alignment", editor: .dropdown(["center", "top", "bottom"])),
        ]),
        NodeTypeInfo(type: "spacer", category: .layout, icon: "arrow.up.and.down", validProps: [
            PropDef(key: "minLength", label: "Min Length", editor: .number),
        ]),
        NodeTypeInfo(type: "grid", category: .layout, icon: "square.grid.2x2", validProps: [
            PropDef(key: "columns", label: "Columns", editor: .number),
            PropDef(key: "spacing", label: "Spacing", editor: .number),
        ]),

        // Content
        NodeTypeInfo(type: "text", category: .content, icon: "textformat", validProps: [
            PropDef(key: "content", label: "Content", editor: .text, required: true),
            PropDef(key: "lineLimit", label: "Line Limit", editor: .number),
        ]),
        NodeTypeInfo(type: "image", category: .content, icon: "photo", validProps: [
            PropDef(key: "source", label: "Source", editor: .text, required: true),
            PropDef(key: "contentMode", label: "Content Mode", editor: .dropdown(["fit", "fill"])),
        ]),
        NodeTypeInfo(type: "divider", category: .content, icon: "minus", validProps: []),

        // Interactive
        NodeTypeInfo(type: "button", category: .interactive, icon: "hand.tap", validProps: [
            PropDef(key: "action", label: "Action", editor: .action),
            PropDef(key: "label", label: "Label", editor: .node),
        ]),
        NodeTypeInfo(type: "text_field", category: .interactive, icon: "character.cursor.ibeam", validProps: [
            PropDef(key: "placeholder", label: "Placeholder", editor: .text),
            PropDef(key: "binding", label: "Binding", editor: .binding),
        ]),
        NodeTypeInfo(type: "search_bar", category: .interactive, icon: "magnifyingglass", validProps: [
            PropDef(key: "placeholder", label: "Placeholder", editor: .text),
            PropDef(key: "binding", label: "Binding", editor: .binding),
            PropDef(key: "onSubmit", label: "On Submit", editor: .action),
        ]),

        // Data
        NodeTypeInfo(type: "list", category: .data, icon: "list.bullet", validProps: [
            PropDef(key: "items", label: "Items Path", editor: .binding, required: true),
            PropDef(key: "itemTemplate", label: "Item Template", editor: .node),
        ]),
        NodeTypeInfo(type: "component", category: .data, icon: "puzzlepiece", validProps: [
            PropDef(key: "name", label: "Component Name", editor: .text, required: true),
            PropDef(key: "parameters", label: "Parameters", editor: .text),
        ]),

        // Navigation
        NodeTypeInfo(type: "screen", category: .navigation, icon: "rectangle.portrait", validProps: [
            PropDef(key: "title", label: "Title", editor: .text),
            PropDef(key: "onLoad", label: "On Load", editor: .action),
        ]),
        NodeTypeInfo(type: "navigation_stack", category: .navigation, icon: "square.stack.fill", validProps: []),
        NodeTypeInfo(type: "navigation_link", category: .navigation, icon: "chevron.right", validProps: []),
        NodeTypeInfo(type: "tab_view", category: .navigation, icon: "rectangle.bottomhalf.filled", validProps: [
            PropDef(key: "tabs", label: "Tabs", editor: .text),
        ]),
    ]

    public static let byType: [String: NodeTypeInfo] = {
        Dictionary(uniqueKeysWithValues: all.map { ($0.type, $0) })
    }()

    public static func icon(for type: String) -> String {
        byType[type]?.icon ?? "questionmark.square"
    }

    public static func category(for type: String) -> NodeCategory {
        byType[type]?.category ?? .content
    }

    public static var allTypeNames: [String] {
        all.map(\.type)
    }
}
