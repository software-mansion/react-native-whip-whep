import WebRTC
import os

@available(macOS 12.0, *)
public class WhepClient: ClientBase & Connectable {

    /**
    Initializes a `WhepClient` object.
    
    - Parameter serverUrl: A URL of the WHEP server.
    - Parameter configurationOptions: Additional configuration options, such as a STUN server URL or authorization token.
    
    - Returns: A `WhepClient` object.
    */
    override public init(serverUrl: URL, configurationOptions: ConfigurationOptions? = nil) {
        super.init(serverUrl: serverUrl, configurationOptions: configurationOptions)
        setUpPeerConnection()
    }

    /**
    Connects the client to the WHEP server using WebRTC Peer Connection.
    
    - Throws: `SessionNetworkError.ConfigurationError` if the `stunServerUrl` parameter
        of the initial configuration is incorrect, which leads to `peerConnection` being nil or in any other case where there has been an error in creating the `peerConnection`
     */
    public func connect() async throws {
        if !self.isConnectionSetUp {
            setUpPeerConnection()
        } else if self.isConnectionSetUp && self.peerConnection == nil {
            throw SessionNetworkError.ConfigurationError(
                description: "Failed to establish RTCPeerConnection. Check initial configuration")
        }

        var audioEnabled = true
        var videoEnabled = true

        if let configOptions = configurationOptions {
            audioEnabled = configOptions.audioEnabled
            videoEnabled = configOptions.videoEnabled

            if !audioEnabled && !videoEnabled {
                logger.warning(
                    "Both audioEnabled and videoEnabled are set to false, what will result in no stream at all. Consider changing one of the options to true."
                )
            }
        }

        var error: NSError?

        if videoEnabled {
            let videoTransceiver = peerConnection!.addTransceiver(of: .video)!
            videoTransceiver.setDirection(.recvOnly, error: &error)
        }

        if audioEnabled {
            let audioTransceiver = peerConnection!.addTransceiver(of: .audio)!
            audioTransceiver.setDirection(.recvOnly, error: &error)
        }

        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        let offer = try await peerConnection!.offer(for: constraints)
        try await peerConnection!.setLocalDescription(offer)

        let sdpAnswer = try await sendSdpOffer(sdpOffer: offer.sdp)

        for candidate in iceCandidates {
            try await sendCandidate(candidate: candidate)
        }

        let remoteDescription = RTCSessionDescription(type: .answer, sdp: sdpAnswer)

        try await peerConnection!.setRemoteDescription(remoteDescription)
    }

    /**
    Closes the established Peer Connection.
    
    - Throws: `SessionNetworkError.ConfigurationError` if the `stunServerUrl` parameter
    of the initial configuration is incorrect, which leads to `peerConnection` being nil or in any other case where there has been an error in creating the `peerConnection`
    */
    public func disconnect() {
        peerConnection?.close()
        peerConnection = nil
        DispatchQueue.main.async {
            self.isConnectionSetUp = false
            self.videoTrack = nil
        }
    }

    private func getAudioTrack() -> RTCAudioTrack? {
        for transceiver in peerConnection!.transceivers {
            if let track = transceiver.receiver.track as? RTCAudioTrack {
                return track
            }
        }
        return nil
    }

    public func pause() {
        let audioTrack = getAudioTrack()
        audioTrack?.isEnabled = false
        self.videoTrack?.isEnabled = false
    }

    public func unpause() {
        let audioTrack = getAudioTrack()
        audioTrack?.isEnabled = true
        self.videoTrack?.isEnabled = true
    }
}
