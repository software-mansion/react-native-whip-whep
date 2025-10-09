import ExpoModulesCore
import MobileWhipWhepClient
import WebRTC

public class ReactNativeMobileWhepClientViewModule: Module, PlayerListener,
    ReconnectionManagerListener
{
    public func onReconnectionStarted() {
        emit(
            event: .reconnectionStatusChanged(
                reconnectionStatus: .reconnectionStarted
            )
        )
    }

    public func onReconnected() {
        emit(event: .reconnectionStatusChanged(reconnectionStatus: .reconnected))
    }

    public func onReconnectionRetriesLimitReached() {
        emit(
            event: .reconnectionStatusChanged(
                reconnectionStatus: .reconnectionRetriesLimitReached
            )
        )
    }

    public func onTrackAdded(track _: RTCVideoTrack) {
        for onTrackUpdateListener in onTrackUpdateListeners {
            onTrackUpdateListener.onTrackUpdate()
        }
    }

    public func onTrackRemoved(track _: RTCVideoTrack) {}

    private var whepClient: WhepClient?
    private var onTrackUpdateListeners: [OnTrackUpdateListener] = []

    private func emit(event: WhepEmitableEvent) {
        DispatchQueue.main.async {
            self.sendEvent(event.event.name, event.data)
        }
    }

    struct ConnectOptions: Record {
        @Field
        var serverUrl: String

        @Field
        var authToken: String?
    }

    public func definition() -> ModuleDefinition {
        Name("ReactNativeMobileWhepClientViewModule")

        Events(WhepEmitableEvent.allEvents)

        Property("whepPeerConnectionState") {
            self.whepClient?.peerConnectionState?.stringValue
        }

        View(ReactNativeMobileWhepClientView.self) {
            Prop("pipEnabled") {
                (view: ReactNativeMobileWhepClientView, pipEnabled: Bool) in
                view.pipEnabled = pipEnabled
            }
            Prop("autoStartPip") { (view: ReactNativeMobileWhepClientView, startAutomatically: Bool) in
                view.autoStartPip = startAutomatically
            }
            Prop("autoStopPip") { (view: ReactNativeMobileWhepClientView, stopAutomatically: Bool) in
                view.autoStopPip = stopAutomatically
            }
            Prop("pipSize") { (view: ReactNativeMobileWhepClientView, size: CGSize) in
                view.pipSize = size
            }

            AsyncFunction("createWhepClient") {
                (
                    view: ReactNativeMobileWhepClientView,
                    configurationOptions: [String: AnyObject]?,
                    _: [String]?,
                    _: [String]?
                ) in
                guard self.whepClient == nil else {
                    self.emit(
                        event: .warning(
                            message:
                                "WHEP client already exists. You must disconnect before creating a new one."
                        )
                    )
                    return
                }

                let options = WhepConfigurationOptions(
                    audioEnabled: configurationOptions?["audioEnabled"] as? Bool ?? true,
                    videoEnabled: configurationOptions?["videoEnabled"] as? Bool ?? true,
                    stunServerUrl: configurationOptions?["stunServerUrl"] as? String
                )

                self.whepClient = WhepClient(configOptions: options)
                self.whepClient?.delegate = self
                self.whepClient?.reconnectionListener = self
                self.whepClient?.onConnectionStateChanged = { [weak self] newState in
                    self?.emit(event: .whepPeerConnectionStateChanged(status: newState))
                }
                view.player = self.whepClient
                self.onTrackUpdateListeners.append(view)
            }

            AsyncFunction("connectWhep") { (connectOptions: ConnectOptions) in
                guard let client = self.whepClient else {
                    throw Exception(
                        name: "E_WHEP_CLIENT_NOT_FOUND",
                        description:
                            "WHEP client not found. Make sure it was initialized properly."
                    )
                }
                guard let url = URL(string: connectOptions.serverUrl) else {
                    throw Exception(
                        name: "E_INVALID_SERVER_URL",
                        description: "Invalid server URL. Make sure the address is correct."
                    )
                }

                try await client.connect(.init(serverUrl: url, authToken: connectOptions.authToken))
            }

            AsyncFunction("startPip") { (view: ReactNativeMobileWhepClientView) in
                view.pipController?.startPictureInPicture()
            }

            AsyncFunction("stopPip") { (view: ReactNativeMobileWhepClientView) in
                view.pipController?.stopPictureInPicture()
            }

            AsyncFunction("togglePip") { (view: ReactNativeMobileWhepClientView) in
                view.pipController?.togglePictureInPicture()
            }

            AsyncFunction("disconnectWhep") {
                self.whepClient?.disconnect()
            }

            AsyncFunction("cleanupWhep") { (view: ReactNativeMobileWhepClientView) in
                self.whepClient?.cleanup()

                view.player = nil
                self.onTrackUpdateListeners = []

                self.whepClient = nil
            }

            AsyncFunction("pauseWhep") {
                guard let client = self.whepClient else {
                    throw Exception(
                        name: "E_WHEP_CLIENT_NOT_FOUND",
                        description:
                            "WHEP client not found. Make sure it was initialized properly."
                    )
                }
                client.pause()
            }

            AsyncFunction("unpauseWhep") {
                guard let client = self.whepClient else {
                    throw Exception(
                        name: "E_WHEP_CLIENT_NOT_FOUND",
                        description:
                            "WHEP client not found. Make sure it was initialized properly."
                    )
                }
                client.unpause()
            }

            AsyncFunction("getSupportedReceiverVideoCodecsNames") {
                WhepClient.getSupportedReceiverVideoCodecsNames()
            }

            AsyncFunction("getSupportedReceiverAudioCodecsNames") {
                WhepClient.getSupportedReceiverAudioCodecsNames()
            }

            AsyncFunction("setPreferredReceiverVideoCodecs") {
                (preferredCodecs: [String]?) in
                self.whepClient?.setPreferredVideoCodecs(
                    preferredCodecs: preferredCodecs
                )
            }

            AsyncFunction("setPreferredReceiverAudioCodecs") {
                (preferredCodecs: [String]?) in
                self.whepClient?.setPreferredAudioCodecs(
                    preferredCodecs: preferredCodecs
                )
            }
        }
    }
}
