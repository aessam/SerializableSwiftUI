import SwiftUI

struct CanvasView: View {
    @Bindable var document: EditorDocument

    var body: some View {
        if let screen = document.selectedScreen {
            VSplitView {
                LivePreviewView(
                    rootNode: screen,
                    screenName: document.selectedScreenName ?? ""
                )
                .frame(minHeight: 200)

                TreeOutlineView(document: document, root: screen)
                    .frame(minHeight: 150)
            }
        } else {
            ContentUnavailableView("No Screen Selected", systemImage: "rectangle.portrait",
                                   description: Text("Select a screen from the navigator"))
        }
    }
}
