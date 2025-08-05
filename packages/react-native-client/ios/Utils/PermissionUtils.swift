import AVFoundation

class PermissionUtils {
    static func requestCameraPermission() async -> Bool { await requestAccessIfNeeded(for: .video) }
    static func requestMicrophonePermission() async -> Bool { await requestAccessIfNeeded(for: .audio) }

    private static func requestAccessIfNeeded(for mediaType: AVMediaType) async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: mediaType)

        return if status == .notDetermined {
            await AVCaptureDevice.requestAccess(for: mediaType)
        } else {
            status == .authorized
        }
    }
}
