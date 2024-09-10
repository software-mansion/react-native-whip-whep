import ExpoModulesCore
import UIKit
import WebRTC
import SwiftUI
import MobileWhepClient

class ReactNativeClientView: UIView {
    private var hostingController: UIHostingController<VideoView>?

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    public func setClient(_ client: ClientBase) {
        let videoView = VideoView(player: client)
        hostingController = UIHostingController(rootView: videoView)
        
        if let hostingController = hostingController {
            addSubview(hostingController.view)
        
            hostingController.view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                hostingController.view.topAnchor.constraint(equalTo: self.topAnchor),
                hostingController.view.bottomAnchor.constraint(equalTo: self.bottomAnchor),
                hostingController.view.leadingAnchor.constraint(equalTo: self.leadingAnchor),
                hostingController.view.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            ])
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        hostingController?.view.frame = self.bounds
    }
}
