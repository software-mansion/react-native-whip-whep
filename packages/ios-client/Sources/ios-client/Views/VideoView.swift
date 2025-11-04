import Foundation
import SwiftUI
import UIKit
import WebRTC

public class VideoViewController: UIViewController {
    public weak var player: ClientBase?

    private let videoView: RTCMTLVideoView = {
        let videoView = RTCMTLVideoView(frame: .zero)
        videoView.videoContentMode = .scaleAspectFit
        return videoView
    }()

    public private(set) var pipController: PictureInPictureController?

    public init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(videoView)
        videoView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            videoView.topAnchor.constraint(equalTo: view.topAnchor),
            videoView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            videoView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            videoView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        player?.delegate = self

        if let track = player?.videoTrack {
            track.add(videoView)
            pipController?.videoTrack = track
        }
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    public func setup(pictureInPictureWith controller: PictureInPictureController) {
        self.pipController = controller
        if let track = player?.videoTrack {
            pipController?.videoTrack = track
        }
    }

    public func disablePictureInPicture() {
        self.pipController = nil
    }
}

extension VideoViewController: PlayerListener {
    public func onTrackAdded(track: RTCVideoTrack) {
        track.add(videoView)
        pipController?.videoTrack = track
    }

    public func onTrackRemoved(track: RTCVideoTrack) {
        track.remove(videoView)
        pipController?.videoTrack = nil
    }
}

extension RTCVideoRotation {
    var nsNumber: NSValue {
        return NSNumber(value: rawValue)
    }
}
