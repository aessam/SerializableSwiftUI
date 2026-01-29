import SwiftUI
import ViewEngine
import ActionSystem

enum PreviewDataMode: String, CaseIterable {
    case mock = "Mock"
    case live = "Live"
}

struct LivePreviewView: View {
    let rootNode: EditableViewNode
    let screenName: String

    @State private var dataMode: PreviewDataMode = .mock
    @State private var liveContext: DataContext?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var refreshID = UUID()

    private var cache: LiveDataCache { .shared }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            toolbar
            Divider()
            previewContent
        }
        .onChange(of: dataMode) { _, newMode in
            if newMode == .live && liveContext == nil {
                Task { await fetchLiveData(force: false) }
            }
        }
    }

    private var toolbar: some View {
        HStack {
            Text("Preview")
                .font(.headline)

            Spacer()

            Picker("", selection: $dataMode) {
                ForEach(PreviewDataMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 120)

            if dataMode == .live {
                if cache.hasCached(screenName) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .help("Using cached data")
                }

                Button {
                    Task { await fetchLiveData(force: true) }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .disabled(isLoading)
                .help("Force refresh (bypass cache)")
            }

            Text(screenName)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var previewContent: some View {
        if isLoading {
            VStack {
                Spacer()
                ProgressView("Loading live data...")
                Spacer()
            }
            .frame(maxWidth: .infinity)
        } else {
            ScrollView {
                let viewNode = rootNode.toViewNode()
                let context = activeContext
                ViewRenderer(node: viewNode, context: context)
                    .id(refreshID)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .padding()
            }
            .overlay(alignment: .bottom) {
                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(6)
                        .background(.red.opacity(0.8))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .padding(8)
                }
            }
        }
    }

    private var activeContext: DataContext {
        switch dataMode {
        case .mock:
            return MockDataProvider.context(for: screenName)
        case .live:
            return liveContext ?? cache.cachedContext(screenName) ?? MockDataProvider.context(for: screenName)
        }
    }

    @MainActor
    private func fetchLiveData(force: Bool) async {
        isLoading = true
        errorMessage = nil

        let result = await cache.fetch(screenName: screenName, force: force)

        switch result {
        case .cached(let ctx), .fetched(let ctx):
            liveContext = ctx
            refreshID = UUID()
        case .error(let msg):
            errorMessage = msg
        }

        isLoading = false
    }
}
