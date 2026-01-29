import SwiftUI
import ViewEngine
import ActionSystem
import PodcastData

struct JSONDrivenView: View {
    let node: ViewNode
    var initialParams: [String: AnyCodableValue] = [:]

    @State private var context = DataContext(data: ["env": .dictionary([:])])
    @State private var navigationPath: [NavigationItem] = []
    @State private var sheetItem: NavigationItem?
    @State private var isLoading = false

    struct NavigationItem: Identifiable, Hashable {
        let id = UUID()
        let screen: String
        let params: [String: AnyCodableValue]

        static func == (lhs: NavigationItem, rhs: NavigationItem) -> Bool {
            lhs.id == rhs.id
        }
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }

    var body: some View {
        Group {
            if node.type == "tab_view" {
                renderTabView()
            } else {
                Text("Use ScreenLoader for non-tab roots")
            }
        }
    }

    @ViewBuilder
    private func renderTabView() -> some View {
        if let tabs = node.tabsProp() {
            TabView {
                ForEach(Array(tabs.enumerated()), id: \.offset) { _, tab in
                    ScreenLoader(screen: tab.screen, params: [:])
                        .tabItem {
                            Label(tab.title, systemImage: tab.icon)
                        }
                }
            }
        }
    }
}

struct ScreenLoader: View {
    let screen: String
    let params: [String: AnyCodableValue]

    @State private var node: ViewNode?
    @State private var context: DataContext?
    @State private var isLoading = true
    @State private var navigationPath: [JSONDrivenView.NavigationItem] = []
    @State private var sheetItem: JSONDrivenView.NavigationItem?
    @State private var dispatcher = ActionDispatcher()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if let node, let context {
                    ZStack {
                        if isLoading {
                            ProgressView()
                        }
                        ViewRenderer(node: node, context: context, onAction: { action, ctx in
                            handleAction(action, context: ctx)
                        })
                    }
                    .navigationTitle(resolveTitle())
                } else {
                    ProgressView("Loading \(screen)...")
                }
            }
            .navigationDestination(for: JSONDrivenView.NavigationItem.self) { item in
                ChildScreenLoader(screen: item.screen, params: item.params)
            }
        }
        .sheet(item: $sheetItem) { item in
            NavigationStack {
                ChildScreenLoader(screen: item.screen, params: item.params)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") { sheetItem = nil }
                        }
                    }
            }
        }
        .onAppear {
            loadScreen()
        }
    }

    private func handleAction(_ action: ActionDefinition, context ctx: DataContext) {
        Task { @MainActor in
            dispatcher.onNavigate = { navScreen, navParams in
                navigationPath.append(JSONDrivenView.NavigationItem(screen: navScreen, params: navParams))
            }
            dispatcher.onPresent = { navScreen, navParams in
                sheetItem = JSONDrivenView.NavigationItem(screen: navScreen, params: navParams)
            }
            dispatcher.onDismiss = {
                sheetItem = nil
            }
            await dispatcher.dispatch(action, context: ctx)
        }
    }

    private func resolveTitle() -> String {
        guard let node, let context else { return "" }
        if let title = node.stringProp("title") {
            return context.resolveString(title)
        }
        return ""
    }

    private func loadScreen() {
        guard let url = Bundle.module.url(forResource: screen, withExtension: "json") else {
            appLog("ScreenLoader ERROR: \(screen).json not found in bundle")
            isLoading = false
            return
        }
        appLog("ScreenLoader: Loading \(screen).json")
        guard let data = try? Data(contentsOf: url),
              let loadedNode = try? JSONDecoder().decode(ViewNode.self, from: data) else {
            appLog("ScreenLoader ERROR: Could not decode \(screen).json")
            isLoading = false
            return
        }

        let ctx = DataContext(data: ["env": .dictionary([:])])
        for (k, v) in params {
            ctx.set(k, value: v)
        }

        self.node = loadedNode
        self.context = ctx

        let onLoad: ActionDefinition? = loadedNode.actionProp("onLoad") ?? loadedNode.props?["onLoad"].flatMap({ val -> ActionDefinition? in
            guard let dict = val.dictionaryValue else { return nil }
            let jsonData = try? JSONEncoder().encode(AnyCodableValue.dictionary(dict))
            guard let jsonData else { return nil }
            return try? JSONDecoder().decode(ActionDefinition.self, from: jsonData)
        })
        appLog("ScreenLoader: \(screen) onLoad=\(onLoad?.actionType ?? "none")")
        if let onLoad {
            Task { @MainActor in
                dispatcher.onNavigate = { navScreen, navParams in
                    navigationPath.append(JSONDrivenView.NavigationItem(screen: navScreen, params: navParams))
                }
                await dispatcher.dispatch(onLoad, context: ctx)
                appLog("ScreenLoader: \(screen) onLoad completed, context keys: \(ctx.data.keys.sorted())")
                isLoading = false
            }
        } else {
            isLoading = false
        }
    }
}

/// Child screen loader used inside NavigationStack destinations — does NOT create its own NavigationStack
struct ChildScreenLoader: View {
    let screen: String
    let params: [String: AnyCodableValue]

    @State private var node: ViewNode?
    @State private var context: DataContext?
    @State private var isLoading = true
    @State private var dispatcher = ActionDispatcher()
    @State private var navigationPath: [JSONDrivenView.NavigationItem] = []
    @State private var sheetItem: JSONDrivenView.NavigationItem?

    var body: some View {
        Group {
            if let node, let context {
                ZStack {
                    if isLoading {
                        ProgressView()
                    }
                    ViewRenderer(node: node, context: context, onAction: { action, ctx in
                        Task { @MainActor in
                            dispatcher.onNavigate = { navScreen, navParams in
                                navigationPath.append(JSONDrivenView.NavigationItem(screen: navScreen, params: navParams))
                            }
                            dispatcher.onPresent = { navScreen, navParams in
                                sheetItem = JSONDrivenView.NavigationItem(screen: navScreen, params: navParams)
                            }
                            dispatcher.onDismiss = { sheetItem = nil }
                            await dispatcher.dispatch(action, context: ctx)
                        }
                    })
                }
                .navigationTitle(resolveTitle())
                .navigationDestination(for: JSONDrivenView.NavigationItem.self) { item in
                    ChildScreenLoader(screen: item.screen, params: item.params)
                }
                .sheet(item: $sheetItem) { item in
                    NavigationStack {
                        ChildScreenLoader(screen: item.screen, params: item.params)
                            .toolbar {
                                ToolbarItem(placement: .cancellationAction) {
                                    Button("Done") { sheetItem = nil }
                                }
                            }
                    }
                }
            } else {
                ProgressView("Loading \(screen)...")
            }
        }
        .onAppear {
            loadScreen()
        }
    }

    private func resolveTitle() -> String {
        guard let node, let context else { return "" }
        if let title = node.stringProp("title") {
            return context.resolveString(title)
        }
        return ""
    }

    private func loadScreen() {
        guard let url = Bundle.module.url(forResource: screen, withExtension: "json") else {
            appLog("ChildScreenLoader ERROR: \(screen).json not found in bundle")
            isLoading = false
            return
        }
        appLog("ChildScreenLoader: Loading \(screen).json")
        guard let data = try? Data(contentsOf: url),
              let loadedNode = try? JSONDecoder().decode(ViewNode.self, from: data) else {
            appLog("ChildScreenLoader ERROR: Could not decode \(screen).json")
            isLoading = false
            return
        }

        let ctx = DataContext(data: ["env": .dictionary([:])])
        for (k, v) in params {
            ctx.set(k, value: v)
        }

        self.node = loadedNode
        self.context = ctx

        let onLoad: ActionDefinition? = loadedNode.actionProp("onLoad") ?? loadedNode.props?["onLoad"].flatMap({ val -> ActionDefinition? in
            guard let dict = val.dictionaryValue else { return nil }
            let jsonData = try? JSONEncoder().encode(AnyCodableValue.dictionary(dict))
            guard let jsonData else { return nil }
            return try? JSONDecoder().decode(ActionDefinition.self, from: jsonData)
        })
        appLog("ChildScreenLoader: \(screen) onLoad=\(onLoad?.actionType ?? "none")")
        if let onLoad {
            Task { @MainActor in
                dispatcher.onNavigate = { navScreen, navParams in
                    navigationPath.append(JSONDrivenView.NavigationItem(screen: navScreen, params: navParams))
                }
                await dispatcher.dispatch(onLoad, context: ctx)
                appLog("ChildScreenLoader: \(screen) onLoad completed, context keys: \(ctx.data.keys.sorted())")
                isLoading = false
            }
        } else {
            isLoading = false
        }
    }
}
