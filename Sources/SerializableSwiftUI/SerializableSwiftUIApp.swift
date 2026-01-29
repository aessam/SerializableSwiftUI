import SwiftUI
import ViewEngine
import ActionSystem
import PodcastData
import os

private let logger = Logger(subsystem: "SerializableSwiftUI", category: "App")

func appLog(_ msg: String) {
    logger.notice("\(msg, privacy: .public)")
    fputs("[App] \(msg)\n", stderr)
}

@main
struct SerializableSwiftUIApp: App {
    init() {
        #if os(macOS)
        NSApplication.shared.setActivationPolicy(.regular)
        #endif
        appLog("Initializing, resource bundle: \(Bundle.module.bundlePath)")
        ThemeEngine.shared.load(from: Bundle.module)
        ComponentRegistry.shared.load(from: Bundle.module)
        appLog("Theme colors: \(ThemeEngine.shared.colors.count), presets: \(ThemeEngine.shared.presets.count)")
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

struct RootView: View {
    @State private var rootNode: ViewNode?

    var body: some View {
        Group {
            if let rootNode {
                JSONDrivenView(node: rootNode)
            } else {
                ProgressView("Loading...")
            }
        }
        .onAppear {
            loadRoot()
        }
    }

    private func loadRoot() {
        guard let url = Bundle.module.url(forResource: "app", withExtension: "json") else {
            appLog("ERROR: app.json not found in bundle")
            return
        }
        appLog("Loading app.json from: \(url.path)")
        guard let data = try? Data(contentsOf: url) else {
            appLog("ERROR: Could not read app.json")
            return
        }
        do {
            rootNode = try JSONDecoder().decode(ViewNode.self, from: data)
            appLog("Loaded root node: type=\(rootNode?.type ?? "nil")")
        } catch {
            appLog("ERROR decoding app.json: \(error)")
        }
    }
}
