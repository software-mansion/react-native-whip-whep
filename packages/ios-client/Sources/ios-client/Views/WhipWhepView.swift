import Foundation
import SwiftUI
import WebRTC

public class WhipWhepViewModel: ObservableObject, PlayerListener {
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

public struct WhipWhepView: UIViewRepresentable {
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
