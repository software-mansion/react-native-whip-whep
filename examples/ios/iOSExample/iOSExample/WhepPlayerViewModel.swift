import Foundation
import MobileWhepClient
import WebRTC

class WhepPlayerViewModel: ObservableObject, PlayerListener {
    @Published var videoTrack: RTCVideoTrack?
    
    var player: WhepClient?

    init(player: WhepClient) {
        self.player = player
        player.delegate = self
    }
    
    func onTrackAdded(track: RTCVideoTrack) {
        videoTrack = track
    }
    
    func onTrackRemoved(track: RTCVideoTrack) {
        if videoTrack == track {
            videoTrack = nil
        }
    }
    
    func connect() async throws {
        try await player?.connect()
    }
    
    func disconnect() {
        player?.disconnect()
    }
}

