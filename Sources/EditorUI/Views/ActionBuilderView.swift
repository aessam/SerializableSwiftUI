import SwiftUI
import ViewEngine

struct ActionBuilderView: View {
    let label: String
    @Binding var action: AnyCodableValue?
    var availableScreens: [String] = []

    @State private var expanded = false

    private var actionType: String {
        action?.dictionaryValue?["actionType"]?.stringValue ?? ""
    }

    private static let actionTypes = ["navigate", "present", "dismiss", "api", "setState", "custom", "sequence"]

    var body: some View {
        DisclosureGroup(label, isExpanded: $expanded) {
            VStack(alignment: .leading, spacing: 8) {
                // Action type picker
                Picker("Action Type", selection: Binding(
                    get: { actionType },
                    set: { newType in
                        var dict = action?.dictionaryValue ?? [:]
                        dict["actionType"] = .string(newType)
                        action = .dictionary(dict)
                    }
                )) {
                    Text("(none)").tag("")
                    ForEach(Self.actionTypes, id: \.self) { t in
                        Text(t).tag(t)
                    }
                }

                switch actionType {
                case "navigate", "present":
                    navigationFields
                case "api":
                    apiFields
                case "setState":
                    setStateFields
                case "custom":
                    customFields
                default:
                    EmptyView()
                }
            }
            .padding(.leading, 8)
        }
    }

    @ViewBuilder
    private var navigationFields: some View {
        HStack {
            Text("Screen")
                .frame(width: 80, alignment: .leading)
            if availableScreens.isEmpty {
                TextField("screen name", text: dictStringBinding("screen"))
            } else {
                Picker("", selection: dictStringBinding("screen")) {
                    Text("(none)").tag("")
                    ForEach(availableScreens, id: \.self) { s in
                        Text(s).tag(s)
                    }
                }
            }
        }

        HStack {
            Text("Params")
                .frame(width: 80, alignment: .leading)
            TextField("JSON params", text: dictStringBinding("params"))
                .font(.caption.monospaced())
        }
    }

    @ViewBuilder
    private var apiFields: some View {
        HStack {
            Text("Endpoint")
                .frame(width: 80, alignment: .leading)
            TextField("/path", text: dictStringBinding("endpoint"))
        }
        HStack {
            Text("Result Key")
                .frame(width: 80, alignment: .leading)
            TextField("key", text: dictStringBinding("resultKey"))
        }
    }

    @ViewBuilder
    private var setStateFields: some View {
        HStack {
            Text("Key")
                .frame(width: 80, alignment: .leading)
            TextField("key", text: dictStringBinding("key"))
        }
        HStack {
            Text("Value")
                .frame(width: 80, alignment: .leading)
            TextField("value", text: dictStringBinding("value"))
        }
    }

    @ViewBuilder
    private var customFields: some View {
        HStack {
            Text("Event")
                .frame(width: 80, alignment: .leading)
            TextField("event name", text: dictStringBinding("event"))
        }
    }

    private func dictStringBinding(_ key: String) -> Binding<String> {
        Binding(
            get: {
                action?.dictionaryValue?[key]?.stringValue ?? ""
            },
            set: { newValue in
                var dict = action?.dictionaryValue ?? [:]
                if newValue.isEmpty {
                    dict.removeValue(forKey: key)
                } else {
                    dict[key] = .string(newValue)
                }
                action = .dictionary(dict)
            }
        )
    }
}
