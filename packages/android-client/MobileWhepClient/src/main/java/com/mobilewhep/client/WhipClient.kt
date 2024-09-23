package com.mobilewhep.client

import android.content.Context
import android.util.Log
import org.webrtc.Camera1Enumerator
import org.webrtc.Camera2Enumerator
import org.webrtc.CameraEnumerationAndroid
import org.webrtc.CameraEnumerator
import org.webrtc.CameraVideoCapturer
import org.webrtc.MediaConstraints
import org.webrtc.PeerConnection
import org.webrtc.RtpTransceiver
import org.webrtc.SessionDescription
import org.webrtc.Size
import org.webrtc.SurfaceTextureHelper
import org.webrtc.VideoCapturer
import org.webrtc.VideoSource
import org.webrtc.VideoTrack
import java.util.UUID

class WhipClient(
  appContext: Context,
  serverUrl: String,
  private val configurationOptions: ConfigurationOptions? = null,
  private var videoDevice: String? = null
) : ClientBase(
    appContext,
    serverUrl,
    configurationOptions
  ) {
  override var videoTrack: VideoTrack? = null
  private var videoCapturer: VideoCapturer? = null
  private var videoSource: VideoSource? = null

  init {
    setUpVideoAndAudioDevices()
  }

  /**
   * Gets the video and audio devices, prepares them, starts capture and adds it to the Peer Connection.
   *
   * @throws CaptureDeviceError.VideoDeviceNotAvailable if there is no video device.
   */
  private fun setUpVideoAndAudioDevices() {
    if (videoDevice == null) {
      throw CaptureDeviceError.VideoDeviceNotAvailable("Video device not found. Check if it can be accessed and passed to the constructor.")
    }

    val audioEnabled = configurationOptions?.audioEnabled ?: true
    val videoEnabled = configurationOptions?.videoEnabled ?: true

    if (!audioEnabled && !videoEnabled) {
      Log.d(
        CLIENT_TAG,
        "Both audioEnabled and videoEnabled is set to false, which will result in no stream at all. " +
          "Consider changing one of the options to true."
      )
    }

    val direction = RtpTransceiver.RtpTransceiverDirection.SEND_ONLY

    if (videoEnabled) {
      val videoTrackId = UUID.randomUUID().toString()

      val cameraEnumerator: CameraEnumerator =
        if (Camera2Enumerator.isSupported(appContext)) {
          Camera2Enumerator(appContext)
        } else {
          Camera1Enumerator(false)
        }

      val videoCapturer: CameraVideoCapturer? =
        videoDevice.let {
          cameraEnumerator.createCapturer(it, null)
        }

      val videoSource: VideoSource =
        peerConnectionFactory.createVideoSource(videoCapturer!!.isScreencast)
      val surfaceTextureHelper = SurfaceTextureHelper.create("CaptureThread", eglBase.eglBaseContext)
      videoCapturer.initialize(surfaceTextureHelper, appContext, videoSource.capturerObserver)
      if (configurationOptions?.videoParameters != null) {
        val videoSize =
          setVideoSize(
            cameraEnumerator,
            videoDevice!!,
            configurationOptions.videoParameters
          )
        try {
          videoCapturer.startCapture(
            videoSize!!.width,
            videoSize.height,
            configurationOptions.videoParameters.maxFps
          )
        } catch (e: Exception) {
          throw CaptureDeviceError.VideoSizeNotSupported(
            "VideoSize ${configurationOptions.videoParameters} is not supported by this device. Consider switching to another preset."
          )
        }
      } else {
        val videoSize =
          setVideoSize(
            cameraEnumerator,
            videoDevice!!,
            VideoParameters.presetHD43
          )
        try {
          videoCapturer.startCapture(
            videoSize!!.width,
            videoSize.height,
            VideoParameters.presetHD43.maxFps
          )
        } catch (e: Exception) {
          throw CaptureDeviceError.VideoSizeNotSupported(
            "VideoSize ${VideoParameters.presetHD43} is not supported by this device. Consider switching to another preset."
          )
        }
      }
      val videoTrack: VideoTrack = peerConnectionFactory.createVideoTrack(videoTrackId, videoSource)

      this.videoSource = videoSource
      this.videoCapturer = videoCapturer

      val transceiverInit = RtpTransceiver.RtpTransceiverInit(direction)
      peerConnection.addTransceiver(videoTrack, transceiverInit)

      videoTrack.setEnabled(true)
      this.videoTrack = videoTrack
    }

    if (audioEnabled) {
      val audioTrackId = UUID.randomUUID().toString()
      val audioSource = this.peerConnectionFactory.createAudioSource(MediaConstraints())
      val audioTrack = this.peerConnectionFactory.createAudioTrack(audioTrackId, audioSource)

      val audioTransceiverInit = RtpTransceiver.RtpTransceiverInit(direction)
      peerConnection.addTransceiver(audioTrack, audioTransceiverInit)
    }

    peerConnection.enforceSendOnlyDirection()
  }

  /**
   * Connects the client to the WHIP server using WebRTC Peer Connection.
   *
   * @throws SessionNetworkError.ConfigurationError if the stunServerUrl parameter
   *  of the initial configuration is incorrect, which leads to peerConnection being nil
   *  or in any other case where there has been an error in creating the peerConnection
   *
   */
  suspend fun connect() {
    val constraints = MediaConstraints()
    val sdpOffer = peerConnection.createOffer(constraints).getOrThrow()
    peerConnection.setLocalDescription(sdpOffer).getOrThrow()

    val sdp = sendSdpOffer(sdpOffer.description)

    iceCandidates.forEach { sendCandidate(it) }

    val answer =
      SessionDescription(
        SessionDescription.Type.ANSWER,
        sdp
      )
    peerConnection.setRemoteDescription(answer)
  }

  /**
   * Closes the established Peer Connection.
   *
   * @throws SessionNetworkError.ConfigurationError if the stunServerUrl parameter
   *  of the initial configuration is incorrect, which leads to peerConnection being nil
   *  or in any other case where there has been an error in creating the peerConnection
   *
   */
  public fun disconnect() {
    peerConnection.dispose()
    peerConnectionFactory.dispose()
    eglBase.release()
    videoCapturer?.stopCapture()
    videoCapturer?.dispose()
    videoSource?.dispose()
  }

  private fun PeerConnection.enforceSendOnlyDirection() {
    transceivers.forEach { transceiver ->
      if (transceiver.direction == RtpTransceiver.RtpTransceiverDirection.SEND_RECV) {
        transceiver.direction = RtpTransceiver.RtpTransceiverDirection.SEND_ONLY
      }
    }
  }

  private fun setVideoSize(
    enumerator: CameraEnumerator,
    deviceName: String,
    videoParameters: VideoParameters
  ): Size? {
    val sizes =
      enumerator
        .getSupportedFormats(deviceName)
        ?.map { Size(it.width, it.height) }
        ?: emptyList()

    val size =
      CameraEnumerationAndroid.getClosestSupportedSize(
        sizes,
        videoParameters.dimensions.width,
        videoParameters.dimensions.height
      )

    return size
  }

  companion object {
    private fun getEnumerator(context: Context): CameraEnumerator =
      if (Camera2Enumerator.isSupported(context)) {
        Camera2Enumerator(context)
      } else {
        Camera1Enumerator(true)
      }

    fun getCaptureDevices(context: Context): List<CaptureDevice> {
      val enumerator = getEnumerator(context)
      return enumerator.deviceNames.map { name ->
        CaptureDevice(
          name,
          enumerator.isFrontFacing(name),
          enumerator.isBackFacing(name)
        )
      }
    }
  }
}
