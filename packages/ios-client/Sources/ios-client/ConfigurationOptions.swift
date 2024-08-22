import Foundation

public struct ConfigurationOptions {
    let authToken: String?
    let stunServerUrl: String?
    let videoParameters: VideoParameters?

    public init(
        authToken: String? = nil, stunServerUrl: String? = nil, videoParameters: VideoParameters? = VideoParameters.presetHD43
    ) {
        self.authToken = authToken
        self.stunServerUrl = stunServerUrl
        self.videoParameters = videoParameters
    }
}
