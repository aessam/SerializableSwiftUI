import SwiftUI
import ViewEngine
import ActionSystem
import PodcastData
import EditorUI
import os

private let logger = Logger(subsystem: "SerializableSwiftUI", category: "App")

func appLog(_ msg: String) {
    logger.notice("\(msg, privacy: .public)")
    fputs("[App] \(msg)\n", stderr)
}

@main
struct SerializableSwiftUIApp: App {
    @State private var editorMode = false

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
            if editorMode {
                editorView
            } else {
                RootView()
            }
        }
        .commands {
            CommandMenu("Editor") {
                Toggle("Editor Mode", isOn: $editorMode)
                    .keyboardShortcut("e", modifiers: [.command, .shift])
            }
        }
    }

    private var editorView: some View {
        let resourcesURL = Bundle.module.bundleURL
            .appendingPathComponent("Contents")
            .appendingPathComponent("Resources")
        let projectURL: URL = {
            // Try the processed resources path; fall back to bundle URL
            if FileManager.default.fileExists(atPath: resourcesURL.path) {
                return resourcesURL
            }
            return Bundle.module.bundleURL
        }()
        let manager = ProjectManager(projectURL: projectURL)
        let document = manager.loadDocument()
        return EditorRootView(document: document)
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
