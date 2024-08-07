import WebRTC
import os

public class WhipClient: ClientBase {
    var videoCapturer: RTCCameraVideoCapturer?
    var videoSource: RTCVideoSource?
    var audioDevice: AVCaptureDevice?
    var videoDevice: AVCaptureDevice?

    func setUpPeerConnection() {
        Helper.setUpPeerConnection(player: self, configurationOptions: self.configurationOptions)

        do {
            try setUpVideoAndAudioDevices()
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
    Initializes a `WhipClientPlayer` object.

    - Parameter serverUrl: A URL of the WHIP server.
    - Parameter authToken: An authorization token of the WHIP server.
    - Parameter configurationOptions: Additional configuration options, such as a STUN server URL.
    - Parameter audioDevice: A device that will be used to stream audio.
    - Parameter videoDevice: A device that will be used to stream video.

    - Returns: A `WhipClientPlayer` object.
    */
    public init(
        serverUrl: URL, configurationOptions: ConfigurationOptions? = nil,
        audioDevice: AVCaptureDevice? = nil, videoDevice: AVCaptureDevice? = nil
    ) {
        self.audioDevice = audioDevice
        self.videoDevice = videoDevice
        super.init(serverUrl: serverUrl, configurationOptions: configurationOptions)
        setUpPeerConnection()
    }

    /**
    Connects the client to the WHIP server using WebRTC Peer Connection.

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
            self.videoCapturer?.stopCapture()
            self.videoCapturer = nil
            self.videoSource = nil
            self.videoTrack = nil
        }
    }

    /**
    Gets the video and audio devices, prepares them, starts capture and adds it to the Peer Connection.

    - Throws: `AVCaptureDeviceError.AudioDeviceNotAvailable` if no audio device has been passed to the initializer and `AVCaptureDeviceError.VideoDeviceNotAvailable` if there is no video device.
    */
    private func setUpVideoAndAudioDevices() throws {
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
                DispatchQueue.main.async {
                    self.videoTrack = videoTrack
                }
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
}
