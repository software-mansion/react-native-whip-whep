import WebRTC

protocol WHIPPlayer {
    var patchEndpoint: String? { get set }
    var peerConnectionFactory: RTCPeerConnectionFactory? { get set }
    var peerConnection: RTCPeerConnection? { get set }
    var iceCandidates: [RTCIceCandidate] { get set }
    var videoTrack: RTCVideoTrack? { get set }
    var videoCapturer: RTCCameraVideoCapturer? { get set }
    var videoSource: RTCVideoSource? { get set }

    func sendSdpOffer(sdpOffer: String) async throws -> String
    func sendCandidate(candidate: RTCIceCandidate) async throws
    func connect() async throws
    func release() throws
}

public class WHIPClientPlayer: NSObject, WHIPPlayer, ObservableObject, RTCPeerConnectionDelegate {
    var serverUrl: URL
    var authToken: String?
    var configurationOptions: ConfigurationOptions?
    var patchEndpoint: String?
    var peerConnectionFactory: RTCPeerConnectionFactory?
    var peerConnection: RTCPeerConnection?

    var iceCandidates: [RTCIceCandidate] = []
    @Published public var videoTrack: RTCVideoTrack?

    var videoCapturer: RTCCameraVideoCapturer?
    var videoSource: RTCVideoSource?
    var audioDevice: AVCaptureDevice?
    var videoDevice: AVCaptureDevice?

    /**
    Initializes a `WHIPClientPlayer` object.

    - Parameter serverUrl: A URL of the WHIP server.
    - Parameter authToken: An authorization token of the WHIP server.
    - Parameter configurationOptions: Additional configuration options, such as a STUN server URL.
    - Parameter audioDevice: A device that will be used to stream audio.
    - Parameter videoDevice: A device that will be used to stream video.

    - Returns: A `WHIPClientPlayer` object.
    */
    public init(
        serverUrl: URL, authToken: String?, configurationOptions: ConfigurationOptions? = nil,
        audioDevice: AVCaptureDevice? = nil, videoDevice: AVCaptureDevice? = nil
    ) {
        self.serverUrl = serverUrl
        self.authToken = authToken
        self.configurationOptions = configurationOptions
        self.audioDevice = audioDevice
        self.videoDevice = videoDevice
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
        peerConnection = self.peerConnectionFactory?.peerConnection(
            with: config,
            constraints: constraints,
            delegate: self)
        if peerConnection == nil {
            print("Failed to establish RTCPeerConnection. Check initial configuration")
        }

        do {
            try setupVideoAndAudioDevices()
        } catch let error as AVCaptureDeviceError {
            switch error {
            case .AudioDeviceNotAvailable(let description),
                .VideoDeviceNotAvailable(let description):
                print(description)
            }
        } catch {
            print("Unexpected error: \(error)")
        }
    }

    /**
    Sends an SDP offer to the WHIP server.

    - Parameter sdpOffer: The offer to send to the server.

    - Throws: `AttributeNotFoundError.ResponseNotFound` if there is no response to the offer or
     `AttributeNotFoundError.LocationNotFound` if the response does not contain the location parameter.

    - Returns: A SDP response.
    */
    func sendSdpOffer(sdpOffer: String) async throws -> String {
        var response: (responseString: String, location: String?)?
        do {
            response = try await Helper.sendSdpOffer(
                sdpOffer: sdpOffer,
                serverUrl: self.serverUrl,
                authToken: self.authToken)
        } catch let error as AttributeNotFoundError {
            switch error {
            case .LocationNotFound(let description),
                .ResponseNotFound(let description),
                .UFragNotFound(let description),
                .PatchEndpointNotFound(let description):
                print(description)
            }
        } catch let error as SessionNetworkError {
            switch error {
            case .CandidateSendingError(let description),
                .ConnectionError(let description),
                .ConfigurationError(let description):
                print(description)
            }
        } catch {
            print("Unexpected error: \(error)")
        }
        guard let response = response else {
            throw AttributeNotFoundError.ResponseNotFound(
                description: "Response to SDP offer not found. Check if the network request was successful.")
        }

        if let location = response.location {
            self.patchEndpoint = location
        } else {
            throw AttributeNotFoundError.LocationNotFound(
                description: "Location attribute not found. Check if the SDP answer contains location parameter.")
        }

        return response.responseString
    }

    /**
    Sends an ICE candidate to WHIP server in order to provide a streaming device.

    - Parameter candidate: Represents a single ICE candidate.
    */
    func sendCandidate(candidate: RTCIceCandidate) async throws {
        do {
            try await Helper.sendCandidate(
                candidate: candidate, patchEndpoint: self.patchEndpoint, serverUrl: self.serverUrl)
        } catch let error as AttributeNotFoundError {
            switch error {
            case .LocationNotFound(let description),
                .PatchEndpointNotFound(let description),
                .ResponseNotFound(let description),
                .UFragNotFound(let description):
                print(description)
            }
        } catch let error as SessionNetworkError {
            switch error {
            case .CandidateSendingError(let description),
                .ConnectionError(let description),
                .ConfigurationError(let description):
                print(description)
            }
        } catch {
            print("Unexpected error: \(error)")
        }
    }

    /**
    Connects the client to the WHIP server using WebRTC Peer Connection.

    - Throws: `SessionNetworkError.ConfigurationError` if the `stunServerUrl` parameter
        of the initial configuration is incorrect, which leads to `peerConnection` being nil or in any other case where there has been an error in creating the `peerConnection`
    */
    public func connect() async throws {
        if peerConnection == nil {
            throw SessionNetworkError.ConfigurationError(
                description: "Failed to establish RTCPeerConnection. Check initial configuration")
        }

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

    /**
    Closes the established Peer Connection.
     
    - Throws: `SessionNetworkError.ConfigurationError` if the `stunServerUrl` parameter
    of the initial configuration is incorrect, which leads to `peerConnection` being nil or in any other case where there has been an error in creating the `peerConnection`
    */
    public func release() throws{
        if peerConnection == nil {
            throw SessionNetworkError.ConfigurationError(
                description: "Failed to establish RTCPeerConnection. Check initial configuration")
        }
        
        peerConnection?.close()
        videoCapturer?.stopCapture()
    }

    /**
    Gets the video and audio devices, prepares them, starts capture and adds it to the Peer Connection.

    - Throws: `AVCaptureDeviceError.AudioDeviceNotAvailable` if no audio device has been passed to the initializer and `AVCaptureDeviceError.VideoDeviceNotAvailable` if there is no video device.
    */
    private func setupVideoAndAudioDevices() throws {
        guard let audioDevice = self.audioDevice else {
            throw AVCaptureDeviceError.AudioDeviceNotAvailable(
                description: "Audio device not found. Check if it can be accessed and passed to the constructor.")
        }
        guard let videoDevice = self.videoDevice else {
            throw AVCaptureDeviceError.VideoDeviceNotAvailable(
                description: "Video device not found. Check if it can be accessed and passed to the constructor.")
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

    public func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {

    }

    public func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {

    }

    public func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {

    }

    public func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {

    }

    /**
     Reacts to changes in the ICE Connection state and logs a message depending on the current state.
    */
    public func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
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
            print(
                "The ICE agent has finished gathering candidates, has checked all pairs against one another, and has found a connection for all components."
            )
        case .closed:
            print("The ICE agent for this RTCPeerConnection has shut down and is no longer handling requests.")
        default:
            break
        }
    }

    public func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {

    }

    /**
     Reacts to new candidate found and sends it to the WHIP server.
    */
    public func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        if self.patchEndpoint != nil {
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
    
    /**
     Reacts to changes in the Peer Connection state and logs a message depending on the current state
    */
    public func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCPeerConnectionState) {
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
