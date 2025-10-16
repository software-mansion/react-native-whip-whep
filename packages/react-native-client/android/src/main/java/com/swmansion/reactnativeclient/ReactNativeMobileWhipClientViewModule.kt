package com.swmansion.reactnativeclient

import android.content.Context
import com.mobilewhep.client.ClientBaseListener
import com.mobilewhep.client.ClientConnectOptions
import com.mobilewhep.client.VideoParameters
import com.mobilewhep.client.WhipClient
import com.mobilewhep.client.WhipConfigurationOptions
import com.mobilewhep.client.utils.PeerConnectionFactoryHelper
import com.swmansion.reactnativeclient.helpers.PermissionUtils
import expo.modules.kotlin.functions.Coroutine
import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition
import expo.modules.kotlin.records.Field
import expo.modules.kotlin.records.Record
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.webrtc.EglBase
import org.webrtc.MediaStreamTrack
import org.webrtc.VideoTrack

class ReactNativeMobileWhipClientViewModule : Module() {
  interface OnTrackUpdateListener {
    fun onTrackUpdate(track: VideoTrack)
  }

  companion object {
    var onWhipTrackUpdateListeners: MutableList<ReactNativeMobileWhipClientViewModule.OnTrackUpdateListener> = mutableListOf()
    var whipClient: WhipClient? = null
  }

  class ConfigurationOptions : Record {
    @Field
    val audioEnabled: Boolean? = null
    @Field
    val videoEnabled: Boolean? = null
    @Field
    val videoDeviceId: String? = null
    @Field
    val videoParameters: String? = null
    @Field
    val stunServerUrl: String? = null
    @Field
    val preferredVideoCodecs: List<String>? = null
    @Field
    val preferredAudioCodecs: List<String>? = null
  }

  class ConnectionOptions : Record {
    @Field
    val serverUrl: String = ""
    @Field
    val authToken: String? = null
  }

  private fun getVideoParametersFromOptions(createOptions: String): VideoParameters {
    return when (createOptions) {
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

  private fun getDefaultCameraDevice(): String {
    val devices = WhipClient.getCaptureDevices(appContext.reactContext!!)
    // Prefer back camera, fallback to front camera, then first available
    return devices.find { it.isBackFacing }?.deviceName
      ?: devices.find { it.isFrontFacing }?.deviceName
      ?: devices.firstOrNull()?.deviceName
      ?: throw IllegalStateException("No camera devices found")
  }

  private fun emit(event: EmitableEvent) {
    sendEvent(event.name, event.data)
  }


  override fun definition() =
    ModuleDefinition {
      Name("ReactNativeMobileWhipClientViewModule")

      Events(WhipEmitableEvent.allEvents)

      Property("cameras") {
        return@Property getCaptureDevices()
      }

      View(ReactNativeMobileWhipClientView::class) {
        AsyncFunction("initializeCamera") { view: ReactNativeMobileWhipClientView , configurationOptions: ConfigurationOptions? ->
          val context: Context =
            appContext.reactContext ?: throw IllegalStateException("React context is not available")

          val parsedVideoParameters: VideoParameters =
            if (configurationOptions?.videoParameters != null) {
              getVideoParametersFromOptions(configurationOptions.videoParameters)
            } else {
              VideoParameters.presetHD169
            }

          // Get default camera device if none provided
          val videoDeviceId = configurationOptions?.videoDeviceId ?: getDefaultCameraDevice()

          val options =
            WhipConfigurationOptions(
              stunServerUrl = configurationOptions?.stunServerUrl,
              audioEnabled = configurationOptions?.audioEnabled ?: true,
              videoEnabled = configurationOptions?.videoEnabled ?: true,
              videoParameters = parsedVideoParameters,
              videoDevice = videoDeviceId,
              preferredAudioCodecs = configurationOptions?.preferredAudioCodecs ?: listOf(),
              preferredVideoCodecs = configurationOptions?.preferredVideoCodecs ?: listOf()
            )

          if (options.videoEnabled && !PermissionUtils.hasCameraPermission(appContext)) {
            emit(WhipEmitableEvent.warning("Camera permission not granted. Cannot initialize WhipClient."))
            return@AsyncFunction
          }

          if (options.audioEnabled && !PermissionUtils.hasMicrophonePermission(appContext)) {
            emit(WhipEmitableEvent.warning("Microphone permission not granted. Cannot initialize WhipClient."))
            return@AsyncFunction
          }

          whipClient = WhipClient(context, options)
          view.player = whipClient
          whipClient?.addTrackListener(object : ClientBaseListener {
            override fun onTrackAdded(track: VideoTrack) {
              onWhipTrackUpdateListeners.forEach { it.onTrackUpdate(track) }
            }
          })
          whipClient?.onConnectionStateChanged = { newState ->
            emit(WhipEmitableEvent.whipPeerConnectionStateChanged(newState))
          }
        }

        AsyncFunction("connect") Coroutine { options: ConnectionOptions ->
          withContext(Dispatchers.IO) {
            if (whipClient == null) {
              throw IllegalStateException("WHIP client not found. Make sure it was initialized properly.")
            }
            whipClient?.connect(ClientConnectOptions(serverUrl = options.serverUrl, authToken = options.authToken))
          }
        }

        AsyncFunction("disconnect") Coroutine { ->
          whipClient?.disconnect()
        }

        AsyncFunction("flipCamera") {
          if (whipClient == null) {
            throw IllegalStateException("WHIP client not found. Make sure it was initialized properly.")
          }

          val currentCameraId = whipClient?.currentCameraDeviceId
            ?: throw IllegalStateException("No camera found.")

          val devices = WhipClient.getCaptureDevices(appContext.reactContext!!)
          val currentCamera = devices.find { it.deviceName == currentCameraId }

          val oppositeCamera = devices.find { device ->
            when {
              currentCamera?.isFrontFacing == true -> device.isBackFacing
              currentCamera?.isBackFacing == true -> device.isFrontFacing
              else -> false
            }
          }

          if (oppositeCamera == null) {
            throw IllegalStateException("No camera found.")
          }

          whipClient?.switchCamera(oppositeCamera.deviceName)
        }

        AsyncFunction("switchCamera") { deviceId: String ->
          whipClient?.switchCamera(deviceId)
        }

        AsyncFunction("cleanup") {
          whipClient?.cleanup()
          return@AsyncFunction Unit
        }

        AsyncFunction("getSupportedSenderVideoCodecsNames") {
          val context: Context =
            appContext.reactContext ?: throw IllegalStateException("React context is not available")

          val eglBase: EglBase =
            whipClient?.eglBase ?: throw IllegalStateException("Whip client is not available")

          val capabilities = PeerConnectionFactoryHelper.getFactory(context, eglBase).getRtpSenderCapabilities(
            MediaStreamTrack.MediaType.MEDIA_TYPE_VIDEO)

          return@AsyncFunction capabilities.codecs.map { it.name }
        }

        AsyncFunction("getSupportedSenderAudioCodecsNames") {
          val context: Context =
            appContext.reactContext ?: throw IllegalStateException("React context is not available")
          val eglBase: EglBase =
            whipClient?.eglBase ?: throw IllegalStateException("Whip client is not available")

          val capabilities = PeerConnectionFactoryHelper.getFactory(context, eglBase).getRtpSenderCapabilities(
            MediaStreamTrack.MediaType.MEDIA_TYPE_AUDIO)

          return@AsyncFunction capabilities.codecs.map { it.name }
        }

        AsyncFunction("currentCameraDeviceId") {
          return@AsyncFunction whipClient?.currentCameraDeviceId
        }
      }
    }
}
