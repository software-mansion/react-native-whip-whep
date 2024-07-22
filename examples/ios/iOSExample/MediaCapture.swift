import AVFoundation
import WebRTC

class MediaCapture: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    private let captureSession = AVCaptureSession()
    var videoSource: RTCVideoSource?
    var audioSource: RTCAudioSource?
    private let peerConnectionFactory: RTCPeerConnectionFactory

    init(peerConnectionFactory: RTCPeerConnectionFactory) {
        self.peerConnectionFactory = peerConnectionFactory
        super.init()
        self.setupCaptureSession()
    }

    private func setupCaptureSession() {
        // Ustaw wyjścia dla Video i Audio
        captureSession.beginConfiguration()
        let videoDevice = AVCaptureDevice.default(for: .video)
        let audioDevice = AVCaptureDevice.default(for: .audio)

        do {
            if let videoDevice = videoDevice,
               let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
               captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
                let videoOutput = AVCaptureVideoDataOutput()
                videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
                if captureSession.canAddOutput(videoOutput) {
                    captureSession.addOutput(videoOutput)
                    videoSource = peerConnectionFactory.videoSource()
                }
            }

            if let audioDevice = audioDevice,
               let audioInput = try? AVCaptureDeviceInput(device: audioDevice),
               captureSession.canAddInput(audioInput) {
                captureSession.addInput(audioInput)
                let audioOutput = AVCaptureAudioDataOutput()
                audioOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "audioQueue"))
                if captureSession.canAddOutput(audioOutput) {
                    captureSession.addOutput(audioOutput)
                    let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)

                    audioSource = peerConnectionFactory.audioSource(with: constraints)
                }
            }
        }

        captureSession.commitConfiguration()
    }

    func startCapture() {
        captureSession.startRunning()
    }

    func stopCapture() {
        captureSession.stopRunning()
    }
}
