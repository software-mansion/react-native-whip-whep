import WebRTC

protocol WHEPPlayerListener: AnyObject {
    func onTrackAdded(track: RTCVideoTrack)
}

protocol WHEPPlayer {
    var patchEndpoint: String? { get set }
    var peerConnectionFactory: RTCPeerConnectionFactory? { get set }
    var peerConnection: RTCPeerConnection? { get set }
    var iceCandidates: [RTCIceCandidate] { get set }
    var videoTrack: RTCVideoTrack? { get set }
    var delegate: WHEPPlayerListener? { get set }

    func sendSdpOffer(sdpOffer: String) async throws -> String
    func sendCandidate(candidate: RTCIceCandidate) async throws
    func connect() async throws
    func release() throws
}

@available(macOS 12.0, *)
public class WHEPClientPlayer: NSObject, WHEPPlayer, RTCPeerConnectionDelegate, ObservableObject {
    var serverUrl: URL
    var authToken: String?
    var configurationOptions: ConfigurationOptions?
    var patchEndpoint: String?
    var peerConnectionFactory: RTCPeerConnectionFactory?
    var peerConnection: RTCPeerConnection?
    var iceCandidates: [RTCIceCandidate] = []
    @Published public var videoTrack: RTCVideoTrack?
    var delegate: WHEPPlayerListener?

    /**
    Initializes a `WHEPClientPlayer` object.

    - Parameter serverUrl: A URL of the WHEP server.
    - Parameter authToken: An authorization token of the WHEP server.
    - Parameter configurationOptions: Additional configuration options, such as a STUN server URL.

    - Returns: A `WHEPClientPlayer` object.
    */
    public init(serverUrl: URL, authToken: String?, configurationOptions: ConfigurationOptions? = nil) {
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
        peerConnection = self.peerConnectionFactory!.peerConnection(
            with: config,
            constraints: constraints,
            delegate: self)!
        if peerConnection == nil {
            print("Failed to establish RTCPeerConnection. Check initial configuration")
        }
    }

    /**
    Sends an SDP offer to the WHEP server.

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
    Sends an ICE candidate to WHEP server in order to provide a streaming device.

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
    Connects the client to the WHEP server using WebRTC Peer Connection.

    - Throws: `SessionNetworkError.ConfigurationError` if the `stunServerUrl` parameter
        of the initial configuration is incorrect, which leads to `peerConnection` being nil or in any other case where there has been an error in creating the `peerConnection`
    */
    public func connect() async throws {
        if peerConnection == nil {
            throw SessionNetworkError.ConfigurationError(
                description: "Failed to establish RTCPeerConnection. Check initial configuration")
        }

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
