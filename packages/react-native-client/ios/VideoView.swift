import UIKit
import AVFoundation
import MobileWhepClient
import WebRTC

public class VideoView: UIView {
    public var player: ClientBase?
    private var videoView: RTCMTLVideoView?

    public init(player: ClientBase?) {
        self.player = player
        super.init(frame: .zero)
        setupView()
        player?.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        let view = RTCMTLVideoView(frame: .zero)
        view.videoContentMode = .scaleAspectFit
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: self.topAnchor),
            view.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            view.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ])
        self.videoView = view
        updateVideoTrack()
    }

    public func updateVideoTrack() {
        DispatchQueue.main.async {
            if let track = self.player?.videoTrack {
                track.add(self.videoView!)
            }
        }
    }

    deinit {
        dismantleView()
    }

    private func dismantleView() {
        if let track = self.player?.videoTrack {
            track.remove(self.videoView!)
        }
        videoView?.removeFromSuperview()
    }
}

extension VideoView: PlayerListener {
    public func onTrackAdded(track: RTCVideoTrack) {
        DispatchQueue.main.async {
            if let videoView = self.videoView {
                track.add(videoView)
            }
        }
    }

    public func onTrackRemoved(track: RTCVideoTrack) {
        DispatchQueue.main.async {
            if let videoView = self.videoView {
                track.remove(videoView)
            }
        }
    }
}
