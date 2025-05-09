import SwiftUI
import UIKit
import Foundation
import ExpoModulesCore
import MobileWhipWhepClient

protocol OnTrackUpdateListener {
    func onTrackUpdate()
}

@objc(ReactNativeMobileWhepClientView)
public class ReactNativeMobileWhepClientView: ExpoView, OnTrackUpdateListener {
    func onTrackUpdate() {
        setupPlayer()
    }
    
    public var playerType: String? {
        didSet {
            setupPlayer()
        }
    }
  
    public var orientation = Orientation.portrait {
        didSet {
            hostingController?.orientation = self.orientation
        }
    }
      
    private var player: ClientBase?
    private var hostingController: VideoViewController?

    required init(appContext: AppContext? = nil) {
        super.init(appContext: appContext)
        ReactNativeMobileWhepClientModule.onTrackUpdateListeners = []
        ReactNativeMobileWhepClientModule.onTrackUpdateListeners.append(self)
    }

    private func setupPlayer() {
        removeOldPlayer()
        guard let playerType = self.playerType else { return }
        if (playerType == "WHIP") {
            self.player = ReactNativeMobileWhepClientModule.whipClient
        } else {
            self.player = ReactNativeMobileWhepClientModule.whepClient
        }
        
        guard let player = self.player else { return }
        let hostingController = VideoViewController(player: player)
        hostingController.view.backgroundColor = nil
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
    
    private func removeOldPlayer() {
        hostingController?.view.removeFromSuperview()
    }
  }
