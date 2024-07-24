import SwiftUI
import WebRTC

struct WebRTCVideoView: UIViewRepresentable {
    var videoTrack: RTCVideoTrack

    func makeUIView(context: Context) -> RTCMTLVideoView {
        let view = RTCMTLVideoView()
        view.contentMode = .scaleAspectFill
        videoTrack.add(view)
        return view
    }

    func updateUIView(_ uiView: RTCMTLVideoView, context: Context) {
        // Miejsce na aktualizacje, jeśli będą potrzebne
    }
}
