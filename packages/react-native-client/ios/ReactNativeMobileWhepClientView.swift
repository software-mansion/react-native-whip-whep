import SwiftUI
import UIKit
import Foundation
import ExpoModulesCore
import MobileWhipWhepClient

protocol OnTrackUpdateListener {
    func onTrackUpdate()
}

@objc(ReactNativeMobileWhepClientView)
public class ReactNativeMobileWhepClientView: UIView, OnTrackUpdateListener {
    func onTrackUpdate() {
        setupPlayer()
    }
    
    public var playerType: String? {
        didSet {
            setupPlayer()
        }
    }
    
    private var player: ClientBase?
    private var hostingController: UIHostingController<VideoView>?

    override public init(frame: CGRect) {
        super.init(frame: frame)
        ReactNativeMobileWhepClientModule.onTrackUpdateListeners = []
        ReactNativeMobileWhepClientModule.onTrackUpdateListeners.append(self)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    private func setupPlayer() {
        guard let playerType = self.playerType else { return }
        if(playerType == "WHIP"){
            self.player = ReactNativeMobileWhepClientModule.whipClient
        }else{
            self.player = ReactNativeMobileWhepClientModule.whepClient
        }
        
        guard let player = self.player else { return }
        let videoView = VideoView(player: player)
        let hostingController = UIHostingController(rootView: videoView)
        self.addSubview(hostingController.view)
        
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: self.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ])
        
        self.hostingController = hostingController
    }
}
