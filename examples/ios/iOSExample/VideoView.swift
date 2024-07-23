//import SwiftUI
//import UIKit
//import WebRTC
//
//struct VideoView: UIViewRepresentable {
//    var videoTrack: RTCVideoTrack?
//
//    func makeUIView(context: Context) -> RTCEAGLVideoView {
//        let view = RTCEAGLVideoView()
//        view.delegate = context.coordinator as! any RTCVideoViewDelegate
//        return view
//    }
//
//    func updateUIView(_ uiView: RTCEAGLVideoView, context: Context) {
//        videoTrack?.add(uiView)
//    }
//
//    func makeCoordinator() -> Coordinator {
//        Coordinator(self)
//    }
//
//    class Coordinator: NSObject, RTCVideoViewDelegate {
//        func videoView(_ videoView: RTCVideoRenderer, didChangeVideoSize size: CGSize) {
//            
//        }
//        
//        var parent: VideoView
//
//        init(_ videoView: VideoView) {
//            self.parent = videoView
//        }
//    }
//}
