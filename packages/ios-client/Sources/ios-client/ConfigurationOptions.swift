import Foundation

public struct ClientConnectOptions {
    public let serverUrl: URL
    public let authToken: String?

    public init(serverUrl: URL, authToken: String?) {
        self.serverUrl = serverUrl
        self.authToken = authToken
    }
}
