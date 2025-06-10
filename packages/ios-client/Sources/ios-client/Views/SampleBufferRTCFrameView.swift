import AVKit
import WebRTC

public class SampleBufferVideoCallView: UIView {
    private lazy var converter = I420Converter()
    private let sampleBufferLayer: AVSampleBufferDisplayLayer

    public var shouldRender: Bool = false

    public override init(frame: CGRect) {
        sampleBufferLayer = AVSampleBufferDisplayLayer()
        super.init(frame: frame)

        layer.addSublayer(sampleBufferLayer)
        sampleBufferLayer.videoGravity = .resizeAspect
        translatesAutoresizingMaskIntoConstraints = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        sampleBufferLayer.frame = bounds
    }

    func sampleBuffer(from frame: RTCVideoFrame) -> CMSampleBuffer? {
        let i420buffer = frame.buffer.toI420()
        guard let pixelBuffer = converter.convertToCVPixelBuffer(from: i420buffer) else { return nil }

        // Create a CMVideoFormatDescription
        var formatDescription: CMVideoFormatDescription?
        let formatResult = CMVideoFormatDescriptionCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer,
            formatDescriptionOut: &formatDescription
        )

        guard formatResult == noErr, let formatDesc = formatDescription else {
            return nil
        }

        // Create CMSampleTimingInfo
        // Timescale is 90khz according to RTCVideoFrame.h
        var timingInfo = CMSampleTimingInfo()
        timingInfo.presentationTimeStamp = CMTimeMake(value: Int64(frame.timeStamp), timescale: 90000)
        timingInfo.decodeTimeStamp = CMTimeMake(value: Int64(frame.timeStamp), timescale: 90000)
        timingInfo.duration = CMTime.invalid

        // Create CMSampleBuffer
        var sampleBuffer: CMSampleBuffer?
        let sampleBufferResult = CMSampleBufferCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer,
            dataReady: true,
            makeDataReadyCallback: nil,
            refcon: nil,
            formatDescription: formatDesc,
            sampleTiming: &timingInfo,
            sampleBufferOut: &sampleBuffer
        )

        guard sampleBufferResult == noErr, let buffer = sampleBuffer else {
            return nil
        }

        // Set sample attachments
        if let attachments = CMSampleBufferGetSampleAttachmentsArray(buffer, createIfNecessary: true),
            let attachmentArray = attachments as? [CFMutableDictionary],
            let dict = attachmentArray.first
        {
            CFDictionarySetValue(
                dict,
                Unmanaged.passUnretained(kCMSampleAttachmentKey_DisplayImmediately).toOpaque(),
                Unmanaged.passUnretained(kCFBooleanTrue).toOpaque())
        }

        return buffer
    }

    public func requestScaleRecalculation() {
        // Trigger scale recalculation if needed
        setNeedsLayout()
    }

    // Property to access the sample buffer layer for video gravity settings
    public var videoGravity: AVLayerVideoGravity {
        get { sampleBufferLayer.videoGravity }
        set { sampleBufferLayer.videoGravity = newValue }
    }
}

extension SampleBufferVideoCallView: RTCVideoRenderer {
    public func setSize(_ size: CGSize) {
        DispatchQueue.main.async { [weak self] in
            self?.sampleBufferLayer.frame = CGRect(origin: .zero, size: size)
        }
    }

    public func renderFrame(_ frame: RTCVideoFrame?) {
        guard shouldRender else { return }
        guard let frame = frame, let sampleBuffer = sampleBuffer(from: frame) else { return }

        sampleBufferLayer.enqueue(sampleBuffer)
    }
}
