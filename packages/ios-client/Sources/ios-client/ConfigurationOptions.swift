import Foundation

public struct ConfigurationOptions {
    let authToken: String?
    let stunServerUrl: String?
    let videoSize: VideoParameters?

    public init(
        authToken: String? = nil, stunServerUrl: String? = nil, videoSize: VideoParameters? = VideoParameters.presetHD43
    ) {
        self.authToken = authToken
        self.stunServerUrl = stunServerUrl
        self.videoSize = videoSize
    }
}
