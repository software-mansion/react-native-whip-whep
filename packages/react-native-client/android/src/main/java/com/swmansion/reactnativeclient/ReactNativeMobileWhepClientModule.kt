package com.swmansion.reactnativeclient

import android.content.Context
import com.mobilewhep.client.ClientBaseListener
import com.mobilewhep.client.ClientConnectOptions
import com.mobilewhep.client.ReconnectionManagerListener
import com.mobilewhep.client.VideoParameters
import com.mobilewhep.client.WhepClient
import com.mobilewhep.client.WhepConfigurationOptions
import com.mobilewhep.client.WhipClient
import com.mobilewhep.client.WhipConfigurationOptions
import com.mobilewhep.client.utils.PeerConnectionFactoryHelper
import com.swmansion.reactnativeclient.helpers.PermissionUtils
import expo.modules.kotlin.functions.Coroutine
import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.webrtc.EglBase
import org.webrtc.MediaStreamTrack
import org.webrtc.VideoTrack

class ReactNativeMobileWhepClientModule :
  Module(),
  ReconnectionManagerListener {
  interface OnTrackUpdateListener {
    fun onTrackUpdate(track: VideoTrack)
  }

  companion object {
    var onWhipTrackUpdateListeners: MutableList<OnTrackUpdateListener> = mutableListOf()
    var onWhepTrackUpdateListeners: MutableList<OnTrackUpdateListener> = mutableListOf()
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

      Function("createWhipClient") {  configurationOptions: Map<String, Any>?, preferredVideoCodecs: List<String>?, preferredAudioCodecs: List<String>? ->
        val context: Context =
          appContext.reactContext ?: throw IllegalStateException("React context is not available")
        val options =
          WhipConfigurationOptions(
            stunServerUrl = configurationOptions?.get("stunServerUrl") as? String,
            audioEnabled = configurationOptions?.get("audioEnabled") as? Boolean ?: true,
            videoEnabled = configurationOptions?.get("videoEnabled") as? Boolean ?: true,
            videoParameters = configurationOptions?.get("videoParameters") as? VideoParameters
              ?: VideoParameters.presetFHD169,
            videoDevice = configurationOptions?.get("videoDeviceId") as? String,
            preferredAudioCodecs = preferredAudioCodecs ?: listOf(),
            preferredVideoCodecs = preferredVideoCodecs ?: listOf()
          )

        if (options.videoEnabled == true && !PermissionUtils.hasCameraPermission(appContext)) {
          emit(EmitableEvent.warning("Camera permission not granted. Cannot initialize WhipClient."))
          return@Function
        }

        if (options.audioEnabled == true && !PermissionUtils.hasMicrophonePermission(appContext)) {
          emit(EmitableEvent.warning("Microphone permission not granted. Cannot initialize WhipClient."))
          return@Function
        }

        whipClient = WhipClient(context, options)
        whipClient?.addTrackListener(object : ClientBaseListener {
          override fun onTrackAdded(track: VideoTrack) {
            onWhipTrackUpdateListeners.forEach { it.onTrackUpdate(track) }
          }
        })
        whipClient?.onConnectionStateChanged = { newState ->
            emit(EmitableEvent.whipPeerConnectionStateChanged(newState))
        }
      }

      AsyncFunction("connectWhip") Coroutine { serverUrl: String, authToken: String? ->
        withContext(Dispatchers.IO) {
          if (whipClient == null) {
            throw IllegalStateException("WHIP client not found. Make sure it was initialized properly.")
          }
          whipClient?.connect(ClientConnectOptions(serverUrl = serverUrl, authToken = authToken))
        }
      }

      AsyncFunction("disconnectWhip") Coroutine { ->
        whipClient?.disconnect()
      }

      Function("switchCamera") { deviceId: String ->
        whipClient?.switchCamera(deviceId)
      }

      Function("cleanupWhip") {
        whipClient?.cleanup()
        return@Function Unit
      }

      Function("getSupportedSenderVideoCodecsNames") {
        val context: Context =
          appContext.reactContext ?: throw IllegalStateException("React context is not available")

        val eglBase: EglBase =
          whipClient?.eglBase ?: throw IllegalStateException("Whip client is not available")

        val capabilities = PeerConnectionFactoryHelper.getFactory(context, eglBase).getRtpSenderCapabilities(
          MediaStreamTrack.MediaType.MEDIA_TYPE_VIDEO)

        return@Function capabilities.codecs.map { it.name }
      }

      Function("getSupportedSenderAudioCodecsNames") {
        val context: Context =
          appContext.reactContext ?: throw IllegalStateException("React context is not available")
        val eglBase: EglBase =
          whipClient?.eglBase ?: throw IllegalStateException("Whip client is not available")

        val capabilities = PeerConnectionFactoryHelper.getFactory(context, eglBase).getRtpSenderCapabilities(
          MediaStreamTrack.MediaType.MEDIA_TYPE_AUDIO)

        return@Function capabilities.codecs.map { it.name }
      }

      Property("cameras") {
        return@Property getCaptureDevices()
      }

      Property("currentCameraDeviceId") {
        return@Property whipClient?.currentCameraDeviceId
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
