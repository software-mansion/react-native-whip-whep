import Foundation

public struct ConfigurationOptions {
    let authToken: String?
    let stunServerUrl: String?

    public init(authToken: String? = nil, stunServerUrl: String? = nil) {
        self.authToken = authToken
        self.stunServerUrl = stunServerUrl
    }
}
