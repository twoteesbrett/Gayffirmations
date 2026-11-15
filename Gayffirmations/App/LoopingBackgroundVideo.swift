import AVFoundation
import SwiftUI
import UIKit

private struct AnimatesThemeBackgroundKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var animatesThemeBackground: Bool {
        get { self[AnimatesThemeBackgroundKey.self] }
        set { self[AnimatesThemeBackgroundKey.self] = newValue }
    }
}

struct LoopingBackgroundVideo: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PlayerView {
        let view = PlayerView()
        view.play(url)
        return view
    }

    func updateUIView(_ uiView: PlayerView, context: Context) {}

    static func dismantleUIView(_ uiView: PlayerView, coordinator: ()) {
        uiView.stop()
    }

    final class PlayerView: UIView {
        override class var layerClass: AnyClass { AVPlayerLayer.self }

        private var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
        private let player = AVQueuePlayer()
        private var looper: AVPlayerLooper?
        private var readiness: NSKeyValueObservation?

        func play(_ url: URL) {
            player.isMuted = true
            playerLayer.videoGravity = .resizeAspectFill
            playerLayer.opacity = 0
            playerLayer.player = player
            readiness = playerLayer.observe(\.isReadyForDisplay, options: [.initial, .new]) { [weak self] layer, _ in
                let ready = layer.isReadyForDisplay
                DispatchQueue.main.async { [weak self] in
                    self?.playerLayer.opacity = ready ? 1 : 0
                }
            }
            looper = AVPlayerLooper(player: player, templateItem: AVPlayerItem(url: url))
            player.play()
        }

        func stop() {
            readiness?.invalidate()
            readiness = nil
            player.pause()
            looper = nil
            player.removeAllItems()
            playerLayer.player = nil
        }
    }
}
