package com.mobilewhep.client

import android.content.Context
import android.util.Log
import org.webrtc.Camera1Enumerator
import org.webrtc.Camera2Enumerator
import org.webrtc.CameraEnumerator
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

class WhipClient(appContext: Context, serverUrl: String, connectionOptions: ConnectionOptions? = null) :
  ClientBase(
    appContext, serverUrl,
    connectionOptions
  ) {
  var videoTrack: VideoTrack? = null
  private var videoCapturer: VideoCapturer? = null
  private var videoSource: VideoSource? = null

  init {
      setUpVideoAndAudioDevices()
  }

  private fun setUpVideoAndAudioDevices() {
    val videoTrackId = UUID.randomUUID().toString()
    val cameraEnumerator: CameraEnumerator = if (Camera2Enumerator.isSupported(appContext)) {
      Camera2Enumerator(appContext)
    } else {
      Camera1Enumerator(false)
    }

    val deviceName = cameraEnumerator.deviceNames.find {
      true
    }

    val videoCapturer: CameraVideoCapturer? = deviceName?.let {
      cameraEnumerator.createCapturer(it, null)
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

  suspend fun connect() {
    val constraints = MediaConstraints()
    val sdpOffer = peerConnection.createOffer(constraints).getOrThrow()
    peerConnection.setLocalDescription(sdpOffer).getOrThrow()

    val sdp = sendSdpOffer(sdpOffer.description)

    iceCandidates.forEach { sendCandidate(it) }

    val answer = SessionDescription(
      SessionDescription.Type.ANSWER,
      sdp
    )
    peerConnection.setRemoteDescription(answer)
  }

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
