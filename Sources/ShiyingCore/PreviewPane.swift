import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct PreviewPane: View {
    @ObservedObject var appState: AppState
    @State private var image: NSImage?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(positionText)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Text(appState.currentGroup?.displayName ?? "还没有照片")
                        .font(.system(size: 15, weight: .semibold))
                    if let summary = appState.currentGroup?.sidecarSummary, !summary.isEmpty {
                        Text(summary)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                HStack(spacing: 8) {
                    Button {
                        appState.goPrevious()
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .disabled(appState.currentIndex <= 0)

                    Button {
                        appState.goNext()
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                    .disabled(appState.visibleGroups.isEmpty || appState.currentIndex >= appState.visibleGroups.count - 1)

                    Menu {
                        ForEach(ViewFilter.allCases) { filter in
                            Button(filter.label) {
                                appState.setFilter(filter)
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }

                    if let rating = appState.currentGroup?.rating {
                        Text(rating.label)
                            .font(.system(size: 12, weight: .semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.quaternary, in: Capsule())
                            .foregroundStyle(.primary)
                    }
                }
                .buttonStyle(.borderless)
                .controlSize(.regular)
            }
            .padding(.horizontal, 26)
            .padding(.vertical, 13)
            .background(.thinMaterial)

            Divider()

            ZStack {
                Color(nsColor: .underPageBackgroundColor)
                    .opacity(0.72)

                if let image {
                    NativeImageView(image: image)
                        .id(appState.currentGroup?.id)
                } else {
                    EmptyPreviewCard()
                }
            }
            .onDrop(of: [UTType.fileURL.identifier], isTargeted: nil) { providers in
                handleDrop(providers)
            }
        }
        .onChange(of: appState.currentGroup?.id) {
            loadImage()
        }
        .onAppear {
            loadImage()
        }
    }

    private var positionText: String {
        let total = appState.visibleGroups.count
        guard total > 0 else { return "0 / 0" }
        return "\(appState.currentIndex + 1) / \(total)"
    }

    private func loadImage() {
        guard let group = appState.currentGroup else {
            image = nil
            return
        }
        image = NSImage(contentsOf: group.preview.url)
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) }) else {
            return false
        }

        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
            let droppedURL: URL?
            if let url = item as? URL {
                droppedURL = url
            } else if let data = item as? Data {
                droppedURL = URL(dataRepresentation: data, relativeTo: nil)
            } else {
                droppedURL = nil
            }

            if let droppedURL {
                DispatchQueue.main.async {
                    appState.loadSelection(from: droppedURL)
                }
            }
        }

        return true
    }
}

struct EmptyPreviewCard: View {
    var body: some View {
        VStack(spacing: 15) {
            ZStack {
                Circle()
                    .fill(.quaternary)
                    .frame(width: 58, height: 58)
                Image(systemName: "photo.stack")
                    .font(.system(size: 28, weight: .regular))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 6) {
                Text("拖入照片或选择文件开始筛选")
                    .font(.system(size: 18, weight: .semibold))
                Text("支持 JPEG，同名 RAW / XMP 会自动跟随")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 34)
        .padding(.vertical, 30)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.82), in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color(nsColor: .separatorColor).opacity(0.25), lineWidth: 0.5)
        }
        .shadow(color: .black.opacity(0.045), radius: 16, x: 0, y: 6)
    }
}

#Preview("右侧预览 - 有数据") {
    PreviewPane(appState: PreviewFixtures.sampleState())
        .frame(width: 760, height: 680)
}

#Preview("右侧预览 - 空状态") {
    PreviewPane(appState: PreviewFixtures.emptyState())
        .frame(width: 760, height: 680)
}

#Preview("空状态卡片") {
    EmptyPreviewCard()
        .frame(width: 520, height: 320)
}
