import Foundation

public struct ConfigurationOptions {
    public let authToken: String?
    public let stunServerUrl: String?
    public let videoParameters: VideoParameters?
    public let audioEnabled: Bool
    public let videoEnabled: Bool

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
