//import UIKit
//import WebRTC
//
//class ViewController: UIViewController {
//
//    var peerConnection: RTCPeerConnection?
//    var whepClient: WHEPClient?
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        
//        setupPeerConnection()
//        Task {
//            await setupWHEPClient()
//        }
//    }
//    
//    func setupPeerConnection() {
//        let configuration = RTCConfiguration()
//        configuration.bundlePolicy = .maxBundle
//        
//        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
//        let defaultPeerConnectionFactory = RTCPeerConnectionFactory()
//        
//        peerConnection = defaultPeerConnectionFactory.peerConnection(with: configuration, constraints: constraints, delegate: nil)
//        
//        peerConnection?.addTransceiver(of: .audio)
//        peerConnection?.addTransceiver(of: .video)
//        
//        peerConnection?.delegate = self
//    }
//    
//    func setupWHEPClient() async {
//        let url = URL(string: "http://192.168.83.130:8829/whep")
//        let token = "example"
//        
//        whepClient = WHEPClient()
//        try! await whepClient?.view(pc: peerConnection!, url: url!, token: token)
//    }
//}
//
//extension ViewController: RTCPeerConnectionDelegate {
//    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
//        
//    }
//    
//    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
//        
//    }
//    
//    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
//        
//    }
//    
//    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
//        
//    }
//    
//    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
//        
//    }
//    
//    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
//        
//    }
//    
//    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
//        
//    }
//    
//    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
//        
//    }
//    
//    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
//        DispatchQueue.main.async {
//            if let videoTrack = stream.videoTracks.first {
//                if let videoView = self.view.viewWithTag(100) as? RTCEAGLVideoView { // assuming there's a view with tag 100
//                    videoTrack.add(videoView)
//                }
//            }
//        }
//    }
//}
