import WebRTC
import os

public struct WhipConfigurationOptions {
    public let audioEnabled: Bool
    public let videoEnabled: Bool
    public let videoDevice: AVCaptureDevice
    public let videoParameters: VideoParameters
    public let stunServerUrl: String?

    public init(
        audioEnabled: Bool = true, videoEnabled: Bool = true, videoDevice: AVCaptureDevice,
        videoParameters: VideoParameters, stunServerUrl: String?
    ) {
        self.audioEnabled = audioEnabled
        self.videoEnabled = videoEnabled
        self.videoDevice = videoDevice
        self.videoParameters = videoParameters
        self.stunServerUrl = stunServerUrl
    }
}

public class WhipClient: ClientBase {
    private let configOptions: WhipConfigurationOptions
    private var videoCapturer: RTCCameraVideoCapturer?
    private var videoSource: RTCVideoSource?

    override func setUpPeerConnection() {
        super.setUpPeerConnection()

        do {
            try setUpVideoAndAudioDevices()
        } catch let error as CaptureDeviceError {
            switch error {
            case .VideoDeviceNotAvailable(let description),
                .VideoSizeNotSupported(let description):
                print(description)
            }
        } catch {
            print("Unexpected error: \(error)")
        }
    }

    /**
    Initializes a `WhipClient` object.
    
    - Parameter serverUrl: A URL of the WHIP server.
    - Parameter configurationOptions: Additional configuration options, such as a STUN server URL or authorization token.
    - Parameter videoDevice: A device that will be used to stream video.
    
    - Returns: A `WhipClient` object.
    */
    public init(
        configOptions: WhipConfigurationOptions
    ) {
        self.configOptions = configOptions
        super.init(stunServerUrl: configOptions.stunServerUrl)
        setUpPeerConnection()
    }

    /**
    Connects the client to the WHIP server using WebRTC Peer Connection.
    
    - Throws: `SessionNetworkError.ConfigurationError` if the `stunServerUrl` parameter
        of the initial configuration is incorrect, which leads to `peerConnection` being nil or in any other case where there has been an error in creating the `peerConnection`
    */
    public override func connect(_ connectOptions: ClientConnectOptions) async throws {
        try await super.connect(connectOptions)
        if !self.isConnectionSetUp {
            setUpPeerConnection()
        } else if self.isConnectionSetUp && self.peerConnection == nil {
            throw SessionNetworkError.ConfigurationError(
                description: "Failed to establish RTCPeerConnection. Check initial configuration")
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
            self.videoCapturer?.stopCapture()
            self.videoCapturer = nil
            self.videoSource = nil
            self.videoTrack = nil
        }
    }

    /**
    Gets the video and audio devices, prepares them, starts capture and adds it to the Peer Connection.
    
    - Throws: `AVCaptureDeviceError.VideoDeviceNotAvailable` if there is no video device available.
    */
    private func setUpVideoAndAudioDevices() throws {
        let audioEnabled = configOptions.audioEnabled
        let videoEnabled = configOptions.videoEnabled
        let videoDevice = configOptions.videoDevice
        let videoParameters = configOptions.videoParameters

        if !audioEnabled && !videoEnabled {
            logger.warning(
                "Both audioEnabled and videoEnabled are set to false, what will result in no stream at all. Consider changing one of the options to true."
            )
        }

        let sendEncodings = [RTCRtpEncodingParameters.create(active: true)]
        let localStreamId = UUID().uuidString

        if videoEnabled {
            let videoSource = peerConnectionFactory!.videoSource()
            self.videoSource = videoSource
            let videoCapturer = RTCCameraVideoCapturer(delegate: videoSource)
            self.videoCapturer = videoCapturer
            let videoTrackId = UUID().uuidString

            let videoTrack = peerConnectionFactory!.videoTrack(with: videoSource, trackId: videoTrackId)
            videoTrack.isEnabled = true

            let (format, fps) = setVideoSize(
                device: videoDevice, videoParameters: (videoParameters))

            videoCapturer.startCapture(with: videoDevice, format: format, fps: fps) { error in
                if let error = error {
                    print("Error starting the video capture: \(error)")
                } else {
                    print("Video capturing started")
                    DispatchQueue.main.async {
                        self.videoTrack = videoTrack
                    }
                }
            }

            let transceiverInit = RTCRtpTransceiverInit()
            transceiverInit.direction = RTCRtpTransceiverDirection.sendOnly
            transceiverInit.streamIds = [localStreamId]
            transceiverInit.sendEncodings = sendEncodings

            peerConnection?.addTransceiver(with: videoTrack, init: transceiverInit)

            self.videoTrack = videoTrack
        }

        if audioEnabled {
            let audioTrackId = UUID().uuidString
            let audioSource = self.peerConnectionFactory!.audioSource(with: nil)
            let audioTrack = self.peerConnectionFactory!.audioTrack(with: audioSource, trackId: audioTrackId)

            let audioTransceiverInit = RTCRtpTransceiverInit()
            audioTransceiverInit.direction = RTCRtpTransceiverDirection.sendOnly
            audioTransceiverInit.streamIds = [localStreamId]
            peerConnection?.addTransceiver(with: audioTrack, init: audioTransceiverInit)
            peerConnection?.enforceSendOnlyDirection()
        }

    }

    private func setVideoSize(device: AVCaptureDevice, videoParameters: VideoParameters) -> (
        selectedFormat: AVCaptureDevice.Format, fps: Int
    ) {
        let formats: [AVCaptureDevice.Format] = RTCCameraVideoCapturer.supportedFormats(for: device)

        let (targetWidth, targetHeight) = (
            videoParameters.dimensions.width,
            videoParameters.dimensions.height
        )

        var currentDiff = Int32.max
        var selectedFormat: AVCaptureDevice.Format = formats[0]
        var selectedDimension: Dimensions?
        for format in formats {
            let dimension = CMVideoFormatDescriptionGetDimensions(format.formatDescription)

            let diff = abs(targetWidth - dimension.width) + abs(targetHeight - dimension.height)
            if diff < currentDiff {
                selectedFormat = format
                currentDiff = diff
                selectedDimension = dimension
            }
        }

        guard let dimension = selectedDimension else {
            fatalError("Could not get dimensions for video capture")
        }

        let fps = videoParameters.maxFps

        // discover FPS limits
        var minFps = 60
        var maxFps = 0
        for fpsRange in selectedFormat.videoSupportedFrameRateRanges {
            minFps = min(minFps, Int(fpsRange.minFrameRate))
            maxFps = max(maxFps, Int(fpsRange.maxFrameRate))
        }
        if fps < minFps || fps > maxFps {
            fatalError("unsported requested frame rate of (\(minFps) - \(maxFps)")
        }

        return (selectedFormat, fps)
    }

    public static func getCaptureDevices() -> [AVCaptureDevice] {
        return RTCCameraVideoCapturer.captureDevices()
    }

    // MARK: - Codec Management

    /**
     Gets the names of supported sender video codecs.
    
     - Returns: Array of supported video codec names
     */
    public func getSupportedSenderVideoCodecsNames() -> [String] {
        guard let capabilities = peerConnectionFactory?.rtpSenderCapabilities(forKind: kRTCMediaStreamTrackKindVideo)
        else {
            return []
        }

        return capabilities.codecs.map { $0.name }
    }

    /**
     Gets the names of supported sender audio codecs.
    
     - Returns: Array of supported audio codec names
     */
    public func getSupportedSenderAudioCodecsNames() -> [String] {
        guard let capabilities = peerConnectionFactory?.rtpSenderCapabilities(forKind: kRTCMediaStreamTrackKindAudio)
        else {
            return []
        }

        return capabilities.codecs.map { $0.name }
    }

    /**
     Sets preferred video codecs for sending.
    
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
                    mediaType: kRTCMediaStreamTrackKindVideo
                )
            }
        }
    }

    /**
     Sets preferred audio codecs for sending.
    
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
                    mediaType: kRTCMediaStreamTrackKindAudio
                )
            }
        }
    }
}
