/// `BroadcastScreenShareReceiver` is responsible for receiving screen broadcast events such as
/// `started` or `stopped` and accorindly calls given callbacks passed during initialization.
internal class BroadcastScreenShareReceiver: BroadcastScreenShareReceiverDelegate {
    let onStart: () -> Void
    let onStop: () -> Void

    init(onStart: @escaping () -> Void, onStop: @escaping () -> Void) {
        self.onStart = onStart
        self.onStop = onStop
    }

    public func started() {
        onStart()
    }

    public func stopped() {
        onStop()
    }

    public func paused() {}

    public func resumed() {}
}
