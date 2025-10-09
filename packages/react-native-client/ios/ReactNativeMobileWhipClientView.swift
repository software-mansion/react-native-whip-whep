import ExpoModulesCore
import Foundation
import MobileWhipWhepClient
import SwiftUI
import UIKit

@objc(ReactNativeMobileWhipClientView)
public class ReactNativeMobileWhipClientView: ExpoView {
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
            hostingController.view.trailingAnchor.constraint(equalTo: self.trailingAnchor),
        ])

        self.hostingController = hostingController
    }

    private func removeOldPlayer() {
        hostingController?.view.removeFromSuperview()
    }
}
