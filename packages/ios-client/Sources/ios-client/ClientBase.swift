import Foundation
import Logging
import WebRTC
import os

extension RTCPeerConnection {
    // currently `Membrane RTC Engine` can't handle track of diretion `sendRecv` therefore
    // we need to change all `sendRecv` to `sendOnly`.
    func enforceSendOnlyDirection() {
        for transceiver in transceivers {
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

public protocol PlayerListener: AnyObject {
    func onTrackAdded(track: RTCVideoTrack)
    func onTrackRemoved(track: RTCVideoTrack)
}

protocol Player {
    var delegate: PlayerListener? { get set }

    func connect() async throws
    func disconnect()
}

public class ClientBase: NSObject, RTCPeerConnectionDelegate {
    private let stunServerUrl: String
    var patchEndpoint: String?
    var peerConnection: RTCPeerConnection?
    var iceCandidates: [RTCIceCandidate] = []
    var isConnectionSetUp: Bool = false
    var connectOptions: ClientConnectOptions?

    public var peerConnectionState: RTCPeerConnectionState? {
        return peerConnection?.connectionState
    }

    @Published public var videoTrack: RTCVideoTrack? {
        willSet {
            if let track = videoTrack {
                delegate?.onTrackRemoved(track: track)
            }
        }
        didSet {
            if let track = videoTrack {
                delegate?.onTrackAdded(track: track)
            }
        }
    }

    public var audioTrack: RTCAudioTrack?

    public weak var delegate: PlayerListener?
    public var onConnectionStateChanged: ((RTCPeerConnectionState) -> Void)?

    let logger = Logger(label: "com.swmansion.whipwhepclient")

    static var peerConnectionFactory = RTCPeerConnectionFactory(
        encoderFactory: RTCDefaultVideoEncoderFactory(),
        decoderFactory: RTCDefaultVideoDecoderFactory()
    )

    public init(stunServerUrl: String?) {
        self.stunServerUrl = stunServerUrl ?? "stun:stun.l.google.com:19302"
    }

    func setUpPeerConnection() {
        let stunServerUrl = stunServerUrl
        let stunServer = RTCIceServer(urlStrings: [stunServerUrl])
        let iceServers = [stunServer]

        let config = RTCConfiguration()
        config.iceServers = iceServers
        config.sdpSemantics = .unifiedPlan
        config.continualGatheringPolicy = .gatherContinually
        config.candidateNetworkPolicy = .all
        config.tcpCandidatePolicy = .disabled

        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        peerConnection = ClientBase.peerConnectionFactory.peerConnection(
            with: config,
            constraints: constraints,
            delegate: self
        )

        if peerConnection! == nil {
            print("Failed to establish RTCPeerConnection. Check initial configuration")
        }

        isConnectionSetUp = true
    }

    public func connect(_ connectOptions: ClientConnectOptions) async throws {
        self.connectOptions = connectOptions
    }

    /**
     Sends an SDP offer to the WHIP/WHEP server.
    
     - Parameter sdpOffer: The offer to send to the server.
    
     - Throws: `AttributeNotFoundError.ResponseNotFound` if there is no response to the offer or
      `AttributeNotFoundError.LocationNotFound` if the response does not contain the location parameter or
      `SessionNetworkError.ConnectionError` if the  connection could not be established or the response code is incorrect,
       for example due to server being down, wrong server URL or token.
    
     - Returns: A SDP response.
     */
    func send(sdpOffer: String) async throws -> String {
        guard let connectOptions else {
            throw SessionNetworkError.ConnectionError(
                description:
                    "Cannot send the SDP Offer. Connection not setup. Remember to call connect first.")
        }

        var request = URLRequest(url: connectOptions.serverUrl)
        request.httpMethod = "POST"
        request.httpBody = sdpOffer.data(using: .utf8)
        request.addValue("application/sdp", forHTTPHeaderField: "Accept")
        request.addValue("application/sdp", forHTTPHeaderField: "Content-Type")
        if let token = connectOptions.authToken {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        var data: Data?
        var response: URLResponse?
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw SessionNetworkError.ConnectionError(
                description:
                    "Network error. Check if the server is up and running and the token and the server url is correct.")
        }
        guard let httpResponse = response as? HTTPURLResponse,
            httpResponse.statusCode == 201
        else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw SessionNetworkError.ConnectionError(
                description:
                    "Network error. Check if the server is up and running and the token and the server url is correct.")
        }

        let responseString = String(data: data!, encoding: .utf8)
        if let foundLocation = httpResponse.allHeaderFields["Location"] as? String {
            patchEndpoint = foundLocation
            print("Location: \(foundLocation)")
        } else {
            throw AttributeNotFoundError.LocationNotFound(
                description: "Location attribute not found. Check if the SDP answer contains location parameter.")
        }
        guard let response = responseString else {
            throw AttributeNotFoundError.ResponseNotFound(
                description: "Response to SDP offer not found. Check if the network request was successful.")
        }
        return response
    }

    /**
     Sends an ICE candidate to WHIP/WHEP server in order to provide a streaming device.
    
     - Parameter candidate: Represents a single ICE candidate.
    
     - Throws: `AttributeNotFoundError.PatchEndpointNotFound` if the patch endpoint has not been properly set up,
       `AttributeNotFoundError.UFragNotFound` if the SDP of the candidate does not contain the ufrag,
       `SessionNetworkError.CandidateSendingError` if the candidate could not be sent and
       `NSError` for when the candidate data dictionary could not be serialized to JSON.
     */
    func sendCandidate(candidate: RTCIceCandidate) async throws {
        guard let connectOptions else {
            throw SessionNetworkError.ConnectionError(
                description:
                    "Cannot send ICE Candidate. Connection not setup. Remember to call connect first.")
        }

        guard patchEndpoint != nil else {
            throw AttributeNotFoundError.PatchEndpointNotFound(
                description: "Patch endpoint not found. Make sure the SDP answer is correct.")
        }

        let splitSdp = candidate.sdp.split(separator: " ")
        guard let ufragIndex = splitSdp.firstIndex(of: "ufrag") else {
            throw AttributeNotFoundError.UFragNotFound(
                description: "ufrag not found. Make sure the SDP answer is correct.")
        }
        let ufrag = String(splitSdp[ufragIndex + 1])

        let candidateDict =
            [
                "candidate": candidate.sdp,
                "sdpMLineIndex": candidate.sdpMLineIndex,
                "sdpMid": candidate.sdpMid ?? "",
                "usernameFragment": ufrag,
            ] as [String: Any]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: candidateDict, options: []) else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "JSON serialization error"])
        }

        var components = URLComponents(string: connectOptions.serverUrl.absoluteString)
        components?.path = ""
        components?.path = patchEndpoint!
        let url = components?.url
        var request = URLRequest(url: url!)
        request.httpMethod = "PATCH"
        request.httpBody = jsonData
        request.setValue("application/trickle-ice-sdpfrag", forHTTPHeaderField: "Content-Type")

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 204 else {
            throw SessionNetworkError.CandidateSendingError(
                description: "Candidate sending error - response was not successful.")
        }
    }

    public func peerConnection(_: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        logger.debug("RTC signaling state changed: \(stateChanged.rawValue).")
    }

    public func peerConnection(_: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        DispatchQueue.main.async {
            if let track = stream.videoTracks.first {
                self.videoTrack = track
                self.delegate?.onTrackAdded(track: track)
            }
        }
        logger.debug("RTC media stream added: \(stream.description).")
    }

    public func peerConnection(_: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        logger.debug("RTC media stream removed: \(stream.description).")
    }

    public func peerConnectionShouldNegotiate(_: RTCPeerConnection) {
        logger.debug("Peer connection negotiation needed.")
    }

    /**
      Reacts to changes in the ICE Connection state and logs a message depending on the current state.
     */
    public func peerConnection(_: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        switch newState {
        case .checking:
            logger.debug("ICE is checking paths, this might take a moment.")
        case .connected:
            logger.debug("ICE has found a viable connection.")
        case .failed:
            logger.debug("No viable ICE paths found, consider a retry or using TURN.")
        case .disconnected:
            logger.debug("ICE connection was disconnected, attempting to reconnect or refresh.")
        case .new:
            logger.debug(
                "The ICE agent is gathering addresses or is waiting to be given remote candidates through calls")
        case .completed:
            logger.debug(
                "The ICE agent has finished gathering candidates, has checked all pairs against one another, and has found a connection for all components."
            )
        case .closed:
            logger.debug("The ICE agent for this RTCPeerConnection has shut down and is no longer handling requests.")
        default:
            break
        }
    }

    public func peerConnection(_: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        logger.debug("RTC ICE gathering state changed: \(newState.rawValue).")
    }

    /**
      Reacts to new candidate found and sends it to the WHIP/WHEP server.
     */
    public func peerConnection(_: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        if patchEndpoint != nil {
            Task { [weak self] in
                try await self?.sendCandidate(candidate: candidate)
            }
        } else {
            iceCandidates.append(candidate)
        }
    }

    public func peerConnection(_: RTCPeerConnection, didRemove _: [RTCIceCandidate]) {
        logger.debug("Removed candidate from candidates list.")
    }

    public func peerConnection(_: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        logger.debug("RTC data channel opened: \(dataChannel.channelId)")
    }

    /**
      Reacts to changes in the Peer Connection state and logs a message depending on the current state
     */
    public func peerConnection(_: RTCPeerConnection, didChange stateChanged: RTCPeerConnectionState) {
        onConnectionStateChanged?(stateChanged)
        switch stateChanged {
        case .connected:
            logger.debug("Connection is fully connected")
        case .disconnected:
            logger.debug("One or more transports has disconnected unexpectedly")
        case .failed:
            logger.debug("One or more transports has encountered an error")
        case .closed:
            logger.debug("Connection has been closed")
        case .new:
            logger.debug("New connection")
        case .connecting:
            logger.debug("Connecting")
        default:
            logger.debug("Some other state: \(stateChanged.rawValue)")
        }
    }

    // MARK: - Codec Management

    /**
     Gets matched codecs from the preferred codec list that are available in the peer connection factory.
    
     - Parameter preferredCodecs: List of preferred codec names
     - Parameter mediaType: The media type (audio or video)
     - Parameter useReceiver: Whether to use receiver capabilities instead of sender capabilities
    
     - Returns: Array of matched codec capabilities
     */
    func getMatchedCodecs(preferredCodecs: [String], mediaType: String, useReceiver: Bool = false)
        -> [RTCRtpCodecCapability]
    {
        if preferredCodecs.isEmpty {
            return []
        }

        let capabilities =
            useReceiver
            ? ClientBase.peerConnectionFactory.rtpReceiverCapabilities(forKind: mediaType)
            : ClientBase.peerConnectionFactory.rtpSenderCapabilities(forKind: mediaType)
        let availableCodecs = capabilities.codecs

        return preferredCodecs.compactMap { preferredCodec in
            availableCodecs.first { codec in
                codec.name.caseInsensitiveCompare(preferredCodec) == .orderedSame
            }
        }
    }

    /**
     Sets codec preferences for a transceiver if matched codecs are available.
    
     - Parameter transceiver: The RTP transceiver to set preferences for
     - Parameter preferredCodecs: List of preferred codec names
     - Parameter mediaType: The media type (audio or video)
     - Parameter useReceiver: Whether to use receiver capabilities instead of sender capabilities
     */
    func setCodecPreferencesIfAvailable(
        transceiver: RTCRtpTransceiver?, preferredCodecs: [String], mediaType: String, useReceiver: Bool = false
    ) {
        let matchedCodecs = getMatchedCodecs(
            preferredCodecs: preferredCodecs, mediaType: mediaType, useReceiver: useReceiver
        )
        if !matchedCodecs.isEmpty {
            transceiver?.codecPreferences = matchedCodecs
        }
    }
}
