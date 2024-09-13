import ExpoModulesCore
import UIKit
import WebRTC
import SwiftUI
import MobileWhepClient

protocol OnTrackUpdateListener {
    func onTrackUpdate(track: RTCVideoTrack)
}

class ReactNativeClientView: UIView, OnTrackUpdateListener {
    private var videoView: VideoView?

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    private func commonInit() {
        ReactNativeClientModule.onTrackUpdateListeners.append(self)
        videoView = VideoView(player: nil)
        
        if let videoView = videoView {
            addSubview(videoView)
        }

        checkAndSetPlayer()
    }
    
    private func checkAndSetPlayer() {
        if let whepClient = ReactNativeClientModule.whepClient {
            videoView?.player = whepClient
        }
    }
    
    deinit {
        ReactNativeClientModule.onTrackUpdateListeners.removeAll(where: {
            if let view = $0 as? ReactNativeClientView {
                return view === self
            }
            return false
        })
    }

    func updateVideoTrack(track: RTCVideoTrack) {
        DispatchQueue.main.async {
            if self.superview != nil {
                self.videoView?.player?.videoTrack = track
            }
        }
    }

    func onTrackUpdate(track: RTCVideoTrack) {
        updateVideoTrack(track: track)
    }
}
