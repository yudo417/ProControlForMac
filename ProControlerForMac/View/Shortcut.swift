import SwiftUI
import ShortcutRecorder

struct ShortCut: NSViewRepresentable {
    func makeNSView(context: Context) -> RecorderControl {
        let control = RecorderControl()
        // Configure the control here if needed, e.g.:
        // control.allowsEmptyShortcut = true
        return control
    }

    func updateNSView(_ nsView: RecorderControl, context: Context) {
        // Update the control if your SwiftUI state changes
        // For now, no updates are necessary
    }
}
