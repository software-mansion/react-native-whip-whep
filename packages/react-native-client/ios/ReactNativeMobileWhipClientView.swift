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

        guard let player = player else { return }
        let hostingController = VideoViewController()
        hostingController.player = player
        hostingController.view.backgroundColor = nil
        addSubview(hostingController.view)

        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])

        self.hostingController = hostingController
    }

    private func removeOldPlayer() {
        hostingController?.view.removeFromSuperview()
    }
}
