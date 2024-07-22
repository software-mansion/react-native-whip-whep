import SwiftUI
import UIKit
import AVFoundation
import WebRTC

struct CameraPreview: UIViewControllerRepresentable {
    var whipClient: WHIPClient

    func makeUIViewController(context: Context) -> CameraViewController {
        let controller = CameraViewController()
        controller.delegate = context.coordinator
        controller.whipClient = whipClient
        return controller
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self, whipClient: whipClient)
    }

    class Coordinator: NSObject {
        var parent: CameraPreview
        var whipClient: WHIPClient

        init(_ parent: CameraPreview, whipClient: WHIPClient) {
            self.parent = parent
            self.whipClient = whipClient
        }
    }
}

class CameraViewController: UIViewController {
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var whipClient: WHIPClient!
    
    var delegate: CameraPreview.Coordinator?
    func cameraIsReady() async {
        Task {
            let url = URL(string: "http://192.168.83.130:8829/whip/")!
            let token = "example"
            print("reached task")

            do {
                try await whipClient.publish(url: url, token: token, captureSession: captureSession)
            } catch {
                print("Wystąpił błąd podczas publikacji: \(error)")
            }
        }
        }

    override func viewDidLoad() {
        super.viewDidLoad()
        DispatchQueue.global(qos: .userInitiated).async {
            self.setupCamera()

        }
    }
    
    private func setupCamera() {
        DispatchQueue.global(qos: .userInitiated).async { // Rozpoczęcie konfiguracji w tle
            self.captureSession = AVCaptureSession()
            guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
            let videoInput: AVCaptureDeviceInput

            do {
                videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            } catch {
                return
            }

            if self.captureSession.canAddInput(videoInput) {
                self.captureSession.addInput(videoInput)
            } else {
                return
            }

            self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)

            DispatchQueue.main.async {
                self.previewLayer.frame = self.view.layer.bounds
                self.previewLayer.videoGravity = .resizeAspectFill
                self.view.layer.addSublayer(self.previewLayer)
                self.view.backgroundColor = .black
            }

            self.captureSession.startRunning()
            Task {
                await self.cameraIsReady()
            }
        }
    }
    
}
