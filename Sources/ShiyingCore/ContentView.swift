import AppKit
import SwiftUI

public struct ContentView: View {
    @StateObject private var appState: AppState

    public init() {
        _appState = StateObject(wrappedValue: AppEnvironment.sharedState)
    }

    public var body: some View {
        HStack(spacing: 0) {
            SidebarView(appState: appState)
                .frame(width: 300)
                .background(.ultraThinMaterial)

            Divider()

            PreviewPane(appState: appState)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 980, minHeight: 680)
        .background(Color(nsColor: .windowBackgroundColor))
        .overlay(KeyCaptureView { event in
            handleKey(event)
        })
    }

    private func handleKey(_ event: NSEvent) {
        switch event.charactersIgnoringModifiers {
        case "1":
            appState.setRating(.good)
        case "2":
            appState.setRating(.maybe)
        case "3":
            appState.setRating(.bad)
        case "0":
            appState.clearRating()
        default:
            switch event.keyCode {
            case 123:
                appState.goPrevious()
            case 124:
                appState.goNext()
            default:
                break
            }
        }
    }
}

#Preview("主窗口") {
    ContentView()
}
