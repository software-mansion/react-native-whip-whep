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
    public var playerType: String = "WHEP"

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    private func commonInit() {
        ReactNativeClientModule.onTrackUpdateListeners = []
        ReactNativeClientModule.onTrackUpdateListeners.append(self)
        videoView = VideoView(player: nil)
        
        if let videoView = videoView {
            addSubview(videoView)
        }

        checkAndSetPlayer()
        print("player:", self.videoView?.player)
    }
    
    private func checkAndSetPlayer() {
        switch(playerType){
        case "WHEP":
            if let whepClient = ReactNativeClientModule.whepClient {
                self.videoView?.player = whepClient
            }
        case "WHIP":
            if let whipClient = ReactNativeClientModule.whipClient {
                self.videoView?.player = whipClient
            }
        default:
            self.videoView?.player = nil
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
            print("here")
            self.checkAndSetPlayer()
            self.videoView?.player?.videoTrack = track
        }
    }

    func onTrackUpdate(track: RTCVideoTrack) {
        updateVideoTrack(track: track)
    }
}
