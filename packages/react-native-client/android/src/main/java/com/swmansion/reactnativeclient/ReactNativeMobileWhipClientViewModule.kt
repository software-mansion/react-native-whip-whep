package com.swmansion.reactnativeclient

import android.app.Activity
import android.content.Context
import android.media.projection.MediaProjectionManager
import androidx.appcompat.app.AppCompatActivity
import com.mobilewhep.client.VideoParameters
import com.mobilewhep.client.WhipClient
import com.mobilewhep.client.WhipConfigurationOptions
import com.swmansion.reactnativeclient.foregroundService.ForegroundServiceManager
import com.swmansion.reactnativeclient.helpers.PermissionUtils
import expo.modules.kotlin.functions.Coroutine
import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition
import expo.modules.kotlin.records.Field
import expo.modules.kotlin.records.Record
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class ReactNativeMobileWhipClientViewModule : Module() {
  companion object {
    private const val SCREENSHARE_REQUEST_CODE = 1001
  }
  
  private var pendingScreenShareView: ReactNativeMobileWhipClientView? = null
  private lateinit var foregroundServiceManager: ForegroundServiceManager

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

      OnCreate {
        foregroundServiceManager = ForegroundServiceManager(appContext)
      }

      OnDestroy {
        foregroundServiceManager.stop()
      }

      OnActivityResult { _, result ->
        if (result.requestCode == SCREENSHARE_REQUEST_CODE) {
          val view = pendingScreenShareView
          if (view != null && result.resultCode == Activity.RESULT_OK && result.data != null) {
            // Store the MediaProjection intent in the view
            view.mediaProjectionIntent = result.data
            
            // Start foreground service, then start screen share
            CoroutineScope(Dispatchers.Main).launch {
              try {
                foregroundServiceManager.updateService { screenSharingEnabled = true }
                foregroundServiceManager.start()
                
                // Start screen share after service is running
                view.startScreenShare()
                pendingScreenShareView = null
              } catch (e: Exception) {
                android.util.Log.e("WhipWhepModule", "Failed to start screen share", e)
                pendingScreenShareView = null
              }
            }
          } else {
            // Permission denied or canceled
            pendingScreenShareView = null
          }
        }
      }

      Events(WhipEmitableEvent.allEvents)

      Property("cameras") {
        return@Property getCaptureDevices()
      }

      View(ReactNativeMobileWhipClientView::class) {
        AsyncFunction("initializeCamera") { view: ReactNativeMobileWhipClientView, configurationOptions: ConfigurationOptions?, videoDeviceId: String? ->
          val context: Context =
            appContext.reactContext ?: throw IllegalStateException("React context is not available")

          val parsedVideoParameters: VideoParameters =
            if (configurationOptions?.videoParameters != null) {
              getVideoParametersFromOptions(configurationOptions.videoParameters)
            } else {
              VideoParameters.presetHD169
            }

          val options =
            WhipConfigurationOptions(
              stunServerUrl = configurationOptions?.stunServerUrl,
              audioEnabled = configurationOptions?.audioEnabled ?: true,
              videoEnabled = configurationOptions?.videoEnabled ?: true,
              videoParameters = parsedVideoParameters,
              videoDevice = videoDeviceId ?: getDefaultCameraDevice(),
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

          view.createWhipClient(context, options) {
            emit(WhipEmitableEvent.whipPeerConnectionStateChanged(it))
          }
        }

        AsyncFunction("initializeScreenShare") { view: ReactNativeMobileWhipClientView, configurationOptions: ConfigurationOptions? ->
          val context: Context =
            appContext.reactContext ?: throw IllegalStateException("React context is not available")

          val parsedVideoParameters: VideoParameters =
            if (configurationOptions?.videoParameters != null) {
              getVideoParametersFromOptions(configurationOptions.videoParameters)
            } else {
              VideoParameters.presetHD169
            }

          val options =
            WhipConfigurationOptions(
              stunServerUrl = configurationOptions?.stunServerUrl,
              audioEnabled = configurationOptions?.audioEnabled ?: true,
              videoEnabled = false,
              videoParameters = parsedVideoParameters,
              videoDevice = null,
              preferredAudioCodecs = configurationOptions?.preferredAudioCodecs ?: listOf(),
              preferredVideoCodecs = configurationOptions?.preferredVideoCodecs ?: listOf()
            )

          if (options.audioEnabled && !PermissionUtils.hasMicrophonePermission(appContext)) {
            emit(WhipEmitableEvent.warning("Microphone permission not granted. Cannot initialize WhipClient."))
            return@AsyncFunction
          }

          view.createWhipClient(context, options) {
            emit(WhipEmitableEvent.whipPeerConnectionStateChanged(it))
          }

          // Store view reference for later use in OnActivityResult
          pendingScreenShareView = view

          // Request MediaProjection permission
          val currentActivity = appContext.currentActivity ?: throw IllegalStateException("Activity not available")
          val mediaProjectionManager = context.getSystemService(AppCompatActivity.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
          val intent = mediaProjectionManager.createScreenCaptureIntent()
          currentActivity.startActivityForResult(intent, SCREENSHARE_REQUEST_CODE)
        }

        AsyncFunction("connect") Coroutine { view: ReactNativeMobileWhipClientView, options: ConnectionOptions ->
          withContext(Dispatchers.IO) {
            view.connect(options)
          }
        }

        AsyncFunction("disconnect") Coroutine { view: ReactNativeMobileWhipClientView ->
          view.disconnect()
        }

        AsyncFunction("flipCamera") { view: ReactNativeMobileWhipClientView ->
          view.flipCamera()
        }

        AsyncFunction("switchCamera") { view: ReactNativeMobileWhipClientView, deviceId: String ->
          view.switchCamera(deviceId)
        }

        AsyncFunction("getSupportedSenderVideoCodecsNames") { view: ReactNativeMobileWhipClientView ->
          return@AsyncFunction view.getSupportedSenderVideoCodecsNames()
        }

        AsyncFunction("getSupportedSenderAudioCodecsNames") { view: ReactNativeMobileWhipClientView ->
          return@AsyncFunction view.getSupportedSenderAudioCodecsNames()
        }

        AsyncFunction("currentCameraDeviceId") { view: ReactNativeMobileWhipClientView ->
          return@AsyncFunction view.getCurrentCameraDeviceId()
        }
      }
    }
}
