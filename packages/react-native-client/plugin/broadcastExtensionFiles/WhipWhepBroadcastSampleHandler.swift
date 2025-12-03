import Foundation
import MobileWhipWhepBroadcastClient
import ReplayKit
import WebRTC
import os.log

/// App Group used by the extension to exchange buffers with the target application
let appGroup = "{{GROUP_IDENTIFIER}}"

let logger = OSLog(subsystem: "{{BUNDLE_IDENTIFIER}}.WhipWhepBroadcastSampleHandler", category: "Broadcaster")

/// An example `SampleHandler` utilizing `BroadcastSampleSource` sending broadcast samples
/// and necessary notifications enabling device's screen share.
///
/// This class is the entry point for the Broadcast Upload Extension.
/// iOS calls these methods when the user starts/stops/pauses screen recording.
///
/// How it works:
/// 1. User initiates screen sharing from your app
/// 2. iOS launches this extension in a separate process
/// 3. broadcastStarted() establishes IPC connection with main app via App Group
/// 4. processSampleBuffer() receives screen frames and forwards them via IPC
/// 5. Main app's BroadcastScreenShareCapturer receives and processes frames
class WhipWhepBroadcastSampleHandler: RPBroadcastSampleHandler {
    let broadcastSource = BroadcastSampleSource(appGroup: appGroup)
    var started: Bool = false

    /// Called when the user starts screen broadcasting.
    /// Establishes IPC connection with the main app.
    override func broadcastStarted(withSetupInfo _: [String: NSObject]?) {
        started = broadcastSource.connect()

        guard started else {
            os_log("failed to connect with ipc server", log: logger, type: .debug)
            super.finishBroadcastWithError(NSError(domain: "", code: 0, userInfo: nil))
            return
        }

        broadcastSource.started()
    }

    override func broadcastPaused() {
        broadcastSource.paused()
    }

    override func broadcastResumed() {
        broadcastSource.resumed()
    }

    override func broadcastFinished() {
        broadcastSource.finished()
    }

    /// Called by iOS for each screen frame captured.
    /// Forwards the frame to the main app via IPC.
    ///
    /// @param sampleBuffer The captured video/audio buffer
    /// @param sampleBufferType Type of buffer (video or audio)
    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
        guard started else {
            return
        }

        broadcastSource.processFrame(sampleBuffer: sampleBuffer, ofType: sampleBufferType)
    }
}
