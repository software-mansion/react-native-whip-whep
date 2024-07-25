import SwiftUI
import AVFoundation
import WebRTC

struct CameraPreview: UIViewRepresentable {
    var videoTrack: RTCVideoTrack?

    func makeUIView(context: Context) -> RTCMTLVideoView {
        let view = RTCMTLVideoView(frame: .zero)
        view.videoContentMode = .scaleAspectFit
        return view
    }

    func updateUIView(_ uiView: RTCMTLVideoView, context: Context) {
        if let track = videoTrack {
            track.add(uiView)
        }
    }

    static func dismantleUIView(_ uiView: RTCMTLVideoView, coordinator: ()) {
        uiView.removeFromSuperview()
    }
}
