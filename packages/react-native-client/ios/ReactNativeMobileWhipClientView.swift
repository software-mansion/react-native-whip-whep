import ExpoModulesCore
import Foundation
import MobileWhipWhepClient
import SwiftUI
import UIKit
import WebRTC

@objc(ReactNativeMobileWhipClientView)
public class ReactNativeMobileWhipClientView: ExpoView {
    deinit {
        whipClient?.delegate = nil
        whipClient?.onConnectionStateChanged = nil
        whipClient = nil
    }
    
    private var whipClient: WhipClient? {
        didSet {
            setupPlayer()
        }
    }
    private var hostingController: VideoViewController?

    required init(appContext: AppContext? = nil) {
        super.init(appContext: appContext)
    }

    private func setupPlayer() {
        removeOldPlayer()

        guard let player = self.whipClient else { return }
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
    }

    private func removeOldPlayer() {
        hostingController?.view.removeFromSuperview()
    }
    
    internal func createWhipClient(options: ReactNativeMobileWhipClientViewModule.ConfigurationOptions, onConnectionStateChanged: @escaping (RTCPeerConnectionState) -> Void) throws {
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

        whipClient = WhipClient(configOptions: options)
        whipClient?.onConnectionStateChanged = onConnectionStateChanged
    }
    
    internal func connect(options: ReactNativeMobileWhipClientViewModule.ConnectionOptions) async throws {
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
    
    internal func flipCamera() throws {
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
    
    internal func switchCamera(deviceId: String) throws {
        guard let client = self.whipClient else {
            throw Exception(
                name: "E_WHIP_CLIENT_NOT_FOUND",
                description: "WHIP client not found. Make sure it was initialized properly."
            )
        }
        client.switchCamera(deviceId: deviceId)
    }
    
    internal func disconnect() async throws {
        try await self.whipClient?.disconnect()
    }
    
    internal func setPreferredVideoCodecs(preferredCodecs: [String]?) {
        self.whipClient?.setPreferredVideoCodecs(preferredCodecs: preferredCodecs)
    }
    
    internal func setPreferredAudioCodecs(preferredCodecs: [String]?) {
        self.whipClient?.setPreferredAudioCodecs(preferredCodecs: preferredCodecs)
    }
    
    internal func getCurrentCameraDeviceId() -> String? {
        self.whipClient?.currentCameraDeviceId
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

}
