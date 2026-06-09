import Foundation

enum Rating: String, CaseIterable, Identifiable {
    case good
    case maybe
    case bad

    var id: String { rawValue }

    var label: String {
        switch self {
        case .good: "1 好片"
        case .maybe: "2 待定"
        case .bad: "3 烂片"
        }
    }

    var folderName: String {
        switch self {
        case .good: "1好片"
        case .maybe: "2待定"
        case .bad: "3删除候选"
        }
    }

    var csvLabel: String {
        switch self {
        case .good: "好片"
        case .maybe: "待定"
        case .bad: "烂片"
        }
    }
}

enum ViewFilter: String, CaseIterable, Identifiable {
    case all
    case good
    case maybe
    case bad

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all: "全部"
        case .good: "好片"
        case .maybe: "待定"
        case .bad: "烂片"
        }
    }
}

enum PhotoFileKind: String {
    case jpeg
    case raw
    case xmp
    case preview
    case file
}

struct PhotoFile: Identifiable, Hashable {
    let id = UUID()
    let url: URL
    let relativePath: String
    let kind: PhotoFileKind

    var name: String {
        url.lastPathComponent
    }
}

struct PhotoGroup: Identifiable, Hashable {
    let id: UUID
    let preview: PhotoFile
    let files: [PhotoFile]
    var rating: Rating?

    var displayName: String {
        preview.name
    }

    var relativePath: String {
        preview.relativePath
    }

    var sidecarSummary: String {
        let rawCount = files.filter { $0.kind == .raw }.count
        let xmpCount = files.filter { $0.kind == .xmp }.count
        let otherCount = max(0, files.count - 1 - rawCount - xmpCount)
        var parts: [String] = []
        if rawCount > 0 { parts.append("\(rawCount) RAW") }
        if xmpCount > 0 { parts.append("\(xmpCount) XMP") }
        if otherCount > 0 { parts.append("\(otherCount) 附属") }
        return parts.joined(separator: " + ")
    }
}
