import Foundation
import WebRTC

internal func downscaleResolution(from: Dimensions, to: Dimensions) -> Dimensions {
    if from.height > to.height {
        let ratio = Float(from.height) / Float(from.width)

        let newHeight = to.height
        let newWidth = Int32((Float(newHeight) / ratio).rounded(.down))

        return Dimensions(width: newWidth, height: newHeight)
    } else if from.width > to.width {
        let ratio = Float(from.height) / Float(from.width)

        let newWidth = to.width
        let newHeight = Int32((Float(newWidth) * ratio).rounded(.down))

        return Dimensions(width: newWidth, height: newHeight)
    }

    return from
}

/// Utility for creating a `CVPixelBuffer` from raw bytes.
extension CVPixelBuffer {
    public static func from(_ data: Data, width: Int, height: Int, pixelFormat: OSType)
        -> CVPixelBuffer
    {
        data.withUnsafeBytes { buffer in
            var pixelBuffer: CVPixelBuffer!

            let result = CVPixelBufferCreate(
                kCFAllocatorDefault,
                width,
                height,
                pixelFormat,
                nil,
                &pixelBuffer
            )
            guard result == kCVReturnSuccess else { fatalError() }

            CVPixelBufferLockBaseAddress(pixelBuffer, [])
            defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }

            var source = buffer.baseAddress!

            for plane in 0..<CVPixelBufferGetPlaneCount(pixelBuffer) {
                let dest = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, plane)
                let height = CVPixelBufferGetHeightOfPlane(pixelBuffer, plane)
                let bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, plane)
                let planeSize = height * bytesPerRow

                memcpy(dest, source, planeSize)
                source += planeSize
            }

            return pixelBuffer
        }
    }
}

internal protocol BroadcastScreenShareReceiverDelegate: AnyObject {
    func started()
    func stopped()
    func paused()
    func resumed()
}

/// `VideoCapturer` that is responsible for capturing media from a remote `Broadcast Extension` that sends samples
/// via `IPC` mechanism.
///
/// The capturer works in a `Server` mode, receiving appropriate notifications/samples from the extension that is working in a `Client` mode.
/// The expected behaviour is to start the capturer prior to starting the extension as the server is responsible for opening the `IPC` port first.
/// If the client starts before the server it will automatically close as the port will be closed.
///
/// The communication is performed by using `Proto Buffers` to gracefully handle serialization and deserialization of raw bytes sent via IPC port.
/// For types of messages please refer to `broadcast_ipc.proto` included with the package.
///
/// It is important that the capturer gets started with a proper `appGroup` that is shared between the application and the `Broadcast Extension` itself
/// (required by `IPC` mechanism).
class BroadcastScreenShareCapturer: RTCVideoCapturer {
    public weak var capturerDelegate: BroadcastScreenShareReceiverDelegate?

    private let videoParameters: VideoParameters
    private let appGroup: String
    private let ipcServer: IPCServer
    let source: RTCVideoSource
    private var started = false
    private var isReceivingSamples: Bool = false

    private var timeoutTimer: Timer?

    internal let supportedPixelFormats = RTCCVPixelBuffer.supportedPixelFormats()

    /**
     Creates a  broadcast screen capturer.
    
     - Parameters:
        - source: `RTCVideoSource` that will receive incoming video buffers
        - appGroup: App Group that will be used for starting an `IPCServer` on
        - videoParameters: The parameters used for limiting the screen capture resolution and target framerate
        - delegate: A delegate that will receive notifications about the sceeen capture events such as started/stopped or paused
     */
    init(
        _ source: RTCVideoSource,
        appGroup: String,
        videoParameters: VideoParameters,
        delegate: BroadcastScreenShareReceiverDelegate? = nil
    ) {
        self.source = source
        self.appGroup = appGroup
        self.videoParameters = videoParameters

        capturerDelegate = delegate
        ipcServer = IPCServer()

        super.init(delegate: source)

        // check every 5 seconds if the screensharing is still active or crashed
        // this is needed as we can't know if the IPC Client stopped working or not, so at least
        // we can check that that we receiving some samples
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] timer in
            guard let self else {
                timer.invalidate()
                return
            }

            // NOTE: there is basically no way of telling if the user has still
            // an opened RPSystemBroadcastPickerView, but we can assume that if the application
            // is in inactive state then this is a case therefore ignore the timeoutTimer tick
            if UIApplication.shared.applicationState == .inactive {
                return
            }

            if !self.isReceivingSamples {
                self.capturerDelegate?.stopped()
                timer.invalidate()
                return
            }

            self.isReceivingSamples = false
        }

        ipcServer.onReceive = { [weak self] _, _, data in
            guard
                let self,
                let sample = try? BroadcastMessage(serializedData: data)
            else {
                return
            }

            switch sample.type {
            case .notification(let notification):
                switch notification {
                case .started:
                    sdkLogger.info("ScreenBroadcastCapturer has been started")
                    self.capturerDelegate?.started()
                    self.started = true
                case .finished:
                    sdkLogger.info("ScreenBroadcastCapturer has been stopped")
                    self.capturerDelegate?.stopped()
                case .paused:
                    sdkLogger.info("ScreenBroadcastCapturer has been paused")
                    self.capturerDelegate?.paused()
                case .resumed:
                    sdkLogger.info("ScreenBroadcastCapturer has been resumed")
                    self.capturerDelegate?.resumed()
                default:
                    break
                }

            case .video(let video):
                if !self.started {
                    self.stopListening()
                    sdkLogger.info("Started receiving video samples without `started` notification...")
                    return
                }

                self.isReceivingSamples = true

                let dimensions = downscaleResolution(
                    from: Dimensions(width: Int32(video.width), height: Int32(video.height)),
                    to: videoParameters.dimensions
                )

                self.source.adaptOutputFormat(
                    toWidth: dimensions.width,
                    height: dimensions.height,
                    fps: Int32(videoParameters.maxFps)
                )

                let pixelBuffer = CVPixelBuffer.from(
                    sample.buffer,
                    width: Int(video.width),
                    height: Int(video.height),
                    pixelFormat: video.format
                )
                let height = Int32(CVPixelBufferGetHeight(pixelBuffer))
                let width = Int32(CVPixelBufferGetWidth(pixelBuffer))

                let rtcBuffer = RTCCVPixelBuffer(
                    pixelBuffer: pixelBuffer,
                    adaptedWidth: width,
                    adaptedHeight: height,
                    cropWidth: width,
                    cropHeight: height,
                    cropX: 0,
                    cropY: 0
                )

                var rotation: RTCVideoRotation = ._0

                switch video.rotation {
                case 90:
                    rotation = ._90
                case 180:
                    rotation = ._180
                case 270:
                    rotation = ._270
                default:
                    break
                }

                // NOTEe: somehow local Metal renderer for RTCVPixelBuffer does not render the video
                // the I420 somehow does so keep it in that format as long as it works
                let buffer = rtcBuffer.toI420()
                let videoFrame = RTCVideoFrame(
                    buffer: buffer,
                    rotation: rotation,
                    timeStampNs: sample.timestamp
                )

                let delegate = source as RTCVideoCapturerDelegate

                delegate.capturer(self, didCapture: videoFrame)

            default:
                break
            }
        }
    }

    public func startListening() {
        guard ipcServer.listen(for: appGroup) else {
            fatalError(
                "Failed to open IPC for screen broadcast, make sure that both app and extension are using same App Group"
            )
        }
    }

    public func stopListening() {
        ipcServer.close()
        ipcServer.dispose()
    }
}
