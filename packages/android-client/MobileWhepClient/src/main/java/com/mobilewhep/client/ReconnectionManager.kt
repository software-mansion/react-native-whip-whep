package com.mobilewhep.client

import android.util.Log
import java.util.Timer
import kotlin.concurrent.schedule

private const val TAG = "ReconnectionManager"

data class ReconnectConfig(
  val maxAttempts: Int = 5,
  val initialDelayMs: Long = 1000,
  val delayMs: Long = 1000
)

interface ReconnectionManagerListener {
  fun onReconnectionStarted() {
    Log.i(TAG, "Reconnection started")
  }

  fun onReconnected() {
    Log.i(TAG, "Reconnected successfully")
  }

  fun onReconnectionRetriesLimitReached() {
    Log.e(TAG, "Reconnection retries limit reached")
  }
}

enum class ReconnectionStatus(
  val status: String
) {
  Idle("idle"),
  Reconnecting("reconnecting"),
  Error("error")
}

internal class ReconnectionManager(
  private var reconnectConfig: ReconnectConfig = ReconnectConfig(),
  private val connect: () -> Unit
) {
  private val listeners = mutableListOf<ReconnectionManagerListener>()
  private var reconnectAttempts = 0
  private var reconnectionStatus = ReconnectionStatus.Idle

  // attempts to reconnect if suitable
  fun onDisconnected() {
    if (reconnectAttempts >= reconnectConfig.maxAttempts) {
      reconnectionStatus = ReconnectionStatus.Error
      listeners.forEach { it.onReconnectionRetriesLimitReached() }
      return
    }

    if (reconnectionStatus == ReconnectionStatus.Reconnecting) {
      return
    }
    reconnectionStatus = ReconnectionStatus.Reconnecting

    listeners.forEach { it.onReconnectionStarted() }
    val delay = reconnectConfig.initialDelayMs + reconnectAttempts * reconnectConfig.delayMs
    reconnectAttempts += 1

    Timer().schedule(delay) {
      connect()
    }
  }

  fun onReconnected() {
    if (reconnectionStatus != ReconnectionStatus.Reconnecting) {
      return
    }
    reset()
    listeners.forEach { it.onReconnected() }
  }

  fun reset() {
    reconnectAttempts = 0
    reconnectionStatus = ReconnectionStatus.Idle
  }

  fun addListener(listener: ReconnectionManagerListener) {
    listeners.add(listener)
  }

  fun removeListener(listener: ReconnectionManagerListener) {
    listeners.remove(listener)
  }
}
