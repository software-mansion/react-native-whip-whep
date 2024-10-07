package com.swmansion.reactnativeclient

import android.content.Context
import com.mobilewhep.client.ClientBaseListener
import com.mobilewhep.client.ConfigurationOptions
import com.mobilewhep.client.VideoParameters
import com.mobilewhep.client.WhepClient
import com.mobilewhep.client.WhipClient
import expo.modules.kotlin.functions.Coroutine
import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.webrtc.VideoTrack

class ReactNativeMobileWhepClientModule :
  Module(),
  ClientBaseListener {
  interface OnTrackUpdateListener {
    fun onTrackUpdate(track: VideoTrack)
  }

  companion object {
    var onTrackUpdateListeners: MutableList<OnTrackUpdateListener> = mutableListOf()
    lateinit var whepClient: WhepClient
    lateinit var whipClient: WhipClient
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

      Events("trackAdded")

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
        whepClient.addTrackListener(this@ReactNativeMobileWhepClientModule)
      }

      AsyncFunction("connectWhep") Coroutine { ->
        withContext(Dispatchers.IO) {
          whepClient.connect()
        }
      }

      Function("disconnectWhep") {
        whepClient.disconnect()
      }

      Function("pauseWhep") {
        whepClient.pause()
      }

      Function("unpauseWhep") {
        whepClient.unpause()
      }

      Function("createWhipClient") { serverUrl: String, configurationOptions: Map<String, Any>?, videoDevice: String ->
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
        whipClient = WhipClient(context, serverUrl, options, videoDevice)
        whipClient.addTrackListener(this@ReactNativeMobileWhepClientModule)
      }

      AsyncFunction("connectWhip") Coroutine { ->
        withContext(Dispatchers.IO) {
          whipClient.connect()
        }
      }

      Function("disconnectWhip") {
        whipClient.disconnect()
      }

      Property("cameras") {
        return@Property getCaptureDevices()
      }
    }

  override fun onTrackAdded(track: VideoTrack) {
    sendEvent("trackAdded", mapOf(track.id() to track.kind()))
    onTrackUpdateListeners.forEach { it.onTrackUpdate(track) }
  }
}
