package com.mobilewhep.client

import android.content.Context
import android.util.Log
import org.webrtc.AudioTrack
import org.webrtc.MediaConstraints
import org.webrtc.MediaStreamTrack
import org.webrtc.RtpTransceiver
import org.webrtc.SessionDescription

class WhepClient(
  appContext: Context,
  serverUrl: String,
  val configurationOptions: ConfigurationOptions? = null
) : ClientBase(
    appContext,
    serverUrl,
    configurationOptions
  ) {
  /**
   * Connects the client to the WHEP server using WebRTC Peer Connection.
   *
   * @throws SessionNetworkError.ConfigurationError if the stunServerUrl parameter
   *  of the initial configuration is incorrect, which leads to peerConnection being nil
   *  or in any other case where there has been an error in creating the peerConnection
   */
  public suspend fun connect() {
    var audioEnabled = configurationOptions?.audioEnabled ?: true
    var videoEnabled = configurationOptions?.videoEnabled ?: true

    if (!audioEnabled && !videoEnabled) {
      Log.d(
        CLIENT_TAG,
        "Both audioEnabled and videoEnabled is set to false, which will result in no stream at all. " +
          "Consider changing one of the options to true."
      )
    }

    if (videoEnabled) {
      peerConnection.addTransceiver(MediaStreamTrack.MediaType.MEDIA_TYPE_VIDEO).direction =
        RtpTransceiver.RtpTransceiverDirection.RECV_ONLY
    }

    if (audioEnabled) {
      peerConnection.addTransceiver(MediaStreamTrack.MediaType.MEDIA_TYPE_AUDIO).direction =
        RtpTransceiver.RtpTransceiverDirection.RECV_ONLY
    }

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

  private fun getAudioTrack(): AudioTrack? {
    peerConnection?.transceivers?.forEach { transceiver ->
      val track = transceiver.receiver.track()
      if (track is AudioTrack) {
        return track
      }
    }
    return null
  }

  public fun pause() {
    var track = getAudioTrack()
    track?.setEnabled(false)
    this.videoTrack?.setEnabled(false)
  }

  public fun unpause() {
    var track = getAudioTrack()
    track?.setEnabled(true)
    this.videoTrack?.setEnabled(true)
  }
}
