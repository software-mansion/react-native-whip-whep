import SwiftUI
import UIKit
import Foundation
import ExpoModulesCore
import MobileWhipWhepClient

@objc(ReactNativeMobileWhipClientView)
public class ReactNativeMobileWhipClientView: ExpoView {
    public var playerType: String? {
        didSet {
//            setupPlayer()
        }
    }
  
  var player: ClientBase? {
    didSet {
      setupPlayer()
    }
  }
    private var hostingController: VideoViewController?

    required init(appContext: AppContext? = nil) {
        super.init(appContext: appContext)
    }

    private func setupPlayer() {
      print("## Setting up player 1")
        removeOldPlayer()
        
        guard let player = self.player else { return }
      print("## Setting up player 2")
        let hostingController = VideoViewController()
        hostingController.player = player
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
