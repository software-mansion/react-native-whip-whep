import SwiftUI
import UIKit
import Foundation
import ExpoModulesCore
import MobileWhipWhepClient

public enum Orientation: String {
    case portrait
    case landscape
}

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
            updateOrientation()
        }
    }
      
    private var player: ClientBase?
    private var hostingController: UIHostingController<VideoView>?

    required init(appContext: AppContext? = nil) {
        super.init(appContext: appContext)
        ReactNativeMobileWhepClientModule.onTrackUpdateListeners = []
        ReactNativeMobileWhepClientModule.onTrackUpdateListeners.append(self)
    }

    private func setupPlayer() {
        removeOldPlayer()
        guard let playerType = self.playerType else { return }
        if (playerType == "WHIP"){
            self.player = ReactNativeMobileWhepClientModule.whipClient
        } else{
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
        updateOrientation()
    }
    
    private func removeOldPlayer() {
        hostingController?.view.removeFromSuperview()
    }
  
    private func updateOrientation() {
      guard let hostingController = hostingController else { return }
      
      if self.orientation == .landscape {
        hostingController.view.transform = CGAffineTransform(rotationAngle: .pi / 2)
        hostingController.view.frame = self.bounds
      } else {
        hostingController.view.transform = .identity
        hostingController.view.frame = self.bounds
      }
    }
  }
