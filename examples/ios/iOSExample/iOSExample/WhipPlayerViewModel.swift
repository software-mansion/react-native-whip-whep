import Foundation
import MobileWhepClient
import WebRTC

class WhipPlayerViewModel: ObservableObject, PlayerListener {
    @Published var videoTrack: RTCVideoTrack?
    
    var player: WhipClientPlayer?

    init(player: WhipClientPlayer) {
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
