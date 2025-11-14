import ReplayKit
import os.log

let log = OSLog(subsystem: "com.mobilewhpwhep.client", category: "ErrorHandling")

#if os(iOS)
    @available(iOS 12, *)
    extension RPSystemBroadcastPickerView {
        public static func show(
            for preferredExtension: String? = nil, showsMicrophoneButton: Bool = false
        ) {
            let view = RPSystemBroadcastPickerView()
            view.preferredExtension = preferredExtension
            view.showsMicrophoneButton = showsMicrophoneButton

            let selector = NSSelectorFromString("buttonPressed:")
            if view.responds(to: selector) {
                view.perform(selector, with: nil)
            }
        }
    }
#endif
