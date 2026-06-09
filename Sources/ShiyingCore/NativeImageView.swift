import AppKit
import SwiftUI

struct NativeImageView: NSViewRepresentable {
    let image: NSImage

    func makeNSView(context: Context) -> NSScrollView {
        let imageView = NSImageView()
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.imageAlignment = .alignCenter
        imageView.image = image

        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.hasHorizontalScroller = false
        scrollView.hasVerticalScroller = false
        scrollView.allowsMagnification = true
        scrollView.minMagnification = 1
        scrollView.maxMagnification = 8
        scrollView.autohidesScrollers = true
        scrollView.documentView = imageView
        context.coordinator.imageView = imageView
        context.coordinator.scrollView = scrollView

        DispatchQueue.main.async {
            fit(imageView: imageView, in: scrollView)
        }

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.imageView?.image = image
        DispatchQueue.main.async {
            if let imageView = context.coordinator.imageView {
                fit(imageView: imageView, in: scrollView)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    private func fit(imageView: NSImageView, in scrollView: NSScrollView) {
        let clipSize = scrollView.contentView.bounds.size
        guard clipSize.width > 0, clipSize.height > 0 else { return }
        imageView.frame = NSRect(origin: .zero, size: clipSize)
        scrollView.magnification = 1
    }

    final class Coordinator {
        weak var imageView: NSImageView?
        weak var scrollView: NSScrollView?
    }
}
