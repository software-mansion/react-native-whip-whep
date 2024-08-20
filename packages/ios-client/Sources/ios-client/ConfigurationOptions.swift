import Foundation

public struct ConfigurationOptions {
    let authToken: String?
    let stunServerUrl: String?
    let audioOnly: Bool
    let videoOnly: Bool

    public init(authToken: String? = nil, stunServerUrl: String? = nil, audioOnly: Bool = false, videoOnly: Bool = false) {
        self.authToken = authToken
        self.stunServerUrl = stunServerUrl
        self.audioOnly = audioOnly
        self.videoOnly = videoOnly
    }
}
