import SwiftUI
import ViewEngine

struct BindingPickerView: View {
    let label: String
    @Binding var value: String
    var screenName: String = ""

    @State private var showSuggestions = false

    private var suggestions: [String] {
        let all = DataModelRegistry.shared.allFieldPaths()
        if value.isEmpty { return all }
        let lower = value.lowercased()
        return all.filter { $0.lowercased().contains(lower) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(label)
                    .frame(width: 100, alignment: .leading)
                TextField("$.path", text: $value)
                    .onSubmit { showSuggestions = false }
                Button {
                    showSuggestions.toggle()
                } label: {
                    Image(systemName: "list.bullet")
                }
                .buttonStyle(.borderless)
            }

            if showSuggestions && !suggestions.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(suggestions, id: \.self) { path in
                            Button {
                                value = path
                                showSuggestions = false
                            } label: {
                                Text(path)
                                    .font(.caption.monospaced())
                                    .padding(.vertical, 2)
                                    .padding(.horizontal, 6)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(maxHeight: 120)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
    }
}
