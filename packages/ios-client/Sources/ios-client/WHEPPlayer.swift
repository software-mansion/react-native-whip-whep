import WebRTC

protocol WHEPPlayerListener: AnyObject {
    func onTrackAdded(track: RTCVideoTrack)
}

protocol WHEPPlayer {
    var patchEndpoint: String? {get set}
    var peerConnectionFactory: RTCPeerConnectionFactory? {get set}
    var peerConnection: RTCPeerConnection? {get set}
    var iceCandidates: [RTCIceCandidate] {get set}
    var videoTrack: RTCVideoTrack? {get set}
    var delegate: WHEPPlayerListener? {get set}
    
    func sendSdpOffer(sdpOffer: String) async throws -> String
    func sendCandidate(candidate: RTCIceCandidate) async throws
    func connect() async throws
    func release(peerConnection: RTCPeerConnection)
}


@available(macOS 12.0, *)
public class WHEPClientPlayer: NSObject, WHEPPlayer, RTCPeerConnectionDelegate {
    var serverUrl: URL
    var authToken: String?
    var configurationOptions: ConfigurationOptions?
    var patchEndpoint: String?
    var peerConnectionFactory: RTCPeerConnectionFactory?
    var peerConnection: RTCPeerConnection?
    var iceCandidates: [RTCIceCandidate] = []
    @Published var videoTrack: RTCVideoTrack?
    var delegate: WHEPPlayerListener?
    
    init(serverUrl: URL, authToken: String?, configurationOptions: ConfigurationOptions?) {
        self.serverUrl = serverUrl
        self.authToken = authToken
        self.configurationOptions = configurationOptions
        super.init()
        let encoderFactory = RTCDefaultVideoEncoderFactory()
        let decoderFactory = RTCDefaultVideoDecoderFactory()
        self.peerConnectionFactory = RTCPeerConnectionFactory(
            encoderFactory: encoderFactory,
            decoderFactory: decoderFactory)
        
        let stunServerUrl = configurationOptions?.stunServerUrl ?? "stun:stun.l.google.com:19302"
        let stunServer = RTCIceServer(urlStrings: [stunServerUrl])
        let iceServers = [stunServer]
        
        let config = RTCConfiguration()
        config.iceServers = iceServers
        config.sdpSemantics = .unifiedPlan
        config.continualGatheringPolicy = .gatherContinually
        config.candidateNetworkPolicy = .all
        config.tcpCandidatePolicy = .disabled
        
        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        peerConnection = self.peerConnectionFactory!.peerConnection(with: config,
                                                                    constraints: constraints,
                                                                   delegate: self)!
    }
    
    func sendSdpOffer(sdpOffer: String) async throws -> String {
        let response =  try await Helper.sendSdpOffer(sdpOffer: sdpOffer, serverUrl: self.serverUrl, authToken: self.authToken)
        if let location = response.location {
            self.patchEndpoint = location
        }
        return response.responseString
    }

    func sendCandidate(candidate: RTCIceCandidate) async throws {
        try await Helper.sendCandidate(candidate: candidate, patchEndpoint: patchEndpoint, serverUrl: self.serverUrl)
    }
    
    func connect() async throws{
        var error: NSError?
        let videoTransceiver = peerConnection!.addTransceiver(of: .video)!
        videoTransceiver.setDirection(.recvOnly, error: &error)

        let audioTransceiver = peerConnection!.addTransceiver(of: .audio)!
        audioTransceiver.setDirection(.recvOnly, error: &error)

        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        let offer = try await peerConnection!.offer(for: constraints)
        try await peerConnection!.setLocalDescription(offer)

        let sdpAnswer = try await sendSdpOffer(sdpOffer: offer.sdp)
        
        for candidate in iceCandidates {
            do {
                try await sendCandidate(candidate: candidate)
            } catch {
                print("Error sending ICE candidate: \(error)")
            }
        }

        let remoteDescription = RTCSessionDescription(type: .answer, sdp: sdpAnswer)
        try await peerConnection!.setRemoteDescription(remoteDescription)
    }
    
    func release(peerConnection: RTCPeerConnection) {
        peerConnection.close()
    }
    
    func addTrackListener(delegate: WHEPPlayerListener) {
        self.delegate = delegate
        if let track = videoTrack {
            delegate.onTrackAdded(track: track)
        }
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        DispatchQueue.main.async {
            if let track = stream.videoTracks.first {
                self.videoTrack = track
                self.delegate?.onTrackAdded(track: track)
            }
        }
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        
    }
    
    public func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        if patchEndpoint != nil {
            Task { [weak self] in
                try await self?.sendCandidate(candidate: candidate)
            }
        } else {
            iceCandidates.append(candidate)
        }
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        
    }
    
    
}
