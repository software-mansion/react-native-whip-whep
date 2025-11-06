import CoreMedia
import ReplayKit
import WebRTC

/// A class working as a source of screen broadcast samples.
///
/// Should be used by implementations of `Broadcast Upload Extension` inside `SampleHandler.swift` files.
///
/// `BroadcastSampleSource` works as an `IPC` client whose role is to connect with already existing `IPC` server. The server
///  must be started by the application initiating the broadcast extension before the client.
///
/// Internally the `BroadcastSampleSource` serializes received sample buffers into `Proto Buffers` and send them using the `IPC` mechanism.
/// The application class able to receive and interpret all sample and notification messages is `ScreenBroadcastCapturer` that is further used by the `LocalScreenBroadcastTrack`.
///
/// In case when source failed to connect all frame processing and notification sending will be ignored.
///
/// To make the `IPC` communication work both `BroadcastSampleSource` and `ScreenBroadcastCapturer` must share the same `App Group`.
public class BroadcastSampleSource {
    let appGroup: String
    let ipcClient: IPCCLient

    var connected: Bool = false

    public init(appGroup: String) {
        self.appGroup = appGroup
        self.ipcClient = IPCCLient()
    }

    public func connect() -> Bool {
        connected = ipcClient.connect(with: appGroup)
        return connected
    }

    /// Sends `started` notification.
    ///
    /// Should be called inside `broadcastStarted` method of sample handler after successful source's `connect` invocation.
    public func started() {
        sendNotification(notification: .started)
    }

    /// Sends `paused` notification.
    ///
    /// Should be called inside `broadcastPaused` method of sample handler
    public func paused() {
        sendNotification(notification: .paused)
    }

    /// Sends `resumed` notification.
    ///
    /// Should be called inside `broadcastResumed` method of sample handler.
    public func resumed() {
        sendNotification(notification: .resumed)
    }

    /// Sends `finished` notification.
    ///
    /// Should be called inside `broadcastFinished` method of sample handler.
    public func finished() {
        sendNotification(notification: .finished)
    }

    /// Processes provided sample buffer by serializing it and passing via `IPC` mechanism.
    ///
    /// Currently supports  only`video` frames.
    public func processFrame(sampleBuffer: CMSampleBuffer, ofType type: RPSampleBufferType) {
        guard connected else {
            return
        }

        switch type {
        case .video:
            if let message = processVideoFrame(sampleBuffer: sampleBuffer),
                let proto = try? message.serializedData()
            {
                ipcClient.send(proto, messageId: 1)
            }
        default:
            break
        }
    }

    private func sendNotification(notification: BroadcastMessage.Notification) {
        guard connected else {
            return
        }

        let message = BroadcastMessage.with { $0.notification = notification }

        if let proto = try? message.serializedData() {
            ipcClient.send(proto, messageId: 1)
        }
    }

    private func processVideoFrame(sampleBuffer: CMSampleBuffer) -> BroadcastMessage? {
        guard let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return nil
        }

        var rotation: RTCVideoRotation?
        if #available(macOS 11.0, *) {
            // Check rotation tags. Extensions see these tags, but `RPScreenRecorder` does not appear to set them.
            // On iOS 12.0 and 13.0 rotation tags (other than up) are set by extensions.
            if let sampleOrientation = CMGetAttachment(
                sampleBuffer,
                key: RPVideoSampleOrientationKey as CFString,
                attachmentModeOut: nil
            ),
                let coreSampleOrientation = sampleOrientation.uint32Value
            {
                rotation = CGImagePropertyOrientation(rawValue: coreSampleOrientation)?.toRTCRotation()
            }
        }

        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        let timestampNs: Int64 = llround(CMTimeGetSeconds(timestamp) * Float64(NSEC_PER_SEC))

        let pixelFormat = CVPixelBufferGetPixelFormatType(buffer)

        return BroadcastMessage.with {
            $0.buffer = Data(pixelBuffer: buffer)
            $0.timestamp = timestampNs
            $0.video = .with {
                $0.format = pixelFormat
                $0.rotation = UInt32(rotation?.rawValue ?? 0)
                $0.width = UInt32(CVPixelBufferGetWidth(buffer))
                $0.height = UInt32(CVPixelBufferGetHeight(buffer))
            }
        }
    }

}

extension Data {
    init(pixelBuffer: CVPixelBuffer) {
        CVPixelBufferLockBaseAddress(pixelBuffer, [.readOnly])
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, [.readOnly]) }

        // Calculate sum of planes' size
        var totalSize = 0
        for plane in 0..<CVPixelBufferGetPlaneCount(pixelBuffer) {
            let height = CVPixelBufferGetHeightOfPlane(pixelBuffer, plane)
            let bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, plane)
            let planeSize = height * bytesPerRow
            totalSize += planeSize
        }

        guard let rawFrame = malloc(totalSize) else { fatalError() }
        var dest = rawFrame

        for plane in 0..<CVPixelBufferGetPlaneCount(pixelBuffer) {
            let source = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, plane)
            let height = CVPixelBufferGetHeightOfPlane(pixelBuffer, plane)
            let bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, plane)
            let planeSize = height * bytesPerRow

            memcpy(dest, source, planeSize)
            dest += planeSize
        }

        self.init(bytesNoCopy: rawFrame, count: totalSize, deallocator: .free)
    }
}

extension CGImagePropertyOrientation {
    func toRTCRotation() -> RTCVideoRotation {
        switch self {
        case .up, .upMirrored, .down, .downMirrored: return ._0
        case .left, .leftMirrored: return ._90
        case .right, .rightMirrored: return ._270
        default: return ._0
        }
    }
}
