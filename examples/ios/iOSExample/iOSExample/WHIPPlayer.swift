import WebRTC

class WHIPPlayer: NSObject, ObservableObject, RTCPeerConnectionDelegate{
    var patchEndpoint: String?
    var peerConnectionFactory: RTCPeerConnectionFactory?
    var peerConnection: RTCPeerConnection?
    var iceCandidates: [RTCIceCandidate] = []
    var connectionOptions: ConnectionOptions
    @Published var videoTrack: RTCVideoTrack?
    

    
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
        var error: NSError?
        let videoTransceiver = peerConnection!.addTransceiver(of: .video)!
        videoTransceiver.setDirection(.sendOnly, error: &error)

        let audioTransceiver = peerConnection!.addTransceiver(of: .audio)!
        audioTransceiver.setDirection(.sendOnly, error: &error)

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
            // Request access to the camera and microphone
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
        let audioDevice = AVCaptureDevice.default(for: .audio)
        
        guard let videoDevice = selectVideoDevice() else {
            print("Could not access any video device")
            return
        }
        
        print(videoDevice)
        let videoSource = peerConnectionFactory!.videoSource()
        videoSource.adaptOutputFormat(toWidth: 640, height: 480, fps: 30)
        let videoCapturer = RTCCameraVideoCapturer(delegate: videoSource)
        
        let videoTrack = peerConnectionFactory!.videoTrack(with: videoSource, trackId: "video0")
        videoTrack.isEnabled = true
        
        videoCapturer.startCapture(with: videoDevice, format: videoDevice.activeFormat, fps: 30) { error in
            if let error = error {
                print("Error starting the video capture: \(error)")
            } else {
                print("Video capturing started")
            }
        }

        let mediaStream = self.peerConnectionFactory!.mediaStream(withStreamId: "stream0")
        mediaStream.addVideoTrack(videoTrack)
        print(mediaStream)
        print("Video track:", videoTrack)
        self.peerConnection!.add(videoTrack, streamIds: ["stream0"])

//        let audioSource = self.peerConnectionFactory!.audioSource(with: nil)
//        let audioTrack = self.peerConnectionFactory!.audioTrack(with: audioSource, trackId: "audio0")
//        
//        //mediaStream.addAudioTrack(audioTrack)
//        self.peerConnection!.add(audioTrack, streamIds: ["stream1"])
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
    
    private func createDataChannel() -> RTCDataChannel? {
        let config = RTCDataChannelConfiguration()
        guard let dataChannel = self.peerConnection!.dataChannel(forLabel: "WebRTCData", configuration: config) else {
            debugPrint("Warning: Couldn't create data channel.")
            return nil
        }
        return dataChannel
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
            fetchConnectionStats()
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
    
    func fetchConnectionStats() {
        peerConnection?.statistics { report in
            for stats in report.statistics.values {
                if stats.type == "candidate-pair" && stats.values["state"] as! String == "succeeded" {
                    print("Active Candidate Pair:")
                    print("Local Candidate ID: \(stats.values["localCandidateId"] )")
                    print("Remote Candidate ID: \(stats.values["remoteCandidateId"] )")
                    self.printCandidateDetails(stats.values["localCandidateId"] as? String, in: report)
                    self.printCandidateDetails(stats.values["remoteCandidateId"] as? String, in: report)
                }
            }
        }
    }

    func printCandidateDetails(_ candidateId: String?, in report: RTCStatisticsReport) {
        guard let candidateId = candidateId,
              let candidateStats = report.statistics[candidateId] else {
            print("Candidate details not found.")
            return
        }
        
        print("Candidate ID: \(candidateId)")
        print("Type: \(candidateStats.values["candidateType"] )")
        print("Protocol: \(candidateStats.values["protocol"] )")
        print("Address: \(candidateStats.values["ip"])")
        print("Port: \(candidateStats.values["port"])")
    }
}
