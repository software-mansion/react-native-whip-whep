import WebRTC

protocol WHEPPlayerListener: AnyObject {
    func onTrackAdded(track: RTCVideoTrack)
}

class WHEPPlayer: NSObject, ObservableObject, RTCPeerConnectionDelegate{
    var patchEndpoint: String?
    var peerConnectionFactory: RTCPeerConnectionFactory?
    var peerConnection: RTCPeerConnection?
    var iceCandidates: [RTCIceCandidate] = []
    var connectionOptions: ConnectionOptions
    @Published var videoTrack: RTCVideoTrack?
    private weak var delegate: WHEPPlayerListener?

    
    init(connectionOptions: ConnectionOptions) {
        self.connectionOptions = connectionOptions
        super.init()
        let encoderFactory = RTCDefaultVideoEncoderFactory()
        let decoderFactory = RTCDefaultVideoDecoderFactory()
        self.peerConnectionFactory = RTCPeerConnectionFactory(
            encoderFactory: encoderFactory,
            decoderFactory: decoderFactory)
        
        let stunServer = RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"])
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
    
    func addTrackListener(delegate: WHEPPlayerListener) {
        self.delegate = delegate
        if let track = videoTrack {
            delegate.onTrackAdded(track: track)
        }
    }
    
    
    func sendSdpOffer(sdpOffer: String) async throws -> String {
        let fullURL = connectionOptions.serverUrl.appendingPathComponent(connectionOptions.whepEndpoint)
        print(fullURL)
        var request = URLRequest(url: fullURL)
        request.httpMethod = "POST"
        request.httpBody = sdpOffer.data(using: .utf8)
        request.addValue("application/sdp", forHTTPHeaderField: "Accept")
        request.addValue("application/sdp", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(connectionOptions.authToken ?? "")", forHTTPHeaderField: "Authorization")


        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 201 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw NSError(domain: "HTTPError", code: statusCode, userInfo: nil)
        }

        let responseString = String(data: data, encoding: .utf8)
        if let location = httpResponse.allHeaderFields["Location"] as? String {
            self.patchEndpoint = location
            print("Location: \(location)")
        }
        
        return responseString!
    }
    
    func sendCandidate(candidate: RTCIceCandidate, patchEndpoint: String?) async throws {
        guard let patchEndpoint = patchEndpoint else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Patch endpoint is nil"])
        }
        
        let splitSdp = candidate.sdp.split(separator: " ")
        guard let ufragIndex = splitSdp.firstIndex(of: "ufrag") else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to find 'ufrag' in SDP"])
        }
        let ufrag = String(splitSdp[ufragIndex + 1])
        
        let candidateDict = [
            "candidate": candidate.sdp,
            "sdpMLineIndex": candidate.sdpMLineIndex,
            "sdpMid": candidate.sdpMid ?? "",
            "usernameFragment": ufrag
        ] as [String : Any]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: candidateDict, options: []) else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "JSON serialization error"])
        }
        
        let url = connectionOptions.serverUrl.appendingPathComponent(patchEndpoint)
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.httpBody = jsonData
        request.setValue("application/trickle-ice-sdpfrag", forHTTPHeaderField: "Content-Type")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 204 else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Response was not successful"])
        }
    }
    
    func connect() async throws {
        var error: NSError?
        let videoTransceiver = peerConnection!.addTransceiver(of: .video)!
        videoTransceiver.setDirection(.recvOnly, error: &error)

        let audioTransceiver = peerConnection!.addTransceiver(of: .audio)!
        audioTransceiver.setDirection(.recvOnly, error: &error)

        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        let offer = try await peerConnection!.offer(for: constraints)
        try await peerConnection!.setLocalDescription(offer)
        
        print("SDP Offer: \(offer.sdp)")

        let sdpAnswer = try await sendSdpOffer(sdpOffer: offer.sdp)
        
        print("SDP answer: \(sdpAnswer)")
        
        for candidate in iceCandidates {
            do {
                try await sendCandidate(candidate: candidate, patchEndpoint: patchEndpoint)
            } catch {
                print("Error sending ICE candidate: \(error)")
            }
        }

        let remoteDescription = RTCSessionDescription(type: .answer, sdp: sdpAnswer)
        try await peerConnection!.setRemoteDescription(remoteDescription)

    }
    
    func release() {
        peerConnection!.close()
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        print("Signaling state changed: \(stateChanged)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        print("Stream added: \(stream)")
        DispatchQueue.main.async {
            if let track = stream.videoTracks.first {
                self.videoTrack = track
                self.delegate?.onTrackAdded(track: track)
            }
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        print("Stream removed: \(stream)")
    }
    
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        print("Negotiation is needed")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        switch newState {
        case .checking:
            print("ICE is checking paths, this might take a moment.")
        case .connected:
            print("ICE has found a viable connection.")
        case .failed:
            print("No viable ICE paths found, consider a retry or using TURN.")
        case .disconnected:
            print("ICE connection was disconnected, attempting to reconnect or refresh.")
        case .new:
            print("The ICE agent is gathering addresses or is waiting to be given remote candidates through calls")
        case .completed:
            print("The ICE agent has finished gathering candidates, has checked all pairs against one another, and has found a connection for all components.")
        case .closed:
            print("The ICE agent for this RTCPeerConnection has shut down and is no longer handling requests.")
        default:
            break
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        print("ICE gathering state changed: \(newState)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        if let patchEndpoint = patchEndpoint {
            Task { [weak self] in
                try await self?.sendCandidate(candidate: candidate, patchEndpoint: patchEndpoint)
            }
        } else {
            iceCandidates.append(candidate)
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        print("Did open data channel: \(dataChannel)")
    }
}
