import SwiftUI

struct SidebarView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 5) {
                Text("本地照片筛选")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                Text("拾影")
                    .font(.system(size: 30, weight: .semibold))
            }

            HStack(spacing: 8) {
                Button {
                    appState.chooseFolder()
                } label: {
                    Label("选择文件", systemImage: "folder.badge.plus")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut("o", modifiers: .command)

                Text("⌘O")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(.quaternary, in: Capsule())
            }

            StatsGrid(appState: appState)

            VStack(alignment: .leading, spacing: 8) {
                Text("分类")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)

                Picker("", selection: Binding<Rating?>(
                    get: { appState.currentGroup?.rating },
                    set: { rating in
                        if let rating {
                            appState.setRating(rating)
                        }
                    }
                )) {
                    Text("1 好片").tag(Optional(Rating.good))
                    Text("2 待定").tag(Optional(Rating.maybe))
                    Text("3 烂片").tag(Optional(Rating.bad))
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .disabled(appState.currentGroup == nil)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("查看")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)

                Picker("查看", selection: Binding(
                    get: { appState.viewFilter },
                    set: { appState.setFilter($0) }
                )) {
                    ForEach(ViewFilter.allCases) { filter in
                        Text(filter.label).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            VStack(spacing: 9) {
                ActionButton(title: "整理到分类文件夹", systemImage: "tray.and.arrow.down.fill", isProminent: true, isEnabled: appState.counts.rated > 0) {
                    appState.exportRatings()
                }
                ActionButton(title: "只整理 1 好片", systemImage: "checkmark.circle", isEnabled: appState.counts.good > 0) {
                    appState.exportRatings(only: .good)
                }
                ActionButton(title: "只整理 2 待定", systemImage: "clock", isEnabled: appState.counts.maybe > 0) {
                    appState.exportRatings(only: .maybe)
                }
                ActionButton(title: "删除 3 烂片原文件", systemImage: "trash", isDestructive: true, isEnabled: appState.counts.bad > 0) {
                    appState.deleteBadGroupsToTrash()
                }
            }

            Text(appState.statusText)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
        .padding(24)
    }
}

struct StatsGrid: View {
    @ObservedObject var appState: AppState

    var body: some View {
        let counts = appState.counts
        Grid(horizontalSpacing: 10, verticalSpacing: 10) {
            GridRow {
                StatCard(title: "1 好片", value: counts.good)
                StatCard(title: "2 待定", value: counts.maybe)
            }
            GridRow {
                StatCard(title: "3 烂片", value: counts.bad)
                StatCard(title: "未筛", value: counts.unrated)
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
            Text("\(value)")
                .font(.system(size: 32, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.78), in: RoundedRectangle(cornerRadius: 15))
        .overlay {
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color(nsColor: .separatorColor).opacity(0.28), lineWidth: 0.5)
        }
        .shadow(color: .black.opacity(0.035), radius: 8, x: 0, y: 3)
    }
}

struct ActionButton: View {
    let title: String
    let systemImage: String
    var isProminent = false
    var isDestructive = false
    let isEnabled: Bool
    let action: () -> Void

    @ViewBuilder
    var body: some View {
        if isProminent {
            baseButton
                .buttonStyle(.borderedProminent)
                .tint(.accentColor)
                .modifier(ActionButtonState(isDestructive: isDestructive, isEnabled: isEnabled))
        } else {
            baseButton
                .buttonStyle(.bordered)
                .tint(isDestructive ? Color.red.opacity(isEnabled ? 0.18 : 0.08) : nil)
                .modifier(ActionButtonState(isDestructive: isDestructive, isEnabled: isEnabled))
        }
    }

    private var baseButton: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 13, weight: .medium))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .controlSize(.regular)
    }
}

struct ActionButtonState: ViewModifier {
    let isDestructive: Bool
    let isEnabled: Bool

    func body(content: Content) -> some View {
        content
            .foregroundStyle(isDestructive && isEnabled ? .red : .primary)
            .disabled(!isEnabled)
            .opacity(isEnabled ? 1 : 0.48)
    }
}

#Preview("左侧栏 - 有数据") {
    SidebarView(appState: PreviewFixtures.sampleState())
        .frame(width: 300, height: 680)
        .background(.ultraThinMaterial)
}

#Preview("左侧栏 - 空状态") {
    SidebarView(appState: PreviewFixtures.emptyState())
        .frame(width: 300, height: 680)
        .background(.ultraThinMaterial)
}
