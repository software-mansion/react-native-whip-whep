public protocol Connectable {
    func connect() async throws
    func disconnect()
}
