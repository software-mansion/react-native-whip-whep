import ExpoModulesCore
import MobileWhipWhepClient
import WebRTC

public class ReactNativeMobileWhipClientViewModule: Module {
    private var whipClient: WhipClient?

    struct ConfigurationOptions: Record {
        @Field
        var audioEnabled: Bool?
        @Field
        var videoEnabled: Bool?
        @Field
        var videoDeviceId: String?
        @Field
        var videoParameters: String?
        @Field
        var stunServerUrl: String?
        @Field
        var preferredVideoCodecs: [String]?
        @Field
        var preferredAudioCodecs: [String]?
    }

    struct ConnectionOptions: Record {
        @Field
        var serverUrl: String
        @Field
        var authToken: String?
    }

    private func createWhipClient(options: ConfigurationOptions) throws {
        guard let videoDeviceId = options.videoDeviceId,
            let avCaptureDevice = AVCaptureDevice(uniqueID: videoDeviceId)
        else {
            throw Exception(
                name: "E_INVALID_VIDEO_DEVICE_ID",
                description: "Invalid video device ID. Make sure the device ID is correct.")
        }

        let parsedVideoParameters: VideoParameters

        if let optionsVideoParameters = options.videoParameters,
            let parameters = try? self.getVideoParametersFromOptions(
                createOptions: optionsVideoParameters)
        {
            parsedVideoParameters = parameters
        } else {
            parsedVideoParameters = VideoParameters.presetHD169
        }

        let options = WhipConfigurationOptions(
            audioEnabled: options.audioEnabled ?? true,
            videoEnabled: options.videoEnabled ?? true,
            videoDevice: avCaptureDevice,
            videoParameters: parsedVideoParameters,
            stunServerUrl: options.stunServerUrl,
            preferredVideoCodecs: options.preferredVideoCodecs ?? [],
            preferredAudioCodecs: options.preferredAudioCodecs ?? []
        )

        guard options.videoEnabled, PermissionUtils.hasCameraPermission() else {
            emit(
                event: .warning(
                    message: "Camera permission not granted. Cannot initialize WhipClient."))
            return
        }

        guard options.audioEnabled, PermissionUtils.hasMicrophonePermission() else {
            emit(
                event: .warning(
                    message: "Microphone permission not granted. Cannot initialize WhipClient."))
            return
        }

        whipClient = WhipClient(configOptions: options)
        whipClient?.onConnectionStateChanged = { [weak self] newState in
            self?.emit(event: .whipPeerConnectionStateChanged(status: newState))
        }
    }

    private func emit(event: WhipEmitableEvent) {
        DispatchQueue.main.async {
            self.sendEvent(event.event.name, event.data)
        }
    }

    private func getCaptureDevices() -> [[String: Any]] {
        let devices = RTCCameraVideoCapturer.captureDevices()
        return devices.map { device -> [String: Any] in
            let facingDirection =
                switch device.position {
                case .front: "front"
                case .back: "back"
                default: "unspecified"
                }
            return [
                "id": device.uniqueID,
                "name": device.localizedName,
                "facingDirection": facingDirection,
            ]
        }
    }

    private func getVideoParametersFromOptions(createOptions: String) throws -> VideoParameters {
        let preset: VideoParameters = {
            switch createOptions {
            case "QVGA169":
                return VideoParameters.presetQVGA169
            case "VGA169":
                return VideoParameters.presetVGA169
            case "VQHD169":
                return VideoParameters.presetQHD169
            case "HD169":
                return VideoParameters.presetHD169
            case "FHD169":
                return VideoParameters.presetFHD169
            case "QVGA43":
                return VideoParameters.presetQVGA43
            case "VGA43":
                return VideoParameters.presetVGA43
            case "VQHD43":
                return VideoParameters.presetQHD43
            case "HD43":
                return VideoParameters.presetHD43
            case "FHD43":
                return VideoParameters.presetFHD43
            default:
                return VideoParameters.presetVGA169
            }
        }()
        return preset
    }

    public func definition() -> ModuleDefinition {
        Name("ReactNativeMobileWhipClientViewModule")

        Events(WhipEmitableEvent.allEvents)

        Property("cameras") {
            return self.getCaptureDevices()
        }

        View(ReactNativeMobileWhipClientView.self) {
            AsyncFunction("initializeCamera") { (view: ReactNativeMobileWhipClientView, options: ConfigurationOptions) in
                Task { @MainActor in
                    guard await PermissionUtils.requestCameraPermission() else {
                        self.emit(event: .warning(message: "Camera permission not granted."))
                        return
                    }
                    guard await PermissionUtils.requestMicrophonePermission() else {
                        self.emit(event: .warning(message: "Microphone permission not granted."))
                        return
                    }
                    
                    try self.createWhipClient(options: options)
                    view.player = self.whipClient
                }
            }

            AsyncFunction("connect") { (options: ConnectionOptions) in
                guard let client = self.whipClient else {
                    throw Exception(
                        name: "E_WHIP_CLIENT_NOT_FOUND",
                        description: "WHIP client not found. Make sure it was initialized properly."
                    )
                }

                guard let url = URL(string: options.serverUrl) else {
                    throw Exception(
                        name: "E_INVALID_SERVER_URL",
                        description: "Invalid server URL. Make sure the address is correct.")
                }
                try await client.connect(.init(serverUrl: url, authToken: options.authToken))
            }

            AsyncFunction("flipCamera") {
                guard let client = self.whipClient else {
                    throw Exception(
                        name: "E_WHIP_CLIENT_NOT_FOUND",
                        description: "WHIP client not found. Make sure it was initialized properly."
                    )
                }

                guard let currentCameraId = self.whipClient?.currentCameraDeviceId else {
                    throw Exception(
                        name: "E_CAMERA_NOT_FOUND",
                        description: "No camera found.")
                }

                let cameras = RTCCameraVideoCapturer.captureDevices()

                let currentCamera = cameras.first { device in
                    device.uniqueID == currentCameraId
                }

                let oppositeCamera = cameras.first { device in
                    device.position != currentCamera?.position
                }

                guard let oppositeCamera else {
                    throw Exception(
                        name: "E_CAMERA_NOT_FOUND",
                        description: "No camera found.")
                }

                client.switchCamera(deviceId: oppositeCamera.uniqueID)
            }

            AsyncFunction("switchCamera") { (deviceId: String) in
                guard let client = self.whipClient else {
                    throw Exception(
                        name: "E_WHIP_CLIENT_NOT_FOUND",
                        description: "WHIP client not found. Make sure it was initialized properly."
                    )
                }
                client.switchCamera(deviceId: deviceId)
            }

            AsyncFunction("disconnect") {
                try await self.whipClient?.disconnect()
            }

            AsyncFunction("cleanup") {
                self.whipClient?.delegate = nil
                self.whipClient?.onConnectionStateChanged = nil
                self.whipClient = nil
            }

            AsyncFunction("setPreferredSenderVideoCodecs") { (preferredCodecs: [String]?) in
                self.whipClient?.setPreferredVideoCodecs(preferredCodecs: preferredCodecs)
            }

            AsyncFunction("setPreferredSenderAudioCodecs") { (preferredCodecs: [String]?) in
                self.whipClient?.setPreferredAudioCodecs(preferredCodecs: preferredCodecs)
            }

            AsyncFunction("getSupportedSenderVideoCodecsNames") {
                WhipClient.getSupportedSenderVideoCodecsNames()
            }

            AsyncFunction("getSupportedSenderAudioCodecsNames") {
                WhipClient.getSupportedSenderAudioCodecsNames()
            }

            AsyncFunction("currentCameraDeviceId") {
                self.whipClient?.currentCameraDeviceId
            }
        }
    }
}
