import ExpoModulesCore
import MobileWhipWhepClient
import WebRTC

public class ReactNativeMobileWhepClientModule: Module, PlayerListener {
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

        Events("trackAdded")

        Function("createWhepClient") { (serverUrl: String, configurationOptions: [String: AnyObject]?) in
            guard let url = URL(string: serverUrl) else {
                throw Exception(
                                name: "E_INVALID_URL",
                                description: "Invalid server URL. Make sure the address in .env file is correct.")
            }
            
            let options = ConfigurationOptions(
                authToken: configurationOptions?["authToken"] as? String,
                stunServerUrl: configurationOptions?["stunServerUrl"] as? String,
                audioEnabled: configurationOptions?["audioEnabled"] as? Bool ?? true,
                videoEnabled: configurationOptions?["videoEnabled"] as? Bool ?? true,
                videoParameters: try! getVideoParametersFromOptions(createOptions: configurationOptions?["videoParameters"] as? String ?? "HD43"))

            ReactNativeMobileWhepClientModule.whepClient = WhepClient(serverUrl: url, configurationOptions: options)
            ReactNativeMobileWhepClientModule.whepClient?.delegate = self
        }

        AsyncFunction("connectWhep") {
            guard let client = ReactNativeMobileWhepClientModule.whepClient else {
                throw Exception(
                                name: "E_WHEP_CLIENT_NOT_FOUND",
                                description: "WHEP client not found. Make sure it was initialized properly.")
            }
            try await client.connect()
        }

        Function("disconnectWhep") {
            guard let client = ReactNativeMobileWhepClientModule.whepClient else {
                throw Exception(
                                name: "E_WHEP_CLIENT_NOT_FOUND",
                                description: "WHEP client not found. Make sure it was initialized properly.")
            }
            client.disconnect()
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

        Function("createWhipClient") { (serverUrl: String, configurationOptions: [String: AnyObject]?, videoDevice: String) in
            guard let url = URL(string: serverUrl) else {
                throw Exception(
                                name: "E_INVALID_URL",
                                description: "Invalid server URL. Make sure the address in .env file is correct.")
            }

            let options = ConfigurationOptions(
                authToken: configurationOptions?["authToken"] as? String,
                stunServerUrl: configurationOptions?["stunServerUrl"] as? String,
                audioEnabled: configurationOptions?["audioEnabled"] as? Bool ?? true,
                videoEnabled: configurationOptions?["videoEnabled"] as? Bool ?? true,
                videoParameters: configurationOptions?["videoParameters"] as? VideoParameters ?? VideoParameters.presetFHD43
            )

            ReactNativeMobileWhepClientModule.whipClient = WhipClient(serverUrl: url, configurationOptions: options, videoDevice: AVCaptureDevice(uniqueID: videoDevice))
            ReactNativeMobileWhepClientModule.whipClient?.delegate = self
        }

        AsyncFunction("connectWhip") {
            guard let client = ReactNativeMobileWhepClientModule.whipClient else {
                throw Exception(
                                name: "E_WHIP_CLIENT_NOT_FOUND",
                                description: "WHIP client not found. Make sure it was initialized properly.")
            }
            try await client.connect()
        }

        Function("disconnectWhip") {
            guard let client = ReactNativeMobileWhepClientModule.whipClient else {
                throw Exception(
                                name: "E_WHIP_CLIENT_NOT_FOUND",
                                description: "WHIP client not found. Make sure it was initialized properly.")
            }
            client.disconnect()
        }
        
        Property("cameras") {
            return self.getCaptureDevices()
        }
    }
    
    public func onTrackAdded(track: RTCVideoTrack) {
        self.sendEvent("trackAdded", [
            track.trackId : track.kind,
        ])
        ReactNativeMobileWhepClientModule.onTrackUpdateListeners.forEach {
            $0.onTrackUpdate()
        }
    }
    
    public func onTrackRemoved(track: RTCVideoTrack) {
        
    }
}
