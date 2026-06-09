import AppKit
import Foundation
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published var sourceDirectory: URL?
    @Published var groups: [PhotoGroup] = []
    @Published var currentIndex: Int = 0
    @Published var viewFilter: ViewFilter = .all
    @Published var statusText = "先选择照片文件夹。"

    private let previewExtensions: Set<String> = [
        "jpg", "jpeg", "png", "webp", "gif", "bmp", "avif", "heic", "heif", "tif", "tiff"
    ]
    private let jpegExtensions: Set<String> = ["jpg", "jpeg"]
    private let rawExtensions: Set<String> = ["cr2", "cr3", "nef", "arw", "raf", "rw2", "orf", "dng", "pef", "srw"]
    private let sidecarExtensions: Set<String> = ["xmp"]

    var visibleGroups: [PhotoGroup] {
        switch viewFilter {
        case .all:
            groups
        case .good:
            groups.filter { $0.rating == .good }
        case .maybe:
            groups.filter { $0.rating == .maybe }
        case .bad:
            groups.filter { $0.rating == .bad }
        }
    }

    var currentGroup: PhotoGroup? {
        visibleGroups.indices.contains(currentIndex) ? visibleGroups[currentIndex] : nil
    }

    var counts: (good: Int, maybe: Int, bad: Int, unrated: Int, rated: Int) {
        var good = 0
        var maybe = 0
        var bad = 0
        var unrated = 0

        for group in groups {
            switch group.rating {
            case .good:
                good += 1
            case .maybe:
                maybe += 1
            case .bad:
                bad += 1
            case nil:
                unrated += 1
            }
        }

        return (good, maybe, bad, unrated, good + maybe + bad)
    }

    func chooseFolder() {
        let panel = NSOpenPanel()
        panel.title = "选择文件"
        panel.canChooseDirectories = true
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false

        guard panel.runModal() == .OK, let selectedURL = panel.url else {
            statusText = "已取消选择。"
            return
        }

        loadSelection(from: selectedURL)
    }

    func loadSelection(from selectedURL: URL) {
        do {
            let directory = try directoryForSelection(selectedURL)
            sourceDirectory = directory
            groups = try scan(directory: directory)
            currentIndex = 0
            viewFilter = .all
            statusText = groups.isEmpty
                ? "没有找到可预览的 JPEG/图片组。"
                : "已载入 \(groups.count) 组照片。按 1 / 2 / 3 开始筛。"
        } catch {
            statusText = "读取失败：\(error.localizedDescription)"
        }
    }

    func setRating(_ rating: Rating) {
        guard let current = currentGroup,
              let sourceIndex = groups.firstIndex(where: { $0.id == current.id })
        else { return }

        groups[sourceIndex].rating = rating
        let staysInView = viewFilter == .all || viewFilter.rawValue == rating.rawValue
        currentIndex = min(currentIndex, max(visibleGroups.count - 1, 0))

        if staysInView, currentIndex < visibleGroups.count - 1 {
            currentIndex += 1
        } else if visibleGroups.isEmpty {
            statusText = "这个视图已经没有照片了。"
        } else {
            statusText = "已经到最后一张。"
        }
    }

    func clearRating() {
        guard let current = currentGroup,
              let sourceIndex = groups.firstIndex(where: { $0.id == current.id })
        else { return }

        groups[sourceIndex].rating = nil
        currentIndex = min(currentIndex, max(visibleGroups.count - 1, 0))
    }

    func goNext() {
        guard !visibleGroups.isEmpty else { return }
        currentIndex = min(currentIndex + 1, visibleGroups.count - 1)
    }

    func goPrevious() {
        guard !visibleGroups.isEmpty else { return }
        currentIndex = max(currentIndex - 1, 0)
    }

    func setFilter(_ filter: ViewFilter) {
        viewFilter = filter
        currentIndex = 0
        statusText = "当前只看：\(filter.label)，共 \(visibleGroups.count) 组。"
    }

    func exportRatings(only ratingFilter: Rating? = nil) {
        guard let sourceDirectory else {
            statusText = "还没有选择照片文件夹。"
            return
        }

        let selectedGroups = groups.filter { group in
            guard let rating = group.rating else { return false }
            return ratingFilter == nil || rating == ratingFilter
        }

        guard !selectedGroups.isEmpty else {
            statusText = ratingFilter.map { "没有可整理的 \($0.label)。" } ?? "还没有任何照片被分类。"
            return
        }

        do {
            let outputName = "_筛选结果_\(Self.timestamp())"
            let outputURL = sourceDirectory.appendingPathComponent(outputName, isDirectory: true)
            let fileManager = FileManager.default
            try fileManager.createDirectory(at: outputURL, withIntermediateDirectories: true)

            for rating in Rating.allCases {
                try fileManager.createDirectory(
                    at: outputURL.appendingPathComponent(rating.folderName, isDirectory: true),
                    withIntermediateDirectories: true
                )
            }

            var copied = 0
            for group in selectedGroups {
                guard let rating = group.rating else { continue }
                let targetFolder = outputURL.appendingPathComponent(rating.folderName, isDirectory: true)

                for file in group.files {
                    let target = targetFolder.appendingPathComponent(Self.uniqueOutputName(file.relativePath))
                    if fileManager.fileExists(atPath: target.path) {
                        try fileManager.removeItem(at: target)
                    }
                    try fileManager.copyItem(at: file.url, to: target)
                    copied += 1
                }
            }

            try buildCSV().write(
                to: outputURL.appendingPathComponent("筛选清单.csv"),
                atomically: true,
                encoding: .utf8
            )

            statusText = "已整理 \(copied) 个文件到 \(outputName)。原图保留不动。"
        } catch {
            statusText = "整理失败：\(error.localizedDescription)"
        }
    }

    func deleteBadGroupsToTrash() {
        let badGroups = groups.filter { $0.rating == .bad }
        guard !badGroups.isEmpty else {
            statusText = "没有 3 烂片可删除。"
            return
        }

        let alert = NSAlert()
        alert.messageText = "删除 3 烂片原文件？"
        alert.informativeText = "将把 \(badGroups.count) 组文件送到废纸篓，包含同名 JPEG/RAW/XMP。"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "送到废纸篓")
        alert.addButton(withTitle: "取消")

        guard alert.runModal() == .alertFirstButtonReturn else { return }

        var deletedGroupIDs = Set<UUID>()
        var deletedFiles = 0
        var failed = 0
        let fileManager = FileManager.default

        for group in badGroups {
            var groupFailed = false
            for file in group.files {
                do {
                    var trashedURL: NSURL?
                    try fileManager.trashItem(at: file.url, resultingItemURL: &trashedURL)
                    deletedFiles += 1
                } catch {
                    groupFailed = true
                    failed += 1
                }
            }
            if !groupFailed {
                deletedGroupIDs.insert(group.id)
            }
        }

        groups.removeAll { deletedGroupIDs.contains($0.id) }
        currentIndex = min(currentIndex, max(visibleGroups.count - 1, 0))
        statusText = "已将 \(deletedGroupIDs.count) 组、\(deletedFiles) 个文件送到废纸篓。\(failed > 0 ? "\(failed) 个失败。" : "")"
    }

    private func directoryForSelection(_ url: URL) throws -> URL {
        let resourceValues = try url.resourceValues(forKeys: [.isDirectoryKey])
        return resourceValues.isDirectory == true ? url : url.deletingLastPathComponent()
    }

    private func scan(directory: URL) throws -> [PhotoGroup] {
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey, .isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        var files: [PhotoFile] = []

        for case let url as URL in enumerator {
            if url.lastPathComponent.hasPrefix("_筛选结果") {
                enumerator.skipDescendants()
                continue
            }

            let resourceValues = try url.resourceValues(forKeys: [.isRegularFileKey])
            guard resourceValues.isRegularFile == true else { continue }

            let ext = url.pathExtension.lowercased()
            guard previewExtensions.contains(ext) || rawExtensions.contains(ext) || sidecarExtensions.contains(ext) else {
                continue
            }

            let relativePath = url.path.replacingOccurrences(of: directory.path + "/", with: "")
            files.append(PhotoFile(url: url, relativePath: relativePath, kind: kind(for: ext)))
        }

        return buildGroups(from: files)
            .sorted { $0.relativePath.localizedStandardCompare($1.relativePath) == .orderedAscending }
    }

    private func buildGroups(from files: [PhotoFile]) -> [PhotoGroup] {
        let grouped = Dictionary(grouping: files) { file in
            let directory = (file.relativePath as NSString).deletingLastPathComponent.lowercased()
            let basename = ((file.relativePath as NSString).lastPathComponent as NSString).deletingPathExtension.lowercased()
            return "\(directory)\u{0}\(basename)"
        }

        return grouped.values.compactMap { groupFiles in
            guard let preview = choosePreview(from: groupFiles) else { return nil }
            let sortedFiles = groupFiles.sorted { lhs, rhs in
                if lhs.id == preview.id { return true }
                if rhs.id == preview.id { return false }
                return lhs.relativePath.localizedStandardCompare(rhs.relativePath) == .orderedAscending
            }
            return PhotoGroup(id: UUID(), preview: preview, files: sortedFiles)
        }
    }

    private func choosePreview(from files: [PhotoFile]) -> PhotoFile? {
        files.first { $0.kind == .jpeg } ?? files.first { $0.kind == .preview }
    }

    private func kind(for ext: String) -> PhotoFileKind {
        if jpegExtensions.contains(ext) { return .jpeg }
        if rawExtensions.contains(ext) { return .raw }
        if sidecarExtensions.contains(ext) { return .xmp }
        if previewExtensions.contains(ext) { return .preview }
        return .file
    }

    private func buildCSV() -> String {
        var rows: [[String]] = [["预览文件", "组内文件", "分类", "类型"]]

        for group in groups {
            for file in group.files {
                rows.append([
                    group.displayName,
                    file.relativePath,
                    group.rating?.csvLabel ?? "未筛",
                    file.kind.rawValue
                ])
            }
        }

        return rows.map { row in row.map(Self.escapeCSV).joined(separator: ",") }.joined(separator: "\n")
    }

    nonisolated private static func escapeCSV(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }

    nonisolated private static func uniqueOutputName(_ relativePath: String) -> String {
        relativePath.replacingOccurrences(of: "/", with: "__")
    }

    nonisolated private static func timestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddHHmmssSSS"
        return formatter.string(from: Date())
    }
}
