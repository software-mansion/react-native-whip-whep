package com.mobilewhep.client

import android.content.Context
import android.util.Log
import org.webrtc.MediaConstraints
import org.webrtc.MediaStreamTrack
import org.webrtc.RtpTransceiver
import org.webrtc.SessionDescription
import org.webrtc.VideoTrack

class WhepClient(appContext: Context, serverUrl: String, connectionOptions: ConnectionOptions? = null) :
  ClientBase(
    appContext, serverUrl,
    connectionOptions
  ) {

  public suspend fun connect() {
    peerConnection.addTransceiver(MediaStreamTrack.MediaType.MEDIA_TYPE_VIDEO).direction =
      RtpTransceiver.RtpTransceiverDirection.RECV_ONLY
    peerConnection.addTransceiver(MediaStreamTrack.MediaType.MEDIA_TYPE_AUDIO).direction =
      RtpTransceiver.RtpTransceiverDirection.RECV_ONLY

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
}
