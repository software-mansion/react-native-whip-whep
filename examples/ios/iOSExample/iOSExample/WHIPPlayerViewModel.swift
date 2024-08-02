import Foundation
import MobileWhepClient
import WebRTC

class WHIPPlayerViewModel: ObservableObject, WHIPPlayerListener {
    @Published var videoTrack: RTCVideoTrack?
    @Published var isConnected: Bool = false
    
    var player: WHIPClientPlayer?

    init(player: WHIPClientPlayer) {
        self.player = player
        player.delegate = self
    }
    
    func onTrackAdded(track: RTCVideoTrack) {
        videoTrack = track
    }
    
    func onConnectionStatusChanged(isConnected: Bool) {
        self.isConnected = isConnected
    }
    
    func connect() async throws {
        try await player?.connect()
    }
}
