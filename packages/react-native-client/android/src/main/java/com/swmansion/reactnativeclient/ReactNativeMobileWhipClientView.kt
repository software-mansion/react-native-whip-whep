package com.swmansion.reactnativeclient

import android.content.Context
import com.mobilewhep.client.ClientBaseListener
import com.mobilewhep.client.ClientConnectOptions
import com.mobilewhep.client.VideoView
import com.mobilewhep.client.WhipClient
import com.mobilewhep.client.WhipConfigurationOptions
import com.mobilewhep.client.utils.PeerConnectionFactoryHelper
import com.swmansion.reactnativeclient.ReactNativeMobileWhipClientViewModule.ConnectionOptions
import expo.modules.kotlin.AppContext
import expo.modules.kotlin.views.ExpoView
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import org.webrtc.EglBase
import org.webrtc.MediaStreamTrack
import org.webrtc.PeerConnection
import org.webrtc.VideoTrack

class ReactNativeMobileWhipClientView(
  context: Context,
  appContext: AppContext,
) : ExpoView(context, appContext) {
  private var videoView: VideoView? = null

  private var whipClient: WhipClient? = null

  fun createWhipClient(appContext: Context, configurationOptions: WhipConfigurationOptions, onConnectionStatusChange: (PeerConnection.PeerConnectionState) -> Unit) {
    whipClient = WhipClient(context, configurationOptions)
    whipClient?.addTrackListener(object : ClientBaseListener {
      override fun onTrackAdded(track: VideoTrack) {
        onTrackUpdate(track)
      }
    })
    whipClient?.onConnectionStateChanged = onConnectionStatusChange
  }

  suspend fun connect(options: ConnectionOptions) {
    if (whipClient == null) {
      throw IllegalStateException("WHIP client not found. Make sure it was initialized properly.")
    }
    whipClient?.connect(ClientConnectOptions(serverUrl = options.serverUrl, authToken = options.authToken))
  }

  suspend fun disconnect() {
    whipClient?.disconnect()
  }

  fun flipCamera() {
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

  fun switchCamera(deviceId: String) {
    whipClient?.switchCamera(deviceId)
  }

  fun getSupportedSenderVideoCodecsNames(): List<String> {
    val context: Context =
      appContext.reactContext ?: throw IllegalStateException("React context is not available")

    val eglBase: EglBase =
      whipClient?.eglBase ?: throw IllegalStateException("Whip client is not available")

    val capabilities = PeerConnectionFactoryHelper.getFactory(context, eglBase).getRtpSenderCapabilities(
      MediaStreamTrack.MediaType.MEDIA_TYPE_VIDEO)

    return capabilities.codecs.map { it.name }
  }

  fun getSupportedSenderAudioCodecsNames(): List<String> {
    val context: Context =
      appContext.reactContext ?: throw IllegalStateException("React context is not available")
    val eglBase: EglBase =
      whipClient?.eglBase ?: throw IllegalStateException("Whip client is not available")

    val capabilities = PeerConnectionFactoryHelper.getFactory(context, eglBase).getRtpSenderCapabilities(
      MediaStreamTrack.MediaType.MEDIA_TYPE_AUDIO)

    return capabilities.codecs.map { it.name }
  }

  fun getCurrentCameraDeviceId(): String? {
    return whipClient?.currentCameraDeviceId
  }

  private fun setupTrack(videoTrack: VideoTrack) {
    if (whipClient == null) return

    if (videoView == null) {
      videoView = VideoView(context, whipClient!!.eglBase)
      videoView!!.player = whipClient

      // Set layout parameters to fill parent
      videoView!!.layoutParams = android.view.ViewGroup.LayoutParams(
        android.view.ViewGroup.LayoutParams.MATCH_PARENT,
        android.view.ViewGroup.LayoutParams.MATCH_PARENT
      )

      addView(videoView)
    }

    // Wait for layout, then setup video track
    videoView!!.post {
      // If VideoView has no dimensions, use parent dimensions
      if (videoView!!.width == 0 || videoView!!.height == 0) {
        val parentWidth = this@ReactNativeMobileWhipClientView.width
        val parentHeight = this@ReactNativeMobileWhipClientView.height
        if (parentWidth > 0 && parentHeight > 0) {
          videoView!!.layout(0, 0, parentWidth, parentHeight)
        }
      }

      setupVideoTrack(videoTrack)
    }
  }

  private fun setupVideoTrack(videoTrack: VideoTrack) {
    videoView!!.player?.videoTrack?.removeSink(videoView)
    videoView!!.player?.videoTrack = videoTrack
    videoTrack.addSink(videoView)
  }

  private fun update(track: VideoTrack) {
    CoroutineScope(Dispatchers.Main).launch {
      setupTrack(track)
    }
  }

  private fun onTrackUpdate(track: VideoTrack) {
    update(track)
  }

  override fun onAttachedToWindow() {
    super.onAttachedToWindow()

    // Ensure the view is properly laid out before setting up video track
    post {
      if (videoView != null && whipClient != null) {
        // Re-trigger video track setup if player and videoView are ready
        whipClient?.videoTrack?.let { track ->
          setupTrack(track)
        }
      }
    }
  }

  override fun onDetachedFromWindow() {
    super.onDetachedFromWindow()
    whipClient?.cleanup()
  }
}
