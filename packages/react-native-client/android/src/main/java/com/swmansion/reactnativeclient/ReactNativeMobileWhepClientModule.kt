package com.swmansion.reactnativeclient

import android.content.Context
import com.mobilewhep.client.ClientBaseListener
import com.mobilewhep.client.ClientConnectOptions
import com.mobilewhep.client.ReconnectionManagerListener
import com.mobilewhep.client.VideoParameters
import com.mobilewhep.client.WhepClient
import com.mobilewhep.client.WhepConfigurationOptions
import expo.modules.kotlin.functions.Coroutine
import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.webrtc.VideoTrack

class ReactNativeMobileWhepClientModule :
  Module(),
  ReconnectionManagerListener {
  interface OnTrackUpdateListener {
    fun onTrackUpdate(track: VideoTrack)
  }

  companion object {
    var onWhepTrackUpdateListeners: MutableList<OnTrackUpdateListener> = mutableListOf()
    var whepClient: WhepClient? = null
  }

  private fun getVideoParametersFromOptions(createOptions: String): VideoParameters {
    var videoParameters =
      when (createOptions) {
        "QVGA169" -> VideoParameters.presetQVGA169
        "VGA169" -> VideoParameters.presetVGA169
        "QHD169" -> VideoParameters.presetQHD169
        "HD169" -> VideoParameters.presetHD169
        "FHD169" -> VideoParameters.presetFHD169
        "QVGA43" -> VideoParameters.presetQVGA43
        "VGA43" -> VideoParameters.presetVGA43
        "QHD43" -> VideoParameters.presetQHD43
        "HD43" -> VideoParameters.presetHD43
        "FHD43" -> VideoParameters.presetFHD43
        else -> VideoParameters.presetVGA169
      }
    videoParameters =
      videoParameters.copy(
        dimensions = videoParameters.dimensions,
      )
    return videoParameters
  }

  override fun definition() =
    ModuleDefinition {
      Name("ReactNativeMobileWhepClient")

      Events(EmitableEvent.allEvents)

      Function("createWhepClient") { configurationOptions: Map<String, Any>?, preferredVideoCodecs: List<String>?, preferredAudioCodecs: List<String>? ->
        val context: Context =
          appContext.reactContext ?: throw IllegalStateException("React context is not available")
        val options =
          WhepConfigurationOptions(
            stunServerUrl = configurationOptions?.get("stunServerUrl") as? String,
            audioEnabled = configurationOptions?.get("audioEnabled") as? Boolean ?: true,
            videoEnabled = configurationOptions?.get("videoEnabled") as? Boolean ?: true,
            preferredAudioCodecs = preferredAudioCodecs ?: listOf(),
            preferredVideoCodecs = preferredVideoCodecs ?: listOf()
          )
        whepClient = WhepClient(context, options)
        whepClient?.addReconnectionListener(this@ReactNativeMobileWhepClientModule)
        whepClient?.addTrackListener(object : ClientBaseListener {
          override fun onTrackAdded(track: VideoTrack) {
            onWhepTrackUpdateListeners.forEach { it.onTrackUpdate(track) }
          }
        })
        whepClient?.onConnectionStateChanged = { newState ->
          emit(EmitableEvent.whepPeerConnectionStateChanged(newState))
        }
      }

      AsyncFunction("connectWhep") Coroutine { serverUrl: String, authToken: String? ->
        if (whepClient == null) {
          throw IllegalStateException("React context is not available")
        }
        withContext(Dispatchers.IO) {
          whepClient?.connect(ClientConnectOptions(serverUrl = serverUrl, authToken = authToken))
        }
      }

      AsyncFunction("disconnectWhep") Coroutine { ->
        whepClient?.disconnect()
        whepClient = null
      }

      Function("pauseWhep") {
        whepClient?.pause()
      }

      Function("unpauseWhep") {
        whepClient?.unpause()
      }
    }

  fun emit(event: EmitableEvent) {
    sendEvent(event.name, event.data)
  }


  override fun onReconnectionStarted() {
    super.onReconnectionStarted()
    emit(EmitableEvent.reconnectionStatusChanged(ReconnectionStatus.ReconnectionStarted))
  }

  override fun onReconnected() {
    super.onReconnected()
    emit(EmitableEvent.reconnectionStatusChanged(ReconnectionStatus.Reconnected))
  }

  override fun onReconnectionRetriesLimitReached() {
    super.onReconnectionRetriesLimitReached()
    emit(EmitableEvent.reconnectionStatusChanged(ReconnectionStatus.ReconnectionRetriesLimitReached))
  }
}
