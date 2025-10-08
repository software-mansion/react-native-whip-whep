import Foundation
import WebRTC

extension RTCPeerConnectionState {
  public var stringValue: String {
    switch self {
    case .new:
      return "new"
    case .connecting:
      return "connecting"
    case .connected:
      return "connected"
    case .disconnected:
      return "disconnected"
    case .failed:
      return "failed"
    case .closed:
      return "closed"
    @unknown default:
      return "unknown"
    }
  }
}

public enum ReconnectionStatus: String {
    case reconnectionStarted
    case reconnected
    case reconnectionRetriesLimitReached
}

protocol EmitableEvent {
    var name: String { get }
    var data: [String: Any?] { get }
    var eventContent: Any? { get }
}

class WhipEmitableEvent: EmitableEvent {
  enum EventName: String, CaseIterable {
    case Warning
    case WhipPeerConnectionStateChanged
    
    var name: String {
        rawValue
    }
  }
  
  let event: EventName
  var name: String { event.name }
  let eventContent: Any?

  var data: [String: Any?] {
      [event.name: eventContent]
  }
  
  private init(event: EventName, eventContent: Any? = nil) {
      self.event = event
      self.eventContent = eventContent
  }
  
  static var allEvents: [String] {
      EventName.allCases.map(\.name)
  }
  
  static func warning(message: String) -> WhipEmitableEvent { .init(event: .Warning, eventContent: message) }
  
  static func whipPeerConnectionStateChanged(status: RTCPeerConnectionState) -> WhipEmitableEvent {
      .init(event: .WhipPeerConnectionStateChanged, eventContent: status.stringValue)
  }
}


class WhepEmitableEvent {
  enum EventName: String, CaseIterable {
    case Warning
    case ReconnectionStatusChanged
    case WhepPeerConnectionStateChanged
    
    var name: String {
        rawValue
    }
  }
  
  let event: EventName
  var name: String { event.name }
  let eventContent: Any?

  var data: [String: Any?] {
      [event.name: eventContent]
  }
  
  private init(event: EventName, eventContent: Any? = nil) {
      self.event = event
      self.eventContent = eventContent
  }
  
  static var allEvents: [String] {
      EventName.allCases.map(\.name)
  }
  
  static func warning(message: String) -> WhepEmitableEvent { .init(event: .Warning, eventContent: message) }
  
  static func reconnectionStatusChanged(reconnectionStatus: ReconnectionStatus) -> WhepEmitableEvent {
      .init(event: .ReconnectionStatusChanged, eventContent: reconnectionStatus.rawValue)
  }
  
  static func whepPeerConnectionStateChanged(status: RTCPeerConnectionState) -> WhepEmitableEvent {
    .init(event: .WhepPeerConnectionStateChanged, eventContent: status.stringValue)
  }
}
