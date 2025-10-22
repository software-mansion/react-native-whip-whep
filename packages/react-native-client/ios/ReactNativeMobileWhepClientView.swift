import ExpoModulesCore
import Foundation
import MobileWhipWhepClient
import SwiftUI
import UIKit
import WebRTC

@objc(ReactNativeMobileWhepClientView)
public class ReactNativeMobileWhepClientView: ExpoView, PlayerListener {
    public var pipEnabled = false {
        didSet {
            setupPip()
        }
    }

    public var pipController: PictureInPictureController? {
        hostingController?.pipController
    }

    public var autoStartPip = false {
        didSet {
            pipController?.startAutomatically = autoStartPip
        }
    }

    public var autoStopPip = true {
        didSet {
            pipController?.stopAutomatically = autoStopPip
        }
    }

    public var pipSize: CGSize = .zero {
        didSet {
            if !pipSize.equalTo(.zero) {
                pipController?.preferredSize = pipSize
            }
        }
    }
    
    private var whepClient: WhepClient? = nil {
        didSet {
            setupPlayer()
            if whepClient == nil {
                hostingController?.player = nil
            }
        }
    }

    private var hostingController: VideoViewController?

    required init(appContext: AppContext? = nil) {
        super.init(appContext: appContext)
    }
    
    deinit {
        print("Deinit in whep view. Clening up")
        whepClient?.cleanup()
        whepClient = nil
    }
    
    public func createWhepClient(
        configurationOptions: [String: AnyObject]?,
        preferredVideoCodecs: [String]?,
        preferredAudioCodecs: [String]?
    ) throws {
        let options = WhepConfigurationOptions(
            audioEnabled: configurationOptions?["audioEnabled"] as? Bool ?? true,
            videoEnabled: configurationOptions?["videoEnabled"] as? Bool ?? true,
            stunServerUrl: configurationOptions?["stunServerUrl"] as? String
        )

        self.whepClient = try WhepClient(configOptions: options)
        self.whepClient?.delegate = self
    }
    
    public func setReconnectionListener(_ listener: ReconnectionManagerListener?) {
        self.whepClient?.reconnectionListener = listener
    }
    
    public func setConnectionStateChangeCallback(onConnectionStateChanged: @escaping (RTCPeerConnectionState) -> Void) {
        self.whepClient?.onConnectionStateChanged = onConnectionStateChanged
    }
    
    public func connect(serverUrl: URL, authToken: String?) async throws {
        guard let client = self.whepClient else {
            throw Exception(
                name: "E_WHEP_CLIENT_NOT_FOUND",
                description:
                    "WHEP client not found. Make sure it was initialized properly."
            )
        }

        try await client.connect(.init(serverUrl: serverUrl, authToken: authToken))
    }
    
    public func disconnect() {
        whepClient?.disconnect()
    }

    public func pause() {
        whepClient?.pause()
    }

    public func unpause() {
        whepClient?.unpause()
    }
    
    public func setPreferredVideoCodecs(preferredCodecs: [String]?) {
        self.whepClient?.setPreferredVideoCodecs(
            preferredCodecs: preferredCodecs
        )
    }    
    public func setPreferredAudioCodecs(preferredCodecs: [String]?) {
        self.whepClient?.setPreferredAudioCodecs(
            preferredCodecs: preferredCodecs
        )
    }
    
    public func onTrackAdded(track: RTCVideoTrack) {
        setupPlayer()
    }

    public func onTrackRemoved(track: RTCVideoTrack) { }

    private func setupPlayer() {
        removeOldPlayer()

        guard let player = self.whepClient else { return }
        let hostingController = VideoViewController()
        hostingController.player = player
        hostingController.view.backgroundColor = nil
        self.addSubview(hostingController.view)

        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: self.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: self.trailingAnchor),
        ])

        self.hostingController = hostingController

        setupPip()
    }

    private func setupPip() {
        if pipEnabled {
            let controller = PictureInPictureController(sourceView: self)
            controller.startAutomatically = autoStartPip
            controller.stopAutomatically = autoStopPip
            if !pipSize.equalTo(.zero) {
                controller.preferredSize = pipSize
            }
            hostingController?.setup(pictureInPictureWith: controller)
        } else {
            hostingController?.disablePictureInPicture()
        }
    }

    private func removeOldPlayer() {
        hostingController?.view.removeFromSuperview()
    }
}
