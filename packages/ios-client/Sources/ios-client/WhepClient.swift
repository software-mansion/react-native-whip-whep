import WebRTC
import os

@available(macOS 12.0, *)
public class WhepClient: ClientBase {

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
        of the initial configuration is incorrect, which leads to `peerConnection` being nil or in any other case where there has been an error in creating the `peerConnection` or
     `ConfigurationOptionsError.WrongCaptureDeviceConfiguration` if both `audioOnly` and `videoOnly` is set to true.
    */
    public func connect() async throws {
        if !self.isConnectionSetUp {
            setUpPeerConnection()
        } else if self.isConnectionSetUp && self.peerConnection == nil {
            throw SessionNetworkError.ConfigurationError(
                description: "Failed to establish RTCPeerConnection. Check initial configuration")
        }
        
        if (configurationOptions != nil && configurationOptions!.audioOnly == true && configurationOptions?.videoOnly == true){
            throw ConfigurationOptionsError.WrongCaptureDeviceConfiguration(description: "Wrong initial configuration. Either audioOnly or videoOnly should be set to false.")
        }

        var error: NSError?
        
        if((configurationOptions != nil) && !configurationOptions!.audioOnly){
            let videoTransceiver = peerConnection!.addTransceiver(of: .video)!
            videoTransceiver.setDirection(.recvOnly, error: &error)
        }
        
        if((configurationOptions != nil) && !configurationOptions!.videoOnly){
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
}
