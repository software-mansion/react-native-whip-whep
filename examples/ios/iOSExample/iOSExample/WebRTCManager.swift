import Foundation
import AVFoundation
import WebRTC

class WebRTCManager: NSObject {
    
    var peerConnection: RTCPeerConnection?
    private var captureSession: AVCaptureSession
    private let peerConnectionFactory: RTCPeerConnectionFactory
    
    override init() {
        peerConnectionFactory = RTCPeerConnectionFactory()
        captureSession = AVCaptureSession()
        super.init()
        configurePeerConnection()
    }
    
    private func configurePeerConnection() {
        let configuration = RTCConfiguration()
        configuration.bundlePolicy = .maxBundle
        configuration.iceServers = [RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"])]
        peerConnection = peerConnectionFactory.peerConnection(with: configuration, constraints: RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil), delegate: nil)
    }
    
    func createAudioTrack() -> RTCAudioTrack? {
        let audioSource = peerConnectionFactory.audioSource(with: nil)
        return peerConnectionFactory.audioTrack(with: audioSource, trackId: "audioTrack0")
    }

    func createVideoTrack() -> RTCVideoTrack? {
        let videoSource = peerConnectionFactory.videoSource()
        // Tu konfiguracja capturera dla videoSource, jak wcześniej
        return peerConnectionFactory.videoTrack(with: videoSource, trackId: "videoTrack0")
    }
    
    func setupMediaStream(type: AVMediaType) {
        let deviceTypes: [AVCaptureDevice.DeviceType] = [.microphone, .builtInWideAngleCamera]
        let session = AVCaptureDevice.DiscoverySession(deviceTypes: deviceTypes, mediaType: type, position: .unspecified)
        
        guard let device = session.devices.first else {
            print("Device not found for the media type \(type.rawValue)")
            return
        }
        
        do {
            let deviceInput = try AVCaptureDeviceInput(device: device)
            if captureSession.canAddInput(deviceInput) {
                captureSession.addInput(deviceInput)
                
                if type == .video {
                    let videoSource = peerConnectionFactory.videoSource()
                    let videoTrack = peerConnectionFactory.videoTrack(with: videoSource, trackId: "videoTrack0")
                    let transceiver = peerConnection?.addTransceiver(with: videoTrack)
                } else if type == .audio {
                    let audioSource = peerConnectionFactory.audioSource(with: nil)
                    let audioTrack = peerConnectionFactory.audioTrack(with: audioSource, trackId: "audioTrack0")
                    _ = peerConnection?.addTransceiver(with: audioTrack)
                }
            } else {
                print("Cannot add input to session")
            }
        } catch {
            print("Failed to create device input: \(error.localizedDescription)")
        }
    }
    
    func startStream() {
        setupMediaStream(type: .audio)
        setupMediaStream(type: .video)
        
        // Uruchomienie sesji przechwytywania
        captureSession.startRunning()
    }
}
