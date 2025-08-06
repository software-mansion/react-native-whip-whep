package com.mobilewhep.client

import android.content.Context
import android.util.Log
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import org.webrtc.AudioTrack
import org.webrtc.MediaConstraints
import org.webrtc.MediaStreamTrack
import org.webrtc.PeerConnection
import org.webrtc.RtpTransceiver
import org.webrtc.SessionDescription

data class WhepConfigurationOptions(
  val audioEnabled: Boolean? = true,
  val videoEnabled: Boolean? = true,
  val stunServerUrl: String? = null
)

class WhepClient(
  appContext: Context,
  private val configurationOptions: WhepConfigurationOptions
) : ClientBase(
    appContext,
    configurationOptions.stunServerUrl
  ) {
  private var reconnectionManager: ReconnectionManager

  init {
    val config = ReconnectConfig()
    this.reconnectionManager =
      ReconnectionManager(config) {
        CoroutineScope(Dispatchers.Default).launch {
          connectOptions?.let {
            connect(it)
          }
        }
      }
  }

  /**
   * Connects the client to the WHEP server using WebRTC Peer Connection.
   *
   * @throws SessionNetworkError.ConfigurationError if the stunServerUrl parameter
   *  of the initial configuration is incorrect, which leads to peerConnection being nil
   *  or in any other case where there has been an error in creating the peerConnection
   */
  public override suspend fun connect(connectOptions: ClientConnectOptions) {
    super.connect(connectOptions)
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

    reconnectionManager.onReconnected()
  }

  /**
   * Closes the established Peer Connection.
   *
   * @throws SessionNetworkError.ConfigurationError if the stunServerUrl parameter
   *  of the initial configuration is incorrect, which leads to peerConnection being nil
   *  or in any other case where there has been an error in creating the peerConnection
   *
   */
  override suspend fun disconnect() {
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

  fun getSupportedReceiverVideoCodecsNames(): List<String> {
    val capabilities = peerConnectionFactory.getRtpReceiverCapabilities(MediaStreamTrack.MediaType.MEDIA_TYPE_VIDEO)

    return capabilities.codecs.map { it.name }
  }

  fun getSupportedReceiverAudioCodecsNames(): List<String> {
    val capabilities = peerConnectionFactory.getRtpReceiverCapabilities(MediaStreamTrack.MediaType.MEDIA_TYPE_AUDIO)

    return capabilities.codecs.map { it.name }
  }

  fun setPreferredVideoCodecs(preferredCodecs: List<String>?) {
    if (preferredCodecs?.isEmpty() == true) {
      return
    }

    peerConnection.transceivers.forEach { transceiver ->
      if (transceiver.mediaType.equals(MediaStreamTrack.MediaType.MEDIA_TYPE_VIDEO)) {
        setCodecPreferencesIfAvailable(
          transceiver,
          preferredCodecs!!,
          MediaStreamTrack.MediaType.MEDIA_TYPE_VIDEO,
          useReceiver = true
        )
      }
    }
  }

  fun setPreferredAudioCodecs(preferredCodecs: List<String>?) {
    if (preferredCodecs?.isEmpty() == true) {
      return
    }

    peerConnection.transceivers.forEach { transceiver ->
      if (transceiver.mediaType.equals(MediaStreamTrack.MediaType.MEDIA_TYPE_AUDIO)) {
        setCodecPreferencesIfAvailable(
          transceiver,
          preferredCodecs!!,
          MediaStreamTrack.MediaType.MEDIA_TYPE_AUDIO,
          useReceiver = true
        )
      }
    }
  }

  override fun onIceConnectionChange(connectionState: PeerConnection.IceConnectionState?) {
    super.onIceConnectionChange(connectionState)

    if (connectionState == PeerConnection.IceConnectionState.DISCONNECTED) {
      reconnectionManager.onDisconnected()
    }
  }

  fun addReconnectionListener(listener: ReconnectionManagerListener) {
    reconnectionManager.addListener(listener)
  }
}
