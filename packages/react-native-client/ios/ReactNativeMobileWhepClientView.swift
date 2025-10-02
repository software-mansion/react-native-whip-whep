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
  
    public var pipEnabled = false {
      didSet {
        setupPip()
      }
    }
    
    public var pipController: PictureInPictureController? {
      hostingController?.pipController
    }
        
    weak var player: ClientBase? {
      didSet {
        setupPlayer()
      }
    }
  
    public var autoStartPip = false {
      didSet {
        pipController?.startAutomatically = autoStartPip
      }
    }
    
    public var autoStopPip = true {
      didSet {
        pipController?.stopAutomatically = autoStopPip
      }
    }
    
    public var pipSize: CGSize = .zero {
      didSet {
        if !pipSize.equalTo(.zero) {
          pipController?.preferredSize = pipSize
        }
      }
    }
    
    private var hostingController: VideoViewController?

    required init(appContext: AppContext? = nil) {
        super.init(appContext: appContext)
    }

    private func setupPlayer() {
        removeOldPlayer()
        
        guard let player = self.player else { return }
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
      
        setupPip()
    }
  
    private func setupPip() {
      if pipEnabled {
        let controller = PictureInPictureController(sourceView: self)
        controller.startAutomatically = autoStartPip
        controller.stopAutomatically = autoStopPip
        if !pipSize.equalTo(.zero) {
          controller.preferredSize = pipSize
        }
        hostingController?.setup(pictureInPictureWith: controller)
      } else {
        hostingController?.disablePictureInPicture()
      }
    }
    
    private func removeOldPlayer() {
        hostingController?.view.removeFromSuperview()
    }
}
