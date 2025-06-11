/*
* Adapted from Objective-C version: https://github.com/react-native-webrtc/react-native-webrtc/blob/a388aba77d6ef652d904ac4ef55026716bb151f1/ios/RCTWebRTC/PIPController.m
 */

import AVKit
import Accelerate
import Foundation
import UIKit
import WebRTC

public enum ResizeMode {
    case contain
    case cover
}

public class PictureInPictureController: NSObject {
    public weak var sourceView: UIView?
    public var videoTrack: RTCVideoTrack? {
        didSet {
            handleVideoTrackChange(from: oldValue, to: videoTrack)
        }
    }

    public var startAutomatically: Bool {
        get { pipController?.canStartPictureInPictureAutomaticallyFromInline ?? false }
        set { pipController?.canStartPictureInPictureAutomaticallyFromInline = newValue }
    }

    public var stopAutomatically: Bool = true

    public var preferredSize: CGSize {
        get { pipCallViewController?.preferredContentSize ?? .zero }
        set {
            guard !newValue.equalTo(pipCallViewController?.preferredContentSize ?? .zero) else {
                return
            }
            pipCallViewController?.preferredContentSize = newValue
            sampleView.requestScaleRecalculation()
        }
    }

    private var pipCallViewController: AVPictureInPictureVideoCallViewController?
    private var contentSource: AVPictureInPictureController.ContentSource?
    private var pipController: AVPictureInPictureController?
    private var sampleView: SampleBufferVideoCallView
    private var fallbackView: UIView
    private var keyValueObservation: NSKeyValueObservation?

    public init(sourceView: UIView) {
        self.sourceView = sourceView

        self.fallbackView = UIView(frame: .zero)

        self.sampleView = SampleBufferVideoCallView(frame: .zero)

        super.init()

        setupViews()
        setupPictureInPicture()
        setupNotifications()
    }

    deinit {
        cleanup()
    }

    private func setupViews() {
        fallbackView.translatesAutoresizingMaskIntoConstraints = false
        sampleView.translatesAutoresizingMaskIntoConstraints = false
    }

    private func setupPictureInPicture() {
        guard let sourceView = sourceView else { return }

        pipCallViewController = AVPictureInPictureVideoCallViewController()

        guard let pipCallViewController = pipCallViewController else { return }

        addSubviewToPipCallViewController(fallbackView)

        contentSource = AVPictureInPictureController.ContentSource(
            activeVideoCallSourceView: sourceView,
            contentViewController: pipCallViewController
        )

        guard let contentSource = contentSource else { return }

        pipController = AVPictureInPictureController(contentSource: contentSource)

        keyValueObservation = pipController?.observe(\.isPictureInPictureActive, options: [.initial, .new]) {
            [weak self] controller, change in
            self?.sampleView.shouldRender = change.newValue ?? false
        }
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    private func addSubviewToPipCallViewController(_ view: UIView) {
        guard let pipCallViewController = pipCallViewController else { return }

        pipCallViewController.view.addSubview(view)

        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: pipCallViewController.view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: pipCallViewController.view.trailingAnchor),
            view.topAnchor.constraint(equalTo: pipCallViewController.view.topAnchor),
            view.bottomAnchor.constraint(equalTo: pipCallViewController.view.bottomAnchor),
        ])
    }

    private func handleVideoTrackChange(from oldTrack: RTCVideoTrack?, to newTrack: RTCVideoTrack?) {
        if let oldTrack = oldTrack {
            oldTrack.remove(sampleView)
        }

        if let newTrack = newTrack {
            newTrack.add(sampleView)
        }

        if newTrack != nil {
            if sampleView.superview == nil {
                addSubviewToPipCallViewController(sampleView)
            }
            if fallbackView.superview != nil {
                fallbackView.removeFromSuperview()
            }
        } else {
            if fallbackView.superview == nil {
                addSubviewToPipCallViewController(fallbackView)
            }
            if sampleView.superview != nil {
                sampleView.removeFromSuperview()
            }
        }
    }

    private func cleanup() {
        keyValueObservation?.invalidate()
        keyValueObservation = nil

        videoTrack?.remove(sampleView)

        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    @objc private func applicationWillEnterForeground(_ notification: Notification) {
        if stopAutomatically {
            // Arbitraty 0.5s, if called to early won't have any effect.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.pipController?.stopPictureInPicture()
            }
        }
    }

    public func insertFallbackView(_ view: UIView) {
        fallbackView.addSubview(view)
    }

    public func setResizeMode(_ mode: ResizeMode) {
        switch mode {
        case .cover:
            sampleView.videoGravity = .resizeAspectFill
        case .contain:
            sampleView.videoGravity = .resizeAspect
        }
    }

    public func togglePictureInPicture() {
        guard let pipController = pipController else { return }

        if pipController.isPictureInPictureActive {
            pipController.stopPictureInPicture()
        } else if pipController.isPictureInPicturePossible {
            pipController.startPictureInPicture()
        }
    }

    public func startPictureInPicture() {
        guard let pipController = pipController,
            pipController.isPictureInPicturePossible
        else { return }

        pipController.startPictureInPicture()
    }

    public func stopPictureInPicture() {
        guard let pipController = pipController,
            pipController.isPictureInPictureActive
        else { return }

        pipController.stopPictureInPicture()
    }
}
