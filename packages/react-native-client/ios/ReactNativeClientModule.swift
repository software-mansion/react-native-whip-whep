import ExpoModulesCore
import MobileWhepClient
import WebRTC

public class ReactNativeClientModule: Module, PlayerListener {
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
    
    private func getCaptureDevices() -> [String] {
        let captureDevices = RTCCameraVideoCapturer.captureDevices()
        print(captureDevices)
        return captureDevices.map { $0.uniqueID }
    }

    public func definition() -> ModuleDefinition {
        Name("ReactNativeClient")

        Events("trackAdded")

        Function("createWhepClient") { (serverUrl: String, configurationOptions: [String: AnyObject]?) in
            guard let url = URL(string: serverUrl) else {
                throw NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
            }
            
            let options = ConfigurationOptions(
                authToken: configurationOptions?["authToken"] as? String,
                stunServerUrl: configurationOptions?["stunServerUrl"] as? String,
                audioEnabled: configurationOptions?["audioEnabled"] as? Bool ?? true,
                videoEnabled: configurationOptions?["videoEnabled"] as? Bool ?? true,
                videoParameters: try! getVideoParametersFromOptions(createOptions: configurationOptions?["videoParameters"] as? String ?? "HD43"))

            ReactNativeClientModule.whepClient = WhepClient(serverUrl: url, configurationOptions: options)
            ReactNativeClientModule.whepClient?.delegate = self
        }

        AsyncFunction("connectWhep") {
            guard let client = ReactNativeClientModule.whepClient else {
                throw NSError(domain: "", code: 404, userInfo: [NSLocalizedDescriptionKey: "Client not found"])
            }
            try await client.connect()
        }

        Function("disconnectWhep") {
            guard let client = ReactNativeClientModule.whepClient else {
                throw NSError(domain: "", code: 404, userInfo: [NSLocalizedDescriptionKey: "Client not found"])
            }
            client.disconnect()
        }

        Function("createWhipClient") { (serverUrl: String, configurationOptions: [String: AnyObject]?, videoDevice: String) in
            guard let url = URL(string: serverUrl) else {
                throw NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
            }

            let options = ConfigurationOptions(
                authToken: configurationOptions?["authToken"] as? String,
                stunServerUrl: configurationOptions?["stunServerUrl"] as? String,
                audioEnabled: configurationOptions?["audioEnabled"] as? Bool ?? true,
                videoEnabled: configurationOptions?["videoEnabled"] as? Bool ?? true,
                videoParameters: configurationOptions?["videoParameters"] as? VideoParameters ?? VideoParameters.presetFHD43
            )

            ReactNativeClientModule.whipClient = WhipClient(serverUrl: url, configurationOptions: options, videoDevice: AVCaptureDevice(uniqueID: videoDevice))
            ReactNativeClientModule.whipClient?.delegate = self
        }

        AsyncFunction("connectWhip") {
            guard let client = ReactNativeClientModule.whipClient else {
                throw NSError(domain: "", code: 404, userInfo: [NSLocalizedDescriptionKey: "Client not found"])
            }
            try await client.connect()
        }

        Function("disconnectWhip") {
            guard let client = ReactNativeClientModule.whipClient else {
                throw NSError(domain: "", code: 404, userInfo: [NSLocalizedDescriptionKey: "Client not found"])
            }
            client.disconnect()
        }
        
        Property("getCaptureDevices") {
           return getCaptureDevices()
        }
    }
    
    public func onTrackAdded(track: RTCVideoTrack) {
        self.sendEvent("trackAdded", [
            track.trackId : track.kind,
        ])
        ReactNativeClientModule.onTrackUpdateListeners.forEach {
            $0.onTrackUpdate(track: track)
        }
    }
    
    public func onTrackRemoved(track: RTCVideoTrack) {
        
    }
}
