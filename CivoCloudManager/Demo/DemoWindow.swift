import SwiftUI

extension View {
    /// Demo mode only: sizes the window for the store capture and exposes the demo traffic counters.
    /// Without demo mode the view is returned unchanged.
    @ViewBuilder
    func demoCaptureSupport() -> some View {
        #if DEBUG
        if DemoMode.isActive {
            modifier(DemoCaptureSupport())
        } else {
            self
        }
        #else
        self
        #endif
    }
}

extension DemoMode {
    /// Demo mode only: shows the app as a regular, light, frontmost application with the demo protocol registered.
    @MainActor
    static func presentAsRegularApp() {
        #if DEBUG
        guard isActive else { return }
        DemoURLProtocol.registerGlobally()
        NSApp.setActivationPolicy(.regular)
        NSApp.appearance = NSAppearance(named: .aqua)
        NSApp.activate()
        #endif
    }
}

#if DEBUG
private struct DemoCaptureSupport: ViewModifier {
    /// The size of the captured window in points: 2880 x 1800 px on a 2x display.
    static let windowSize = CGSize(width: 1440, height: 900)

    func body(content: Content) -> some View {
        content
            .background(DemoWindowFrame(size: Self.windowSize))
            .overlay(alignment: .topLeading) {
                // A zero-content element: it draws nothing and only carries the counters for the UI test.
                TimelineView(.periodic(from: .now, by: 0.5)) { _ in
                    Color.clear
                        .frame(width: 1, height: 1)
                        .accessibilityElement()
                        .accessibilityIdentifier("demo.status")
                        .accessibilityValue(DemoTraffic.shared.summary)
                }
            }
    }
}

/// Places the window at an exact size on a 2x display that can hold it, so the capture is 2880 x 1800 px.
private struct DemoWindowFrame: NSViewRepresentable {
    let size: CGSize

    func makeNSView(context: Context) -> NSView { FrameView(size: size) }

    func updateNSView(_ nsView: NSView, context: Context) {}

    private final class FrameView: NSView {
        let size: CGSize

        init(size: CGSize) {
            self.size = size
            super.init(frame: .zero)
        }

        required init?(coder: NSCoder) { nil }

        override func viewDidMoveToWindow() {
            guard let window, let screen = Self.qualifyingScreen(for: size) else { return }
            window.isRestorable = false
            let area = screen.visibleFrame
            let origin = CGPoint(x: area.midX - size.width / 2, y: area.maxY - size.height)
            window.setFrame(CGRect(origin: origin, size: size), display: true)
        }

        private static func qualifyingScreen(for size: CGSize) -> NSScreen? {
            NSScreen.screens.first { screen in
                screen.backingScaleFactor == 2
                    && screen.visibleFrame.width >= size.width && screen.visibleFrame.height >= size.height
            }
        }
    }
}
#endif
