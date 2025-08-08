import Foundation

public enum ReconnectionStatus: String {
    case idle
    case reconnecting
    case error
}

public struct ReconnectConfig {
    let maxAttempts: Int
    let initialDelayMs: Int
    let delayMs: Int

    public init(maxAttempts: Int = 5, initialDelayMs: Int = 1000, delayMs: Int = 1000) {
        self.maxAttempts = maxAttempts
        self.initialDelayMs = initialDelayMs
        self.delayMs = delayMs
    }
}

public protocol ReconnectionManagerListener: AnyObject {
    func onReconnectionStarted()
    func onReconnected()
    func onReconnectionRetriesLimitReached()
}

class ReconnectionManager {
    private let reconnectConfig: ReconnectConfig
    private var reconnectAttempts = 0
    private var reconnectionStatus: ReconnectionStatus = .idle
    private let connect: () -> Void
    private weak var listener: ReconnectionManagerListener?

    init(reconnectConfig: ReconnectConfig, connect: @escaping () -> Void, listener: ReconnectionManagerListener?) {
        self.reconnectConfig = reconnectConfig
        self.connect = connect
        self.listener = listener
    }

    func onDisconnected() {
        guard reconnectAttempts < reconnectConfig.maxAttempts else {
            reconnectionStatus = .error
            listener?.onReconnectionRetriesLimitReached()
            return
        }

        guard reconnectionStatus != .reconnecting else { return }
        reconnectionStatus = .reconnecting
        listener?.onReconnectionStarted()

        let delay = reconnectConfig.initialDelayMs + reconnectAttempts * reconnectConfig.delayMs
        reconnectAttempts += 1

        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(delay)) { [weak self] in
            self?.connect()
        }
    }

    func onReconnected() {
        guard reconnectionStatus == .reconnecting else { return }
        reset()
        listener?.onReconnected()
    }

    func reset() {
        reconnectAttempts = 0
        reconnectionStatus = .idle
    }
}
