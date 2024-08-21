package com.mobilewhep.client

import android.content.Context
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
   * @throws ConfigurationOptionsError.WrongCaptureDeviceConfiguration if both audioOnly
   * and `videoOnly is set to true.
   */
  public suspend fun connect() {
    if (configurationOptions != null && configurationOptions.audioOnly == true && configurationOptions.videoOnly == true) {
      throw ConfigurationOptionsError.WrongCaptureDeviceConfiguration(
        "Wrong initial configuration. Either audioOnly or videoOnly should be set to false."
      )
    }

    if (configurationOptions != null && !configurationOptions.audioOnly!!) {
      peerConnection.addTransceiver(MediaStreamTrack.MediaType.MEDIA_TYPE_VIDEO).direction =
        RtpTransceiver.RtpTransceiverDirection.RECV_ONLY
    }

    if (configurationOptions != null && !configurationOptions.videoOnly!!) {
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
}
