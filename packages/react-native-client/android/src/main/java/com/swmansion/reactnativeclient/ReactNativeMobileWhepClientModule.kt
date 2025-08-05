package com.swmansion.reactnativeclient

import android.content.Context
import android.util.Log
import com.mobilewhep.client.ClientBaseListener
import com.mobilewhep.client.ConfigurationOptions
import com.mobilewhep.client.ReconnectionManagerListener
import com.mobilewhep.client.VideoParameters
import com.mobilewhep.client.WhepClient
import com.mobilewhep.client.WhipClient
import com.swmansion.reactnativeclient.helpers.PermissionUtils
import expo.modules.kotlin.functions.Coroutine
import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.webrtc.VideoTrack

class ReactNativeMobileWhepClientModule :
  Module(),
  ClientBaseListener,
  ReconnectionManagerListener {
  interface OnTrackUpdateListener {
    fun onTrackUpdate(track: VideoTrack)
  }

  companion object {
    var onTrackUpdateListeners: MutableList<OnTrackUpdateListener> = mutableListOf()
    var whepClient: WhepClient? = null
    var whipClient: WhipClient? = null
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


  private fun getCaptureDevices(): List<Map<String, Any>> {
    val devices = WhipClient.getCaptureDevices(appContext.reactContext!!)
    return devices.map { device ->
      mapOf<String, Any>(
        "id" to device.deviceName,
        "name" to device.deviceName,
        "facingDirection" to
          when (true) {
            device.isFrontFacing -> "front"
            device.isBackFacing -> "back"
            else -> "unspecified"
          }
      )
    }
  }

  override fun definition() =
    ModuleDefinition {
      Name("ReactNativeMobileWhepClient")

      Events(EmitableEvent.allEvents)

      Function("createWhepClient") { serverUrl: String, configurationOptions: Map<String, Any>? ->
        val context: Context =
          appContext.reactContext ?: throw IllegalStateException("React context is not available")
        val options =
          ConfigurationOptions(
            authToken = configurationOptions?.get("authToken") as? String,
            stunServerUrl = configurationOptions?.get("stunServerUrl") as? String,
            audioEnabled = configurationOptions?.get("audioEnabled") as? Boolean ?: true,
            videoEnabled = configurationOptions?.get("videoEnabled") as? Boolean ?: true,
            videoParameters = getVideoParametersFromOptions(
              configurationOptions?.get("videoParameters") as? String ?: "HD43"
            ),
          )
        whepClient = WhepClient(context, serverUrl, options)
        whepClient?.addReconnectionListener(this@ReactNativeMobileWhepClientModule)
        whepClient?.addTrackListener(this@ReactNativeMobileWhepClientModule)
        whepClient?.onConnectionStateChanged = { newState ->
          emit(EmitableEvent.whepPeerConnectionStateChanged(newState))
        }
      }

      AsyncFunction("connectWhep") Coroutine { ->
        if (whepClient == null) {
          throw IllegalStateException("React context is not available")
        }
        withContext(Dispatchers.IO) {
          whepClient?.connect()
        }
      }

      Function("disconnectWhep") {
        whepClient?.disconnect()
      }

      Function("pauseWhep") {
        whepClient?.pause()
      }

      Function("unpauseWhep") {
        whepClient?.unpause()
      }

      AsyncFunction("createWhipClient") Coroutine { serverUrl: String, configurationOptions: Map<String, Any>?, videoDevice: String ->
        val context: Context =
          appContext.reactContext ?: throw IllegalStateException("React context is not available")
        val options =
          ConfigurationOptions(
            authToken = configurationOptions?.get("authToken") as? String,
            stunServerUrl = configurationOptions?.get("stunServerUrl") as? String,
            audioEnabled = configurationOptions?.get("audioEnabled") as? Boolean ?: true,
            videoEnabled = configurationOptions?.get("videoEnabled") as? Boolean ?: true,
            videoParameters = configurationOptions?.get("videoParameters") as? VideoParameters
              ?: VideoParameters.presetFHD43,
          )

        if (options.videoEnabled == true && !PermissionUtils.requestCameraPermission(appContext)) {
          emit(EmitableEvent.warning("Camera permission not granted. Cannot initialize WhipClient."))
          return@Coroutine
        }

        if (options.audioEnabled == true && !PermissionUtils.requestMicrophonePermission(appContext)) {
          emit(EmitableEvent.warning("Microphone permission not granted. Cannot initialize WhipClient."))
          return@Coroutine
        }

        whipClient = WhipClient(context, serverUrl, options, videoDevice)
        whipClient?.addTrackListener(this@ReactNativeMobileWhepClientModule)
        whipClient?.onConnectionStateChanged = { newState ->
            emit(EmitableEvent.whipPeerConnectionStateChanged(newState))
        }
      }

      AsyncFunction("connectWhip") Coroutine { ->
        withContext(Dispatchers.IO) {
          if (whipClient == null) {
            throw IllegalStateException("WHIP client not found. Make sure it was initialized properly.")
          }
          whipClient?.connect()
        }
      }

      Function("disconnectWhip") {
        whipClient?.disconnect()
      }

      Property("cameras") {
        return@Property getCaptureDevices()
      }
    }

  fun emit(event: EmitableEvent) {
    sendEvent(event.name, event.data)
  }

  override fun onTrackAdded(track: VideoTrack) {
    onTrackUpdateListeners.forEach { it.onTrackUpdate(track) }
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
