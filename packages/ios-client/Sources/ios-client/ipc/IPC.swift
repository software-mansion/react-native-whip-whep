import Foundation
import simd

// enables to attach the IPC instance to the existing CFMessagePort instance
extension CFMessagePort {
    private static var selfObjectHandle: UInt8 = 1

    func associatedSelf() -> IPC? {
        objc_getAssociatedObject(self as Any, &CFMessagePort.selfObjectHandle) as? IPC
    }

    func associateSelf(_ obj: IPC) {
        objc_setAssociatedObject(
            self as Any,
            &CFMessagePort.selfObjectHandle,
            obj,
            objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
    }
}

public class IPC {
    internal var port: CFMessagePort?
    public internal(set) var connected: Bool = false

    internal init() {}

    public func close() {
        guard let port = port else { return }

        CFMessagePortInvalidate(port)
    }

    internal func dispose() {
        port = nil
        connected = false
    }
}

public typealias IPCOnReceiveData = (_ server: IPCServer, _ messageId: Int32, _ data: Data) -> Void

/// `IPCServer`  class responsible for opening an `CFMessagePort` and listening on new messages.
public class IPCServer: IPC {
    private static let loopMode = CFRunLoopMode.commonModes

    private let loop: CFRunLoop
    private var loopSource: CFRunLoopSource?

    public var onReceive: IPCOnReceiveData?

    public init(onReceive: IPCOnReceiveData? = nil, loop: CFRunLoop = CFRunLoopGetMain()) {
        self.onReceive = onReceive
        self.loop = loop
    }

    override func dispose() {
        super.dispose()

        guard let source = loopSource else { return }

        CFRunLoopRemoveSource(loop, source, Self.loopMode)
        loopSource = nil
    }

    @discardableResult
    public func listen(for name: String) -> Bool {
        guard port == nil else {
            return false
        }

        port = CFMessagePortCreateLocal(
            nil,
            name as CFString,
            {
                (port: CFMessagePort?, id: Int32, data: CFData?, _: UnsafeMutableRawPointer?) -> Unmanaged<CFData>? in
                guard let selfObj = port?.associatedSelf() as? IPCServer,
                    let data = data as Data?
                else {
                    return nil
                }

                selfObj.onReceive?(selfObj, id, data)
                return nil
            },
            nil,
            nil
        )

        if let port = port {
            port.associateSelf(self)

            CFMessagePortSetInvalidationCallBack(port) { port, _ in
                guard let selfObj = port?.associatedSelf() else { return }
                selfObj.dispose()
            }

            if let source = CFMessagePortCreateRunLoopSource(nil, port, 0) {
                CFRunLoopAddSource(loop, source, Self.loopMode)

                loopSource = source
            } else {
                close()
                return false
            }

            connected = true
            return true
        }

        return false
    }
}

/// `IPCClient`  class responsible for writing to a `CFMessagePort` that has been opened by certain `IPCServer`.
public class IPCCLient: IPC {
    private static var selfObjectHandle: UInt8 = 1

    override public init() {}

    @discardableResult
    public func connect(with name: String) -> Bool {
        port = CFMessagePortCreateRemote(nil, name as CFString)

        if let port = port {
            port.associateSelf(self)

            CFMessagePortSetInvalidationCallBack(port) { port, _ in
                guard let selfObj = port?.associatedSelf() else { return }

                selfObj.dispose()
            }

            connected = true
            return true
        }

        return false
    }

    @discardableResult
    public func send(_ data: Data, messageId: Int32 = 0) -> Bool {
        guard let port = port else { return false }

        let result = CFMessagePortSendRequest(port, messageId, data as CFData, 0.0, 0.0, nil, nil)

        return result == Int32(kCFMessagePortSuccess)
    }
}
