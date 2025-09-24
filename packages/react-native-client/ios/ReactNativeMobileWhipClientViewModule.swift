import ExpoModulesCore
import MobileWhipWhepClient
import WebRTC

public class ReactNativeMobileWhipClientViewModule: Module {
  private var whipClient: WhipClient?
  
  private func createWhipClient(
    audioEnabled: Bool,
    videoEnabled: Bool,
    videoDeviceId: String?,
    videoParameters: VideoParameters,
    stunServerUrl: String?,
    preferredVideoCodecs: [String]?,
    preferredAudioCodecs: [String]?
  ) throws {
    guard let videoDeviceId, let avCaptureDevice = AVCaptureDevice(uniqueID: videoDeviceId) else {
      throw Exception(
        name: "E_INVALID_VIDEO_DEVICE_ID",
        description: "Invalid video device ID. Make sure the device ID is correct.")
    }
    
    let options = WhipConfigurationOptions(
      audioEnabled: audioEnabled,
      videoEnabled: videoEnabled,
      videoDevice: avCaptureDevice,
      videoParameters: videoParameters,
      stunServerUrl: stunServerUrl,
      preferredVideoCodecs: preferredVideoCodecs ?? [],
      preferredAudioCodecs: preferredAudioCodecs ?? []
    )
    
    guard options.videoEnabled, PermissionUtils.hasCameraPermission() else {
        emit(event: .warning(message: "Camera permission not granted. Cannot initialize WhipClient."))
        return
    }
    
    guard options.audioEnabled, PermissionUtils.hasMicrophonePermission() else {
        emit(event: .warning(message: "Microphone permission not granted. Cannot initialize WhipClient."))
        return
    }

      whipClient = WhipClient(configOptions: options)
      whipClient?.onConnectionStateChanged = { [weak self] newState in
        self?.emit(event: .whipPeerConnectionStateChanged(status: newState))
      }
  }
  
  private func emit(event: EmitableEvent) {
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
  
  private var audioEnabled: Bool = true
  private var videoEnabled: Bool = true
  private var videoDeviceId: String?
  private var videoParameters: VideoParameters = .presetHD169
  private var stunServerUrl: String?
  private var preferredVideoCodecs: [String] = []
  private var preferredAudioCodecs: [String] = []
  
  public func definition() -> ModuleDefinition {
    Name("ReactNativeMobileWhipClientViewModule")
    
    Events(EmitableEvent.allEvents)
    
    Property("cameras") {
        return self.getCaptureDevices()
    }
    
    Property("currentCameraDeviceId") {
      print("Getting currentCameraDeviceId: \(whipClient?.currentCameraDeviceId)")
      return whipClient?.currentCameraDeviceId
    }
    
    Property("whipPeerConnectionState") {
      return whipClient?.peerConnectionState?.stringValue
    }
    
    View(ReactNativeMobileWhipClientView.self) {
      OnViewDidUpdateProps { view in
        print("## OnViewDidUpdateProps WHIP")
        print("## audioEnabled: \(self.audioEnabled)")
        print("## videoEnabled: \(self.videoEnabled)")
        print("## videoDeviceId: \(self.videoDeviceId)")
        print("## videoParameters: \(self.videoParameters)")
        print("## stunServerUrl: \(self.stunServerUrl)")
        print("## preferredVideoCodecs: \(self.preferredVideoCodecs)")
        print("## preferredAudioCodecs: \(self.preferredAudioCodecs)")
        do {
          try self.createWhipClient(
            audioEnabled: self.audioEnabled,
            videoEnabled: self.videoEnabled,
            videoDeviceId: self.videoDeviceId,
            videoParameters: self.videoParameters,
            stunServerUrl: self.stunServerUrl,
            preferredVideoCodecs: self.preferredVideoCodecs,
            preferredAudioCodecs: self.preferredAudioCodecs
          )
          print(self.whipClient)
          view.player = self.whipClient
        } catch {
          print("## Dupa")
        }
      }
      Prop("audioEnabled") { (view: ReactNativeMobileWhipClientView, audioEnabled: Bool) in
        self.audioEnabled = audioEnabled
      }
      Prop("videoEnabled") { (view: ReactNativeMobileWhipClientView, videoEnabled: Bool) in
        self.videoEnabled = videoEnabled
      }
      Prop("videoDeviceId") { (view: ReactNativeMobileWhipClientView, videoDeviceId: String?) in
        self.videoDeviceId = videoDeviceId
      }
      Prop("videoParameters") { (view: ReactNativeMobileWhipClientView, videoParameters: String) in
        // Fix this
        self.videoParameters = videoParameters as? VideoParameters ?? VideoParameters.presetHD169
      }
      Prop("stunServerUrl") { (view: ReactNativeMobileWhipClientView, stunServerUrl: String?) in
        self.stunServerUrl = stunServerUrl
      }
      Prop("preferredVideoCodecs") { (view: ReactNativeMobileWhipClientView, preferredVideoCodecs: [String]) in
        self.preferredVideoCodecs = preferredVideoCodecs
      }
      Prop("preferredAudioCodecs") { (view: ReactNativeMobileWhipClientView, preferredAudioCodecs: [String]) in
        self.preferredAudioCodecs = preferredAudioCodecs
      }
      
      Prop("playerType") { (view: ReactNativeMobileWhipClientView, playerType: String) in
        view.playerType = playerType
      }
      
      AsyncFunction("connect") { (serverUrl: String, authToken: String?) in
        guard let client = self.whipClient else {
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
      
      AsyncFunction("flipCamera") {
        guard let client = self.whipClient else {
          throw Exception(
            name: "E_WHIP_CLIENT_NOT_FOUND",
            description: "WHIP client not found. Make sure it was initialized properly.")
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
        print("## Swithing camera to: \(deviceId)")
        guard let client = self.whipClient else {
          throw Exception(
            name: "E_WHIP_CLIENT_NOT_FOUND",
            description: "WHIP client not found. Make sure it was initialized properly.")
        }
        client.switchCamera(deviceId: deviceId)
      }
      
      AsyncFunction("disconnect") {
        try await self.whipClient?.disconnect()
      }
      
      // Figure out what to do with this
      AsyncFunction("cleanupWhip") {
        self.whipClient?.delegate = nil
        self.whipClient?.onConnectionStateChanged = nil
        self.whipClient = nil
      }
    }
  }
}
