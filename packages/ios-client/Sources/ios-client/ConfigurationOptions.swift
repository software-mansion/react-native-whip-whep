import Foundation

public struct ConfigurationOptions {
    let authToken: String?
    let stunServerUrl: String?
    let videoParameters: VideoParameters?
    let audioEnabled: Bool
    let videoEnabled: Bool

    public init(
        authToken: String? = nil, stunServerUrl: String? = nil, audioEnabled: Bool = true, videoEnabled: Bool = true,
        videoParameters: VideoParameters? = VideoParameters.presetHD43
    ) {
        self.authToken = authToken
        self.stunServerUrl = stunServerUrl
        self.audioEnabled = audioEnabled
        self.videoEnabled = videoEnabled
        self.videoParameters = videoParameters
    }
}
