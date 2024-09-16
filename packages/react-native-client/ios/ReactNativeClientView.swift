import SwiftUI
import UIKit
import Foundation
import ExpoModulesCore
import MobileWhepClient
import WebRTC

protocol OnTrackUpdateListener {
    func onTrackUpdate(track: RTCVideoTrack)
}

@objc(ReactNativeClientView)
public class ReactNativeClientView: UIView, OnTrackUpdateListener {
    func onTrackUpdate(track: RTCVideoTrack) {
        setupPlayer()
    }
    
    public var playerType: String? {
        didSet {
            print("setup player")
            setupPlayer()
        }
    }
    
    private var player: ClientBase?
    private var hostingController: UIHostingController<VideoView>?

    override public init(frame: CGRect) {
        super.init(frame: frame)
        ReactNativeClientModule.onTrackUpdateListeners = []
        ReactNativeClientModule.onTrackUpdateListeners.append(self)
        setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    
    private func setupView() {
        // Any additional setup can be added here if needed
    }

    private func setupPlayer() {
        guard let playerType = self.playerType else { return }
        print(self.playerType)
        if(playerType == "WHIP"){
            self.player = ReactNativeClientModule.whipClient
        }else{
            self.player = ReactNativeClientModule.whepClient
        }
        
        guard let player = self.player else { return }

        // Create a SwiftUI view wrapped in a UIHostingController
        let videoView = VideoView(player: player)
        let hostingController = UIHostingController(rootView: videoView)
        
        // Add the hosting controller's view to the current view
        self.addSubview(hostingController.view)
        
        // Ensure it resizes properly
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: self.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ])
        
        // Store the hosting controller to a property to keep a reference to it
        self.hostingController = hostingController
        print("new view", videoView.player.videoTrack)
    }
}
