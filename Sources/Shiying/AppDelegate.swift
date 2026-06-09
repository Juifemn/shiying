import AppKit
import ShiyingCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        Task { @MainActor in
            if let filename = filenames.first {
                AppEnvironment.openSelection(URL(fileURLWithPath: filename))
                sender.activate(ignoringOtherApps: true)
            }
            sender.reply(toOpenOrPrint: .success)
        }
    }
}
