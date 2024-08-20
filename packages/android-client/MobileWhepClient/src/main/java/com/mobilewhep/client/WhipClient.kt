package com.mobilewhep.client

import android.content.Context
import android.util.Log
import org.webrtc.CameraVideoCapturer
import org.webrtc.MediaConstraints
import org.webrtc.PeerConnection
import org.webrtc.RtpTransceiver
import org.webrtc.SessionDescription
import org.webrtc.SurfaceTextureHelper
import org.webrtc.VideoCapturer
import org.webrtc.VideoSource
import org.webrtc.VideoTrack
import java.util.UUID

class WhipClient(
  appContext: Context,
  serverUrl: String,
  configurationOptions: ConfigurationOptions? = null,
  private var videoDevice: VideoDevice? = null
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
   *
   */
  private fun setUpVideoAndAudioDevices() {
    if (videoDevice == null) {
      Log.d(TAG, "Video device not found. Check if it can be accessed and passed to the constructor.")
      throw CaptureDeviceError.VideoDeviceNotAvailable("Video device not found. Check if it can be accessed and passed to the constructor.")
    }
    val videoTrackId = UUID.randomUUID().toString()

    val deviceName = videoDevice!!.deviceName

    val videoCapturer: CameraVideoCapturer? =
      deviceName.let {
        videoDevice!!.cameraEnumerator!!.createCapturer(it, null)
      }

    val videoSource: VideoSource =
      peerConnectionFactory.createVideoSource(videoCapturer!!.isScreencast)
    val surfaceTextureHelper = SurfaceTextureHelper.create("CaptureThread", eglBase.eglBaseContext)
    videoCapturer?.initialize(surfaceTextureHelper, appContext, videoSource.capturerObserver)
    Log.d(TAG, "Starting video capture")
    videoCapturer?.startCapture(1024, 720, 30)
    Log.d(TAG, "Video capture started")
    val videoTrack: VideoTrack = peerConnectionFactory.createVideoTrack(videoTrackId, videoSource)

    this.videoSource = videoSource
    this.videoCapturer = videoCapturer

    val audioTrackId = UUID.randomUUID().toString()
    val audioSource = this.peerConnectionFactory.createAudioSource(MediaConstraints())
    val audioTrack = this.peerConnectionFactory.createAudioTrack(audioTrackId, audioSource)

    val direction = RtpTransceiver.RtpTransceiverDirection.SEND_ONLY
    val transceiverInit = RtpTransceiver.RtpTransceiverInit(direction)
    peerConnection.addTransceiver(videoTrack, transceiverInit)

    val audioTransceiverInit = RtpTransceiver.RtpTransceiverInit(direction)
    peerConnection.addTransceiver(audioTrack, audioTransceiverInit)

    peerConnection.enforceSendOnlyDirection()
    videoTrack.setEnabled(true)
    this.videoTrack = videoTrack
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
  }

  fun PeerConnection.enforceSendOnlyDirection() {
    transceivers.forEach { transceiver ->
      if (transceiver.direction == RtpTransceiver.RtpTransceiverDirection.SEND_RECV) {
        transceiver.direction = RtpTransceiver.RtpTransceiverDirection.SEND_ONLY
      }
    }
  }
}
