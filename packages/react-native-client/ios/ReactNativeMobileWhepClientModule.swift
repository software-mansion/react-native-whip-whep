import ExpoModulesCore
import MobileWhipWhepClient
import WebRTC

public class ReactNativeMobileWhepClientModule: Module, PlayerListener, ReconnectionManagerListener {
  static var whepClient: WhepClient? = nil {
    didSet {
      print("## WHEP was set in module")
    }
  }
    static var onTrackUpdateListeners: [OnTrackUpdateListener] = []

    public func definition() -> ModuleDefinition {
        Name("ReactNativeMobileWhepClient")

        Events(EmitableEvent.allEvents)
      
      Property("whepPeerConnectionState") {
        return ReactNativeMobileWhepClientModule.whepClient?.peerConnectionState?.stringValue
      }

        Function("createWhepClient") { (configurationOptions: [String: AnyObject]?, preferredVideoCodecs: [String]?, preferredAudioCodecs: [String]?) in
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

        AsyncFunction("disconnectWhep") {
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
      

        // MARK: - Codec Methods
        
        Function("getSupportedSenderVideoCodecsNames") {
          return WhipClient.getSupportedSenderVideoCodecsNames()
        }

        Function("getSupportedSenderAudioCodecsNames") {
          return WhipClient.getSupportedSenderAudioCodecsNames()
        }

        Function("getSupportedReceiverVideoCodecsNames") {
          return WhepClient.getSupportedReceiverVideoCodecsNames()
        }

        Function("getSupportedReceiverAudioCodecsNames") {
          return WhepClient.getSupportedReceiverAudioCodecsNames()
        }

      // I think those are unused

        Function("setPreferredReceiverVideoCodecs") { (preferredCodecs: [String]?) in
            ReactNativeMobileWhepClientModule.whepClient?.setPreferredVideoCodecs(preferredCodecs: preferredCodecs)
        }

        Function("setPreferredReceiverAudioCodecs") { (preferredCodecs: [String]?) in
            ReactNativeMobileWhepClientModule.whepClient?.setPreferredAudioCodecs(preferredCodecs: preferredCodecs)
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
