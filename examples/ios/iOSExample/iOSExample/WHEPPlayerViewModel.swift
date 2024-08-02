import Foundation
import MobileWhepClient
import WebRTC

class WHEPPlayerViewModel: ObservableObject, WHEPPlayerListener {
    @Published var videoTrack: RTCVideoTrack?
    @Published var isConnected: Bool = false
    
    var player: WHEPClientPlayer?

    init(player: WHEPClientPlayer) {
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
    
    func onConnectionStatusChanged(isConnected: Bool) {
        self.isConnected = isConnected
    }
    
    func connect() async throws {
        try await player?.connect()
    }
}

