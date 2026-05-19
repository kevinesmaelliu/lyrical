import SwiftUI

struct LyricsWindowView: View {
    @ObservedObject var viewModel: PlayerViewModel

    private var windowSize: CGSize {
        let size = LyricsWindowMetrics.size(
            widthScale: viewModel.windowWidthScale,
            heightScale: viewModel.windowHeightScale
        )
        return CGSize(width: size.width, height: size.height)
    }

    var body: some View {
        ZStack {
            VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)
                .ignoresSafeArea()

            lyricsBody
                .padding(.horizontal, 14 * viewModel.windowWidthScale)
                .padding(.vertical, 10 * viewModel.windowHeightScale)
        }
        .clipShape(RoundedRectangle(cornerRadius: LyricsWindowMetrics.cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: LyricsWindowMetrics.cornerRadius, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        }
        .frame(width: windowSize.width, height: windowSize.height)
    }

    @ViewBuilder
    private var lyricsBody: some View {
        if !viewModel.auth.isAuthenticated {
            statusText(viewModel.statusMessage)
        } else if viewModel.nowPlaying == nil {
            statusText(viewModel.statusMessage)
        } else if viewModel.lyricLines.isEmpty {
            statusText(viewModel.statusMessage.isEmpty ? "…" : viewModel.statusMessage)
        } else {
            CompactSyncedLyricsView(
                lines: viewModel.lyricLines,
                activeIndex: viewModel.activeLineIndex,
                fontSize: viewModel.fontSize,
                linesBefore: viewModel.contextLinesBefore,
                linesAfter: viewModel.contextLinesAfter
            )
        }
    }

    private func statusText(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Shows the current line with configurable previous/next context — no scrolling chrome.
struct CompactSyncedLyricsView: View {
    let lines: [LyricLine]
    let activeIndex: Int?
    let fontSize: Double
    let linesBefore: Int
    let linesAfter: Int

    var body: some View {
        VStack(spacing: 4) {
            if let activeIndex, activeIndex < lines.count {
                let beforeStart = max(0, activeIndex - linesBefore)
                ForEach(beforeStart..<activeIndex, id: \.self) { index in
                    contextLine(lines[index].text, distance: activeIndex - index)
                }

                Text(lines[activeIndex].text)
                    .font(.system(size: fontSize, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
                    .multilineTextAlignment(.center)
                    .animation(.easeInOut(duration: 0.2), value: activeIndex)

                let afterEnd = min(lines.count, activeIndex + 1 + linesAfter)
                ForEach((activeIndex + 1)..<afterEnd, id: \.self) { index in
                    contextLine(lines[index].text, distance: index - activeIndex)
                }
            } else if let first = lines.first {
                Text(first.text)
                    .font(.system(size: fontSize, weight: .medium))
                    .foregroundStyle(.primary.opacity(0.6))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func contextLine(_ text: String, distance: Int) -> some View {
        Text(text)
            .font(.system(size: fontSize * 0.72, weight: .regular))
            .foregroundStyle(.primary.opacity(contextOpacity(distance: distance)))
            .lineLimit(1)
            .multilineTextAlignment(.center)
    }

    private func contextOpacity(distance: Int) -> Double {
        max(0.12, 0.38 - Double(distance) * 0.08)
    }
}

struct ArtworkView: View {
    let url: URL?

    var body: some View {
        Group {
            if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(Color.primary.opacity(0.08))
            .overlay {
                Image(systemName: "music.note")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
    }
}

struct VisualEffectBlur: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        view.wantsLayer = true
        view.layer?.cornerRadius = LyricsWindowMetrics.cornerRadius
        view.layer?.masksToBounds = true
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.layer?.cornerRadius = LyricsWindowMetrics.cornerRadius
    }
}
