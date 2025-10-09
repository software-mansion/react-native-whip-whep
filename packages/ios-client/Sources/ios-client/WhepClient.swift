import os
import WebRTC

public struct WhepConfigurationOptions {
    public let audioEnabled: Bool
    public let videoEnabled: Bool
    public let stunServerUrl: String?

    public init(audioEnabled: Bool = true, videoEnabled: Bool = true, stunServerUrl: String?) {
        self.audioEnabled = audioEnabled
        self.videoEnabled = videoEnabled
        self.stunServerUrl = stunServerUrl
    }
}

@available(macOS 12.0, *)
public class WhepClient: ClientBase {
    let configOptions: WhepConfigurationOptions
    private var reconnectionManager: ReconnectionManager?
    public weak var reconnectionListener: ReconnectionManagerListener?

    /**
     Initializes a `WhepClient` object.

     - Parameter serverUrl: A URL of the WHEP server.
     - Parameter configurationOptions: Additional configuration options, such as a STUN server URL or authorization token.

     - Returns: A `WhepClient` object.
     */
    public init(configOptions: WhepConfigurationOptions) {
        self.configOptions = configOptions
        super.init(stunServerUrl: configOptions.stunServerUrl)
        setUpPeerConnection()

        reconnectionManager = ReconnectionManager(
            reconnectConfig: ReconnectConfig(),
            connect: {
                Task { [weak self] in
                    do {
                        guard let connectOptions = self?.connectOptions else {
                            throw SessionNetworkError.ConnectionError(
                                description:
                                "Connection not setup. Cannot reconnect on a non existing connection.")
                        }
                        try await self?.connect(connectOptions)
                    } catch {
                        self?.logger.error("Reconnection failed: \(error)")
                    }
                }
            },
            listener: reconnectionListener
        )
    }

    /**
     Connects the client to the WHEP server using WebRTC Peer Connection.

     - Throws: `SessionNetworkError.ConfigurationError` if the `stunServerUrl` parameter
         of the initial configuration is incorrect, which leads to `peerConnection` being nil or in any other case where there has been an error in creating the `peerConnection`
      */
    override public func connect(_ connectOptions: ClientConnectOptions) async throws {
        try await super.connect(connectOptions)
        if !isConnectionSetUp {
            setUpPeerConnection()
        } else if isConnectionSetUp, peerConnection == nil {
            throw SessionNetworkError.ConfigurationError(
                description: "Failed to establish RTCPeerConnection. Check initial configuration")
        }

        let audioEnabled = configOptions.audioEnabled
        let videoEnabled = configOptions.videoEnabled

        if !audioEnabled, !videoEnabled {
            logger.warning(
                "Both audioEnabled and videoEnabled are set to false, what will result in no stream at all. Consider changing one of the options to true."
            )
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

        let sdpAnswer = try await send(sdpOffer: offer.sdp)

        for candidate in iceCandidates {
            try await sendCandidate(candidate: candidate)
        }

        let remoteDescription = RTCSessionDescription(type: .answer, sdp: sdpAnswer)

        try await peerConnection!.setRemoteDescription(remoteDescription)

        reconnectionManager?.onReconnected()
    }

    override public func peerConnection(_ peerConnection: RTCPeerConnection,
                                        didChange newState: RTCIceConnectionState)
    {
        super.peerConnection(peerConnection, didChange: newState)

        if newState == .disconnected {
            reconnectionManager?.onDisconnected()
        }
    }

    /**
     Closes the established Peer Connection.

     - Throws: `SessionNetworkError.ConfigurationError` if the `stunServerUrl` parameter
     of the initial configuration is incorrect, which leads to `peerConnection` being nil or in any other case where there has been an error in creating the `peerConnection`
     */
    public func disconnect() {
        DispatchQueue.main.async { [weak self] in
            self?.peerConnection?.close()
            self?.peerConnection = nil
            self?.isConnectionSetUp = false
            self?.videoTrack = nil
        }
    }

    public func cleanup() {
        reconnectionManager = nil
        delegate = nil
        reconnectionListener = nil
        onConnectionStateChanged = nil
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
        videoTrack?.isEnabled = false
    }

    public func unpause() {
        let audioTrack = getAudioTrack()
        audioTrack?.isEnabled = true
        videoTrack?.isEnabled = true
    }

    // MARK: - Codec Management

    /**
     Gets the names of supported receiver video codecs.

     - Returns: Array of supported video codec names
     */
    public static func getSupportedReceiverVideoCodecsNames() -> [String] {
        let capabilities = WhepClient.peerConnectionFactory.rtpReceiverCapabilities(
            forKind: kRTCMediaStreamTrackKindVideo)

        return capabilities.codecs.map { $0.name }
    }

    /**
     Gets the names of supported receiver audio codecs.

     - Returns: Array of supported audio codec names
     */
    public static func getSupportedReceiverAudioCodecsNames() -> [String] {
        let capabilities = WhepClient.peerConnectionFactory.rtpReceiverCapabilities(
            forKind: kRTCMediaStreamTrackKindAudio)

        return capabilities.codecs.map { $0.name }
    }

    /**
     Sets preferred video codecs for receiving.

     - Parameter preferredCodecs: Array of preferred video codec names, or nil to skip setting
     */
    public func setPreferredVideoCodecs(preferredCodecs: [String]?) {
        guard let preferredCodecs = preferredCodecs, !preferredCodecs.isEmpty else {
            return
        }

        guard let peerConnection = peerConnection else {
            return
        }

        for transceiver in peerConnection.transceivers {
            if transceiver.mediaType == .video {
                setCodecPreferencesIfAvailable(
                    transceiver: transceiver,
                    preferredCodecs: preferredCodecs,
                    mediaType: kRTCMediaStreamTrackKindVideo,
                    useReceiver: true
                )
            }
        }
    }

    /**
     Sets preferred audio codecs for receiving.

     - Parameter preferredCodecs: Array of preferred audio codec names, or nil to skip setting
     */
    public func setPreferredAudioCodecs(preferredCodecs: [String]?) {
        guard let preferredCodecs = preferredCodecs, !preferredCodecs.isEmpty else {
            return
        }

        guard let peerConnection = peerConnection else {
            return
        }

        for transceiver in peerConnection.transceivers {
            if transceiver.mediaType == .audio {
                setCodecPreferencesIfAvailable(
                    transceiver: transceiver,
                    preferredCodecs: preferredCodecs,
                    mediaType: kRTCMediaStreamTrackKindAudio,
                    useReceiver: true
                )
            }
        }
    }
}
