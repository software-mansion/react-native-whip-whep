import ExpoModulesCore
import UIKit
import WebRTC
import SwiftUI
import MobileWhepClient

// MobileWhepClientView będzie dziedziczyć teraz bezpośrednio z UIView
class ReactNativeClientView: UIView {
//    private var hostingController: UIHostingController<VideoView>?
//
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//    }
//
//    required init?(coder: NSCoder) {
//        super.init(coder: coder)
//    }
//
//    public func setClient(_ client: ClientBase) {
//        // Tworzenie VideoView z playerem
//        let videoView = VideoView(player: client)
//        // Tworzenie HostingController dla SwiftUI view (VideoView)
//        hostingController = UIHostingController(rootView: videoView)
//        
//        if let hostingController = hostingController {
//            addSubview(hostingController.view)
//            
//            // Konfiguracja Auto Layout dla SwiftUI View
//            hostingController.view.translatesAutoresizingMaskIntoConstraints = false
//            NSLayoutConstraint.activate([
//                hostingController.view.topAnchor.constraint(equalTo: self.topAnchor),
//                hostingController.view.bottomAnchor.constraint(equalTo: self.bottomAnchor),
//                hostingController.view.leadingAnchor.constraint(equalTo: self.leadingAnchor),
//                hostingController.view.trailingAnchor.constraint(equalTo: self.trailingAnchor),
//            ])
//        }
//    }
//
//    override func layoutSubviews() {
//        super.layoutSubviews()
//        hostingController?.view.frame = self.bounds
//    }
}
