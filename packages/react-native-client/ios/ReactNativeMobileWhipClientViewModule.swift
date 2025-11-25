import ExpoModulesCore
import MobileWhipWhepClient
import WebRTC

public class ReactNativeMobileWhipClientViewModule: Module {
    struct ConfigurationOptions: Record {
        @Field
        var audioEnabled: Bool?
        @Field
        var videoEnabled: Bool?
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

    public func definition() -> ModuleDefinition {
        Name("ReactNativeMobileWhipClientViewModule")

        Events(WhipEmitableEvent.allEvents)

        Property("cameras") {
            return self.getCaptureDevices()
        }

        View(ReactNativeMobileWhipClientView.self) {
            AsyncFunction("initializeCamera") {
                (view: ReactNativeMobileWhipClientView, options: ConfigurationOptions, videoDeviceId: String?) in
                let audioEnabled = options.audioEnabled ?? true
                let videoEnabled = options.videoEnabled ?? true

                guard audioEnabled || videoEnabled else {
                    throw Exception(
                        name: "Video and audio disabled",
                        description: "You need to enable either video or audio to start streaming.")
                }

                if videoEnabled {
                    guard await PermissionUtils.requestCameraPermission() else {
                        self.emit(event: .warning(message: "Camera permission not granted."))
                        return
                    }
                }

                if audioEnabled {
                    guard await PermissionUtils.requestMicrophonePermission() else {
                        self.emit(event: .warning(message: "Microphone permission not granted."))
                        return
                    }
                }

                try await view.createWhipClient(options: options) { [weak self] newState in
                    self?.emit(event: .whipPeerConnectionStateChanged(status: newState))
                }

                if videoEnabled {
                    try await view.startCapture(videoDeviceId: videoDeviceId)
                }
            }

            AsyncFunction("initializeScreenShare") {
                (view: ReactNativeMobileWhipClientView, options: ConfigurationOptions) in
                let audioEnabled = options.audioEnabled ?? true

                if audioEnabled {
                    guard await PermissionUtils.requestMicrophonePermission() else {
                        self.emit(event: .warning(message: "Microphone permission not granted."))
                        return
                    }
                }

                try await view.createWhipClient(options: options) { [weak self] newState in
                    self?.emit(event: .whipPeerConnectionStateChanged(status: newState))
                }

                try await view.startScreenShare()
            }

            AsyncFunction("connect") { (view: ReactNativeMobileWhipClientView, options: ConnectionOptions) in
                try await view.connect(options: options)
            }

            AsyncFunction("flipCamera") { (view: ReactNativeMobileWhipClientView) in
                try await view.flipCamera()
            }

            AsyncFunction("switchCamera") { (view: ReactNativeMobileWhipClientView, deviceId: String) in
                try await view.switchCamera(deviceId: deviceId)
            }

            AsyncFunction("disconnect") { (view: ReactNativeMobileWhipClientView) in
                try await view.disconnect()
            }

            AsyncFunction("setPreferredSenderVideoCodecs") {
                (view: ReactNativeMobileWhipClientView, preferredCodecs: [String]?) in
                view.setPreferredVideoCodecs(preferredCodecs: preferredCodecs)
            }

            AsyncFunction("setPreferredSenderAudioCodecs") {
                (view: ReactNativeMobileWhipClientView, preferredCodecs: [String]?) in
                view.setPreferredAudioCodecs(preferredCodecs: preferredCodecs)
            }

            AsyncFunction("getSupportedSenderVideoCodecsNames") {
                WhipClient.getSupportedSenderVideoCodecsNames()
            }

            AsyncFunction("getSupportedSenderAudioCodecsNames") {
                WhipClient.getSupportedSenderAudioCodecsNames()
            }

            AsyncFunction("currentCameraDeviceId") { (view: ReactNativeMobileWhipClientView) in
                view.getCurrentCameraDeviceId()
            }
        }
    }
}
