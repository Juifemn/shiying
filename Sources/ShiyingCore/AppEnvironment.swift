import Foundation

@MainActor
public enum AppEnvironment {
    static let sharedState = AppState()

    public static func openSelection(_ url: URL) {
        sharedState.loadSelection(from: url)
    }
}
