import Foundation
import WebRTC
import os

public protocol PlayerListener: AnyObject {
    func onTrackAdded(track: RTCVideoTrack)
    func onTrackRemoved(track: RTCVideoTrack)
}

protocol Player {
    var delegate: PlayerListener? { get set }

    func connect() async throws
    func disconnect()
}

public class ClientBase: NSObject, RTCPeerConnectionDelegate, RTCPeerConnectionFactoryType {
    var serverUrl: URL
    var authToken: String?
    var configurationOptions: ConfigurationOptions?
    var patchEndpoint: String?
    var peerConnectionFactory: RTCPeerConnectionFactory?
    var peerConnection: RTCPeerConnection?
    var iceCandidates: [RTCIceCandidate] = []
    var isConnectionSetUp: Bool = false
    var videoTrack: RTCVideoTrack? {
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

    public var delegate: PlayerListener?

    let logger = Logger()

    public init(serverUrl: URL, configurationOptions: ConfigurationOptions? = nil) {
        self.serverUrl = serverUrl
        self.authToken = configurationOptions?.authToken
        self.configurationOptions = configurationOptions
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
        response = try? await Helper.sendSdpOffer(
            sdpOffer: sdpOffer,
            serverUrl: self.serverUrl,
            authToken: self.authToken)
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
        try await Helper.sendCandidate(
            candidate: candidate, patchEndpoint: self.patchEndpoint, serverUrl: self.serverUrl)
    }

    public func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        logger.debug("RTC signaling state changed: \(stateChanged.rawValue).")
    }

    public func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        DispatchQueue.main.async {
            if let track = stream.videoTracks.first {
                self.videoTrack = track
                self.delegate?.onTrackAdded(track: track)
            }
        }
        logger.debug("RTC media stream added: \(stream.description).")
    }

    public func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        logger.debug("RTC media stream removed: \(stream.description).")
    }

    public func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        logger.debug("Peer connection negotiation needed.")
    }

    /**
     Reacts to changes in the ICE Connection state and logs a message depending on the current state.
    */
    public func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
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

    public func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        logger.debug("RTC ICE gathering state changed: \(newState.rawValue).")
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
        logger.debug("Removed candidate from candidates list.")
    }

    public func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        logger.debug("RTC data channel opened: \(dataChannel.channelId)")
    }

    /**
     Reacts to changes in the Peer Connection state and logs a message depending on the current state
    */
    public func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCPeerConnectionState) {
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

}
