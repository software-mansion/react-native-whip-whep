package com.swmansion.reactnativeclient

import org.webrtc.PeerConnection

enum class ReconnectionStatus(
  val status: String
) {
  ReconnectionStarted("reconnectionStarted"),
  Reconnected("reconnected"),
  ReconnectionRetriesLimitReached("reconnectionRetriesLimitReached"),
}

fun PeerConnection.PeerConnectionState.stringValue(): String {
  return when (this) {
    PeerConnection.PeerConnectionState.NEW -> "new"
    PeerConnection.PeerConnectionState.CONNECTING -> "connecting"
    PeerConnection.PeerConnectionState.CONNECTED -> "connected"
    PeerConnection.PeerConnectionState.DISCONNECTED -> "disconnected"
    PeerConnection.PeerConnectionState.FAILED -> "failed"
    PeerConnection.PeerConnectionState.CLOSED -> "closed"
    else -> "unknown"
  }
}

class EmitableEvent private constructor(
  private val event: EventName,
  private val eventContent: Any? = null
) {
  enum class EventName {
    Warning,
    ReconnectionStatusChanged,
    WhepPeerConnectionStateChanged,
    WhipPeerConnectionStateChanged,
  }

  val name: String
    get() = event.name

  val data: Map<String, Any?>
    get() = mapOf(event.name to eventContent)

  companion object {
    fun warning(message: String) = EmitableEvent(EventName.Warning, message)

    fun reconnectionStatusChanged(status: ReconnectionStatus) = EmitableEvent(EventName.ReconnectionStatusChanged, status.status)

    fun whepPeerConnectionStateChanged(status: PeerConnection.PeerConnectionState) = EmitableEvent(EventName.WhepPeerConnectionStateChanged, status.stringValue())

    fun whipPeerConnectionStateChanged(status: PeerConnection.PeerConnectionState) = EmitableEvent(EventName.WhipPeerConnectionStateChanged, status.stringValue())

    val allEvents: Array<String>
      get() = EventName.entries.map { it.name }.toTypedArray()
  }
}
