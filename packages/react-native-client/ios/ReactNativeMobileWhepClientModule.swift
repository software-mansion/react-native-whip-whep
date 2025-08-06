import ExpoModulesCore
import MobileWhipWhepClient
import WebRTC

public class ReactNativeMobileWhepClientModule: Module, PlayerListener, ReconnectionManagerListener {
    static var whepClient: WhepClient? = nil
    static var whipClient: WhipClient? = nil
    static var onTrackUpdateListeners: [OnTrackUpdateListener] = []

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
        Name("ReactNativeMobileWhepClient")

        Events(EmitableEvent.allEvents)
      
        Property("cameras") {
            return self.getCaptureDevices()
        }
      
      Property("whepPeerConnectionState") {
        return ReactNativeMobileWhepClientModule.whepClient?.peerConnectionState?.stringValue
      }
      
      Property("whipPeerConnectionState") {
        return ReactNativeMobileWhepClientModule.whipClient?.peerConnectionState?.stringValue
      }

        Function("createWhepClient") { (configurationOptions: [String: AnyObject]?) in
          guard ReactNativeMobileWhepClientModule.whepClient == nil else {
            emit(event: .warning(message: "WHEP client already exists. You must disconnect before creating a new one."))
            return
          }
            let options = WhepConfigurationOptions(
              audioEnabled: configurationOptions?["audioEnabled"] as? Bool ?? true,
              videoEnabled: configurationOptions?["videoEnabled"] as? Bool ?? true,
              stunServerUrl: configurationOptions?["stunServerUrl"] as? String
            )
          
            ReactNativeMobileWhepClientModule.whepClient = WhepClient(configOptions: options)
            ReactNativeMobileWhepClientModule.whepClient?.delegate = self
            ReactNativeMobileWhepClientModule.whepClient?.reconnectionListener = self
            ReactNativeMobileWhepClientModule.whepClient?.onConnectionStateChanged = { [weak self] newState in
              self?.emit(event: .whepPeerConnectionStateChanged(status: newState))
            }
        }

        AsyncFunction("connectWhep") { (serverUrl: String, authToken: String?) in
            guard let client = ReactNativeMobileWhepClientModule.whepClient else {
                throw Exception(
                                name: "E_WHEP_CLIENT_NOT_FOUND",
                                description: "WHEP client not found. Make sure it was initialized properly.")
            }
          guard let url = URL(string: serverUrl) else {
            throw Exception(
              name: "E_INVALID_SERVER_URL",
              description: "Invalid server URL. Make sure the address is correct.")
          }
          try await client.connect(.init(serverUrl: url, authToken: authToken))
        }

        Function("disconnectWhep") {
          ReactNativeMobileWhepClientModule.whepClient?.disconnect()
          ReactNativeMobileWhepClientModule.whepClient = nil
        }

        Function("pauseWhep") {
            guard let client = ReactNativeMobileWhepClientModule.whepClient else {
                throw Exception(
                                name: "E_WHEP_CLIENT_NOT_FOUND",
                                description: "WHEP client not found. Make sure it was initialized properly.")
            }
            client.pause()
        }

        Function("unpauseWhep") {
            guard let client = ReactNativeMobileWhepClientModule.whepClient else {
                throw Exception(
                                name: "E_WHEP_CLIENT_NOT_FOUND",
                                description: "WHEP client not found. Make sure it was initialized properly.")
            }
            client.unpause()
        }

        Function("createWhipClient") { (configurationOptions: [String: AnyObject]?) in
            guard ReactNativeMobileWhepClientModule.whipClient == nil else {
              emit(event: .warning(message: "WHIP client already exists. You must disconnect before creating a new one."))
              return
            }
          
          guard let deviceId = configurationOptions?["videoDeviceId"] as? String, let avCaptureDevice = AVCaptureDevice(uniqueID: deviceId) else {
            throw Exception(
              name: "E_INVALID_VIDEO_DEVICE_ID",
              description: "Invalid video device ID. Make sure the device ID is correct.")
          }
          
          let options = WhipConfigurationOptions(
            audioEnabled: configurationOptions?["audioEnabled"] as? Bool ?? true,
            videoEnabled: configurationOptions?["videoEnabled"] as? Bool ?? true,
            videoDevice: avCaptureDevice,
            videoParameters: configurationOptions?["videoParameters"] as? VideoParameters ?? VideoParameters.presetHD169,
            stunServerUrl: configurationOptions?["stunServerUrl"] as? String)
          
          guard options.videoEnabled, PermissionUtils.hasCameraPermission() else {
              emit(event: .warning(message: "Camera permission not granted. Cannot initialize WhipClient."))
              return
          }
          
          guard options.audioEnabled, PermissionUtils.hasMicrophonePermission() else {
              emit(event: .warning(message: "Microphone permission not granted. Cannot initialize WhipClient."))
              return
          }

            ReactNativeMobileWhepClientModule.whipClient = WhipClient(configOptions: options)
            ReactNativeMobileWhepClientModule.whipClient?.delegate = self
            ReactNativeMobileWhepClientModule.whipClient?.onConnectionStateChanged = { [weak self] newState in
              self?.emit(event: .whipPeerConnectionStateChanged(status: newState))
            }
        }

        AsyncFunction("connectWhip") { (serverUrl: String, authToken: String?) in
          guard let client = ReactNativeMobileWhepClientModule.whipClient else {
            throw Exception(
              name: "E_WHIP_CLIENT_NOT_FOUND",
              description: "WHIP client not found. Make sure it was initialized properly.")
          }
          
          guard let url = URL(string: serverUrl) else {
            throw Exception(
              name: "E_INVALID_SERVER_URL",
              description: "Invalid server URL. Make sure the address is correct.")
          }
          try await client.connect(.init(serverUrl: url, authToken: authToken))
        }

        Function("disconnectWhip") {
          ReactNativeMobileWhepClientModule.whipClient?.disconnect()
          ReactNativeMobileWhepClientModule.whipClient = nil
        }
        
    }
    
    public func onTrackAdded(track: RTCVideoTrack) {
        ReactNativeMobileWhepClientModule.onTrackUpdateListeners.forEach {
            $0.onTrackUpdate()
        }
    }
    
    public func onTrackRemoved(track: RTCVideoTrack) {
        
    }
    
    public func onReconnectionStarted() {
      emit(event: .reconnectionStatusChanged(reconnectionStatus: .reconnectionStarted))
    }
    
    public func onReconnected() {
      emit(event: .reconnectionStatusChanged(reconnectionStatus: .reconnected))
    }
    
    public func onReconnectionRetriesLimitReached() {
      emit(event: .reconnectionStatusChanged(reconnectionStatus: .reconnectionRetriesLimitReached))
    }
}
