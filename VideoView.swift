import Foundation
import SwiftUI
import UIKit
import WebRTC

public struct VideoView: UIViewRepresentable {
    public var player: ClientBase

    public init(player: ClientBase) {
        self.player = player
    }

    public func makeUIView(context: Context) -> RTCMTLVideoView {
        let view = RTCMTLVideoView(frame: .zero)
        view.videoContentMode = .scaleAspectFit
        player.delegate = context.coordinator
        context.coordinator.videoView = view
        return view
    }

    public func updateUIView(_ uiView: RTCMTLVideoView, context: Context) {
        DispatchQueue.main.async {
            if let track = player.videoTrack {
                track.add(uiView)
            }
        }

    }

    public static func dismantleUIView(_ uiView: RTCMTLVideoView, coordinator: Coordinator) {
        if let track = coordinator.videoTrack {
            track.remove(uiView)
        }
        uiView.removeFromSuperview()
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public class Coordinator: NSObject, PlayerListener {
        var parent: VideoView
        var videoTrack: RTCVideoTrack?
        var videoView: RTCMTLVideoView?

        init(_ parent: VideoView) {
            self.parent = parent
        }

        public func onTrackAdded(track: RTCVideoTrack) {
            DispatchQueue.main.async {
                self.videoTrack = track
                if let videoView = self.videoView {
                    self.videoTrack?.add(videoView)
                }
            }
        }

        public func onTrackRemoved(track: RTCVideoTrack) {
            DispatchQueue.main.async {
                if self.videoTrack == track {
                    if let videoView = self.videoView {
                        track.remove(videoView)
                    }
                    self.videoTrack = nil
                }
            }
        }
    }
}

public class VideoViewController: UIViewController {

    private var player: ClientBase

    private lazy var videoView: RTCMTLVideoView = {
        let videoView = RTCMTLVideoView(frame: .zero)
        videoView.videoContentMode = .scaleAspectFit
        return videoView
    }()

    public init(player: ClientBase) {
        self.player = player
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(videoView)
        videoView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            videoView.topAnchor.constraint(equalTo: view.topAnchor),
            videoView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            videoView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            videoView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        player.delegate = self

        if let track = player.videoTrack {
            track.add(videoView)
        }
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if let track = player.videoTrack {
            track.remove(videoView)
        }
    }
}

extension VideoViewController: PlayerListener {
    public func onTrackAdded(track: RTCVideoTrack) {
        track.add(videoView)
    }

    public func onTrackRemoved(track: RTCVideoTrack) {
        track.remove(videoView)
    }
}
