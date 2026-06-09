import Foundation

@MainActor
enum PreviewFixtures {
    static func emptyState() -> AppState {
        AppState()
    }

    static func sampleState() -> AppState {
        let state = AppState()
        state.groups = [
            sampleGroup(name: "001_海边日落.jpg", rating: .good, rawCount: 1),
            sampleGroup(name: "002_街角人像.jpg", rating: .maybe, rawCount: 1),
            sampleGroup(name: "003_失焦废片.jpg", rating: .bad, rawCount: 1),
            sampleGroup(name: "004_候选构图.jpg", rating: nil, rawCount: 0)
        ]
        state.currentIndex = 1
        state.statusText = "预览数据：这里不会读取真实照片。"
        return state
    }

    private static func sampleGroup(name: String, rating: Rating?, rawCount: Int) -> PhotoGroup {
        let preview = PhotoFile(
            url: URL(fileURLWithPath: "/tmp/\(name)"),
            relativePath: name,
            kind: .jpeg
        )

        var files = [preview]
        for index in 1...rawCount {
            files.append(PhotoFile(
                url: URL(fileURLWithPath: "/tmp/\(nameWithoutExtension(name))-\(index).dng"),
                relativePath: "\(nameWithoutExtension(name))-\(index).dng",
                kind: .raw
            ))
        }

        files.append(PhotoFile(
            url: URL(fileURLWithPath: "/tmp/\(nameWithoutExtension(name)).xmp"),
            relativePath: "\(nameWithoutExtension(name)).xmp",
            kind: .xmp
        ))

        return PhotoGroup(id: UUID(), preview: preview, files: files, rating: rating)
    }

    private static func nameWithoutExtension(_ name: String) -> String {
        (name as NSString).deletingPathExtension
    }
}
