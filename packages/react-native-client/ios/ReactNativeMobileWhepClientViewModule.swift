import ExpoModulesCore
import MobileWhipWhepClient

public class ReactNativeMobileWhepClientViewModule: Module,
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

        View(ReactNativeMobileWhepClientView.self) {
            Prop("pipEnabled") {
                (view: ReactNativeMobileWhepClientView, pipEnabled: Bool) in
                view.pipEnabled = pipEnabled
            }
            Prop("autoStartPip") {
                (view: ReactNativeMobileWhepClientView, startAutomatically: Bool) in
                view.autoStartPip = startAutomatically
            }
            Prop("autoStopPip") {
                (view: ReactNativeMobileWhepClientView, stopAutomatically: Bool) in
                view.autoStopPip = stopAutomatically
            }
            Prop("pipSize") { (view: ReactNativeMobileWhepClientView, size: CGSize) in
                view.pipSize = size
            }

            AsyncFunction("createWhepClient") { (
                    view: ReactNativeMobileWhepClientView,
                    configurationOptions: [String: AnyObject]?,
                    preferredVideoCodecs: [String]?,
                    preferredAudioCodecs: [String]?
                ) in
                do {
                    try view.createWhepClient(configurationOptions: configurationOptions, preferredVideoCodecs: preferredVideoCodecs, preferredAudioCodecs: preferredAudioCodecs)
                    view.setReconnectionListener(self)
                    view.setConnectionStateChangeCallback { [weak self] newState in
                        self?.emit(event: .whepPeerConnectionStateChanged(status: newState))
                    }
                } catch {
                    throw Exception(
                        name: "E_WHEP_CLIENT_NOT_CREATED",
                        description:
                            "Creating whep client failed."
                    )
                }
            }

            AsyncFunction("connect") { (view: ReactNativeMobileWhepClientView, connectOptions: ConnectOptions) in

                guard let url = URL(string: connectOptions.serverUrl) else {
                    throw Exception(
                        name: "E_INVALID_SERVER_URL",
                        description: "Invalid server URL. Make sure the address is correct."
                    )
                }

                try await view.connect(serverUrl: url, authToken: connectOptions.authToken)
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

            AsyncFunction("disconnect") { (view: ReactNativeMobileWhepClientView) in
                view.disconnect()
            }

            AsyncFunction("pause") { (view: ReactNativeMobileWhepClientView) in
                view.pause()
            }

            AsyncFunction("unpause") { (view: ReactNativeMobileWhepClientView) in
                view.unpause()
            }

            AsyncFunction("getSupportedReceiverVideoCodecsNames") {
                return WhepClient.getSupportedReceiverVideoCodecsNames()
            }

            AsyncFunction("getSupportedReceiverAudioCodecsNames") {
                return WhepClient.getSupportedReceiverAudioCodecsNames()
            }

            AsyncFunction("setPreferredReceiverVideoCodecs") {
                (view: ReactNativeMobileWhepClientView, preferredCodecs: [String]?) in
                view.setPreferredVideoCodecs(
                    preferredCodecs: preferredCodecs
                )
            }

            AsyncFunction("setPreferredReceiverAudioCodecs") {
                (view: ReactNativeMobileWhepClientView, preferredCodecs: [String]?) in
                view.setPreferredAudioCodecs(
                    preferredCodecs: preferredCodecs
                )
            }
        }
    }
}
