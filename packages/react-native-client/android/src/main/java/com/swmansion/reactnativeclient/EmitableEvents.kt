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

class EmitableEvent(val name: String, private val eventContent: Any? = null) {
  val data: Map<String, Any?>
    get() = mapOf(name to eventContent)

}

class WhepEmitableEvent private constructor(
  private val event: EventName,
  private val eventContent: Any? = null
) {
  enum class EventName {
    Warning,
    ReconnectionStatusChanged,
    WhepPeerConnectionStateChanged,
  }

  val name: String
    get() = event.name

  val data: Map<String, Any?>
    get() = mapOf(event.name to eventContent)

  companion object {
    fun warning(message: String) = WhepEmitableEvent(EventName.Warning, message).toEmitableEvent()

    fun reconnectionStatusChanged(status: ReconnectionStatus) = WhepEmitableEvent(EventName.ReconnectionStatusChanged, status.status).toEmitableEvent()

    fun whepPeerConnectionStateChanged(status: PeerConnection.PeerConnectionState) = WhepEmitableEvent(EventName.WhepPeerConnectionStateChanged, status.stringValue()).toEmitableEvent()

    val allEvents: Array<String>
      get() = EventName.entries.map { it.name }.toTypedArray()
  }

  private fun toEmitableEvent() = EmitableEvent(name, eventContent)
}

class WhipEmitableEvent private constructor(
  private val event: EventName,
  private val eventContent: Any? = null
) {
  enum class EventName {
    Warning,
    WhipPeerConnectionStateChanged,
  }

  val name: String
    get() = event.name

  val data: Map<String, Any?>
    get() = mapOf(event.name to eventContent)

  companion object {
    fun warning(message: String) = WhipEmitableEvent(EventName.Warning, message).toEmitableEvent()

    fun whipPeerConnectionStateChanged(status: PeerConnection.PeerConnectionState) = WhipEmitableEvent(EventName.WhipPeerConnectionStateChanged, status.stringValue()).toEmitableEvent()

    val allEvents: Array<String>
      get() = EventName.entries.map { it.name }.toTypedArray()
  }

  private fun toEmitableEvent() = EmitableEvent(name, eventContent)
}
