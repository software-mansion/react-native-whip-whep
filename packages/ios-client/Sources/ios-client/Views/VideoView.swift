import Foundation
import SwiftUI
import WebRTC

public class VideoViewModel: ObservableObject, PlayerListener {
    @Published public var videoTrack: RTCVideoTrack?

    public var player: Connectable & ClientBase

    public init(player: Connectable & ClientBase) {
        self.player = player
        player.delegate = self
    }

    public func onTrackAdded(track: RTCVideoTrack) {
        videoTrack = track
    }

    public func onTrackRemoved(track: RTCVideoTrack) {
        if videoTrack == track {
            videoTrack = nil
        }
    }

    public func connect() async throws {
        try await player.connect()
    }

    public func disconnect() {
        player.disconnect()
    }
}

public struct VideoView: UIViewRepresentable {
    public var videoTrack: RTCVideoTrack?

    public init(videoTrack: RTCVideoTrack?) {
        self.videoTrack = videoTrack
    }

    public func makeUIView(context: Context) -> RTCMTLVideoView {
        let view = RTCMTLVideoView(frame: .zero)
        view.videoContentMode = .scaleAspectFit
        return view
    }

    public func updateUIView(_ uiView: RTCMTLVideoView, context: Context) {
        if let track = videoTrack {
            track.add(uiView)
        }
    }

    public static func dismantleUIView(_ uiView: RTCMTLVideoView, coordinator: ()) {
        uiView.removeFromSuperview()
    }
}

public class VideoViewController: UIViewController {

    private var videoTrack: RTCVideoTrack?

    private lazy var videoView: RTCMTLVideoView = {
        let videoView = RTCMTLVideoView(frame: .zero)
        videoView.videoContentMode = .scaleAspectFit
        return videoView
    }()

    public init(videoTrack: RTCVideoTrack?) {
        self.videoTrack = videoTrack
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

        if let track = videoTrack {
            track.add(videoView)
        }
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if let track = videoTrack {
            track.remove(videoView)
        }
    }
}
