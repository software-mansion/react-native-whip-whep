import WebRTC

extension RTCPeerConnection {
  // currently `Membrane RTC Engine` can't handle track of diretion `sendRecv` therefore
  // we need to change all `sendRecv` to `sendOnly`.
  func enforceSendOnlyDirection() {
    self.transceivers.forEach { transceiver in
      if transceiver.direction == .sendRecv {
        transceiver.setDirection(.sendOnly, error: nil)
      }
    }
  }
}

extension RTCRtpEncodingParameters {
  static func create(rid: String, active: Bool, scaleResolutionDownBy: NSNumber) -> RTCRtpEncodingParameters {
    let encoding = RTCRtpEncodingParameters()
    encoding.rid = rid
    encoding.isActive = active
    encoding.scaleResolutionDownBy = scaleResolutionDownBy
    return encoding
  }
  

  static func create(active: Bool) -> RTCRtpEncodingParameters {
    let encoding = RTCRtpEncodingParameters()
    encoding.isActive = active
    return encoding
  }
}

class WHIPPlayer: NSObject, ObservableObject, RTCPeerConnectionDelegate{
    var patchEndpoint: String?
    var peerConnectionFactory: RTCPeerConnectionFactory?
    var peerConnection: RTCPeerConnection?
    var iceCandidates: [RTCIceCandidate] = []
    var connectionOptions: ConnectionOptions
    @Published var videoTrack: RTCVideoTrack?
    var videoCapturer: RTCCameraVideoCapturer?
    var videoSource: RTCVideoSource?
    
    
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
        setupLocalMedia()
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
    
    func setupLocalMedia() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            self.setupVideoAndAudioDevices()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    self.setupVideoAndAudioDevices()
                }
            }
        default:
            print("Access denied")
        }
    }

    private func setupVideoAndAudioDevices() {
        _ = AVCaptureDevice.default(for: .audio)
        guard let videoDevice = selectVideoDevice() else {
            print("Could not access any video device")
            return
        }
        
        let videoSource = peerConnectionFactory!.videoSource()
        self.videoSource = videoSource
        let videoCapturer = RTCCameraVideoCapturer(delegate: videoSource)
        self.videoCapturer = videoCapturer
        let videoTrackId = UUID().uuidString
        
        let videoTrack = peerConnectionFactory!.videoTrack(with: videoSource, trackId: videoTrackId)
        videoTrack.isEnabled = true
        
        videoCapturer.startCapture(with: videoDevice, format: videoDevice.activeFormat, fps: 30) { error in
            if let error = error {
                print("Error starting the video capture: \(error)")
            } else {
                print("Video capturing started")
            }
        }
        
        let audioTrackId = UUID().uuidString
        let audioSource = self.peerConnectionFactory!.audioSource(with: nil)
        let audioTrack = self.peerConnectionFactory!.audioTrack(with: audioSource, trackId: audioTrackId)

        let sendEncodings = [RTCRtpEncodingParameters.create(active: true)]
        let localStreamId = UUID().uuidString
          

        let transceiverInit = RTCRtpTransceiverInit()
        transceiverInit.direction = RTCRtpTransceiverDirection.sendOnly
        transceiverInit.streamIds = [localStreamId]
        transceiverInit.sendEncodings = sendEncodings
        peerConnection?.addTransceiver(with: videoTrack, init: transceiverInit)
        
        let audioTransceiverInit = RTCRtpTransceiverInit()
        audioTransceiverInit.direction = RTCRtpTransceiverDirection.sendOnly
        audioTransceiverInit.streamIds = [localStreamId]
        peerConnection?.addTransceiver(with: audioTrack, init: audioTransceiverInit)
        peerConnection?.enforceSendOnlyDirection()
        
        self.videoTrack = videoTrack

    }
    
    func selectVideoDevice() -> AVCaptureDevice? {
        let preferredPosition: AVCaptureDevice.Position = .back
        let devices = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInTrueDepthCamera, .builtInTelephotoCamera, .builtInUltraWideCamera], mediaType: .video, position: .unspecified).devices
        
        if let device = devices.first(where: { $0.position == preferredPosition }) {
            return device
        } else if let device = devices.first {
            return device
        }
        return nil
    }

    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        print("Signaling state changed: \(stateChanged)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        print("Stream added: \(stream)")
        DispatchQueue.main.async {
            if let track = stream.videoTracks.first {
                self.videoTrack = track
                print("Video track received and set.")
            } else {
                print("No video track available in the stream.")
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
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCPeerConnectionState) {
        switch stateChanged {
        case .connected:
            print("Connection is fully connected")
        case .disconnected:
            print("One or more transports has disconnected unexpectedly")
        case .failed:
            print("One or more transports has encountered an error")
        case .closed:
            print("Connection has been closed")
        case .new:
            print("New connection")
        case .connecting:
            print("Connecting")
        default:
            print("Some other state: \(stateChanged.rawValue)")
        }
    }
}
