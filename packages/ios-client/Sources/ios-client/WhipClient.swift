import WebRTC
import ReplayKit
import os

public struct WhipConfigurationOptions {
    public let audioEnabled: Bool
    public let videoEnabled: Bool
    public var videoDevice: AVCaptureDevice
    public let videoParameters: VideoParameters
    public let stunServerUrl: String?
    public let preferredVideoCodecs: [String]
    public let preferredAudioCodecs: [String]

    public init(
        audioEnabled: Bool = true, videoEnabled: Bool = true, videoDevice: AVCaptureDevice,
        videoParameters: VideoParameters, stunServerUrl: String?, preferredVideoCodecs: [String] = [],
        preferredAudioCodecs: [String] = []
    ) {
        self.audioEnabled = audioEnabled
        self.videoEnabled = videoEnabled
        self.videoDevice = videoDevice
        self.videoParameters = videoParameters
        self.stunServerUrl = stunServerUrl
        self.preferredVideoCodecs = preferredVideoCodecs
        self.preferredAudioCodecs = preferredAudioCodecs
    }
}

public class WhipClient: ClientBase {
    private var configOptions: WhipConfigurationOptions
    private var videoCapturer: RTCCameraVideoCapturer?
    private var videoSource: RTCVideoSource?
    
    private var broadcastScreenShareReceiver: BroadcastScreenShareReceiver?
    private var broadcastScreenShareCapturer: BroadcastScreenShareCapturer?

    public var currentCameraDeviceId: String?
    public var isScreenShareOn: Bool = false

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

    deinit {
        cleanup()
    }

    override func setUpPeerConnection() throws {
        try super.setUpPeerConnection()

        let audioEnabled = configOptions.audioEnabled
        let videoEnabled = configOptions.videoEnabled

        if !audioEnabled && !videoEnabled {
            logger.warning(
                "Both audioEnabled and videoEnabled are set to false, what will result in no stream at all. Consider changing one of the options to true."
            )
        }

        let sendEncodings = [RTCRtpEncodingParameters.create(active: true)]
        let localStreamId = UUID().uuidString

        if let videoTrack = self.videoTrack, videoEnabled {
            let transceiverInit = RTCRtpTransceiverInit()
            transceiverInit.direction = RTCRtpTransceiverDirection.sendOnly
            transceiverInit.streamIds = [localStreamId]
            transceiverInit.sendEncodings = sendEncodings

            let transceiver = peerConnection?.addTransceiver(with: videoTrack, init: transceiverInit)
            setCodecPreferencesIfAvailable(
                transceiver: transceiver,
                preferredCodecs: configOptions.preferredVideoCodecs,
                mediaType: kRTCMediaStreamTrackKindVideo
            )
        }

        if let audioTrack = self.audioTrack, audioEnabled {
            let audioTransceiverInit = RTCRtpTransceiverInit()
            audioTransceiverInit.direction = RTCRtpTransceiverDirection.sendOnly
            audioTransceiverInit.streamIds = [localStreamId]
            let transceiver = peerConnection?.addTransceiver(with: audioTrack, init: audioTransceiverInit)
            peerConnection?.enforceSendOnlyDirection()
            setCodecPreferencesIfAvailable(
                transceiver: transceiver,
                preferredCodecs: configOptions.preferredAudioCodecs,
                mediaType: kRTCMediaStreamTrackKindAudio
            )

            let audioSession = RTCAudioSession.sharedInstance()
            audioSession.lockForConfiguration()
            let config = RTCAudioSessionConfiguration.webRTC()
            config.category = AVAudioSession.Category.playAndRecord.rawValue
            config.mode = videoEnabled ? AVAudioSession.Mode.videoChat.rawValue : AVAudioSession.Mode.voiceChat.rawValue
            try audioSession.setConfiguration(config, active: true)
            audioSession.unlockForConfiguration()
        }
    }

    /**
    Connects the client to the WHIP server using WebRTC Peer Connection.
    
    - Throws: `SessionNetworkError.ConfigurationError` if the `stunServerUrl` parameter
        of the initial configuration is incorrect, which leads to `peerConnection` being nil or in any other case where there has been an error in creating the `peerConnection`
    */
    public override func connect(_ connectOptions: ClientConnectOptions) async throws {
        try await super.connect(connectOptions)
        if !self.isConnectionSetUp {
            try setUpPeerConnection()
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
    public func disconnect() async throws {
        DispatchQueue.main.sync { [weak self] in
            self?.peerConnection?.close()
            self?.peerConnection = nil
            self?.isConnectionSetUp = false
        }
        try await disconnectResource()
    }

    public func cleanup() {
        peerConnection?.close()
        videoCapturer?.stopCapture()
    }

    public func disconnectResource() async throws {
        guard let connectOptions else {
            throw SessionNetworkError.ConnectionError(
                description:
                    "Connection not setup. Remember to call connect first.")
        }
        guard let patchEndpoint = self.patchEndpoint else {
            throw AttributeNotFoundError.PatchEndpointNotFound(
                description: "Patch endpoint not found. Make sure the SDP answer is correct.")
        }
        var components = URLComponents(string: connectOptions.serverUrl.absoluteString)
        components?.path = patchEndpoint

        let url = components?.url
        var request = URLRequest(url: url!)
        request.httpMethod = "DELETE"

        if let token = connectOptions.authToken {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let response: URLResponse
        (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            return
        }
        if httpResponse.statusCode < 200 || httpResponse.statusCode >= 300 {
            throw SessionNetworkError.ConnectionError(
                description:
                    "DELETE Failed, invalid response. Check if the server is up and running and the token and the server url is correct."
            )
        }
    }

    public func switchCamera(deviceId: String) {
        guard let videoCapturer else {
            logger.error("Switch camera failed, videoCapturer is nil")
            return
        }
        videoCapturer.stopCapture()

        let devices = RTCCameraVideoCapturer.captureDevices()

        if let device = devices.first(where: { $0.uniqueID == deviceId }) {
            configOptions.videoDevice = device
        } else {
            print("Device with ID \(deviceId) not found")
            return
        }

        startCapture()
    }

    private func setUpVideoAndAudioDevices() throws {
        let audioEnabled = configOptions.audioEnabled
        let videoEnabled = configOptions.videoEnabled

        if !audioEnabled && !videoEnabled {
            logger.warning(
                "Both audioEnabled and videoEnabled are set to false, what will result in no stream at all. Consider changing one of the options to true."
            )
        }

        if videoEnabled {
            let videoSource = WhipClient.peerConnectionFactory.videoSource()
            self.videoSource = videoSource
            let videoCapturer = RTCCameraVideoCapturer(delegate: videoSource, captureSession: AVCaptureSession())
            self.videoCapturer = videoCapturer
            let videoTrackId = UUID().uuidString

            let videoTrack = WhipClient.peerConnectionFactory.videoTrack(with: videoSource, trackId: videoTrackId)
            videoTrack.isEnabled = true

            startCapture()

            self.videoTrack = videoTrack
        }

        if audioEnabled {
            let audioTrackId = UUID().uuidString
            let audioSource = WhipClient.peerConnectionFactory.audioSource(with: nil)
            let audioTrack = WhipClient.peerConnectionFactory.audioTrack(with: audioSource, trackId: audioTrackId)

            self.audioTrack = audioTrack

        }

    }

    private func startCapture() {
        let videoDevice = configOptions.videoDevice
        let videoParameters = configOptions.videoParameters

        let (format, fps) = setVideoSize(
            device: videoDevice, videoParameters: (videoParameters))

        guard let videoCapturer else {
            logger.warning("No video capturer to start")
            return
        }

        videoCapturer.startCapture(with: videoDevice, format: format, fps: fps) { [weak self] error in
            if let error = error {
                print("Error starting the video capture: \(error)")
            } else {
                print("Video capturing started")
                self?.currentCameraDeviceId = videoDevice.uniqueID
            }
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
        for format in formats {
            let dimension = CMVideoFormatDescriptionGetDimensions(format.formatDescription)

            let diff = abs(targetWidth - dimension.width) + abs(targetHeight - dimension.height)
            if diff < currentDiff {
                selectedFormat = format
                currentDiff = diff
            }
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
    public static func getSupportedSenderVideoCodecsNames() -> [String] {
        let capabilities = WhipClient.peerConnectionFactory.rtpSenderCapabilities(
            forKind: kRTCMediaStreamTrackKindVideo)

        return capabilities.codecs.map { $0.name }
    }

    /**
     Gets the names of supported sender audio codecs.
    
     - Returns: Array of supported audio codec names
     */
    public static func getSupportedSenderAudioCodecsNames() -> [String] {
        let capabilities = WhipClient.peerConnectionFactory.rtpSenderCapabilities(
            forKind: kRTCMediaStreamTrackKindAudio)

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

    // MARK: - Screen Sharing

    /**
     Toggles screen sharing on or off.
     
     When screen sharing starts:
     - Camera capture is stopped
     - IPC server starts listening for frames from the broadcast extension
     - Video track switches to screen share source
     
     When screen sharing stops:
     - IPC server stops listening
     - Camera capture resumes
     - Video track switches back to camera source
     */
    public func toggleScreenShare() throws {
        guard let screenShareExtensionBundleId = Bundle.main.infoDictionary?["ScreenShareExtensionBundleId"] as? String else {
            throw ScreenSharingError.NoExtension(description: "No screen share extension bundle id set. Please set ScreenShareExtensionBundleId in Info.plist")
        }
        
        let appGroup = Bundle.main.object(forInfoDictionaryKey: "AppGroupName") as? String
            ?? "group.com.swmansion.mobilewhepclient"
        
        
        if isScreenShareOn {
            // Stop screen sharing
            broadcastScreenShareCapturer?.stopListening()
            isScreenShareOn = false
            
            // Resume camera capture
            startCapture()
            
            logger.info("Screen sharing stopped, camera resumed")
        } else {
            videoCapturer?.stopCapture()
            let videoSource = WhipClient.peerConnectionFactory.videoSource(forScreenCast: true)
            
            broadcastScreenShareReceiver = BroadcastScreenShareReceiver(
                onStart: { [weak self] in
                    guard let self, let videoSource = broadcastScreenShareCapturer?.source else { return }
                    
                    let webrtcTrack = WhipClient.peerConnectionFactory.videoTrack(with: videoSource, trackId: UUID().uuidString)
                    delegate?.onTrackAdded(track: webrtcTrack)
                },
                onStop: { [weak self] in
                    // handle stop
                    print("Stopped ??")
                }
            )
            
            broadcastScreenShareCapturer = BroadcastScreenShareCapturer(
                videoSource,
                appGroup: appGroup,
                videoParameters: .presetFHD169
            )
            broadcastScreenShareCapturer?.capturerDelegate = broadcastScreenShareReceiver
            broadcastScreenShareCapturer?.startListening()
            isScreenShareOn = true
            
            logger.info("Screen sharing started, camera stopped")
            // Note: The actual screen frames will come from the broadcast extension
            // via IPC once the user starts screen recording from the system picker
            
            DispatchQueue.main.async {
                RPSystemBroadcastPickerView.show(for: screenShareExtensionBundleId)
            }
        }
        
        DispatchQueue.main.async {
            RPSystemBroadcastPickerView.show(for: screenShareExtensionBundleId)
        }
    }
}
