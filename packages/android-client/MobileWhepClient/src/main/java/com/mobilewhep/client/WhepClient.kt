package com.mobilewhep.client

import android.content.Context
import android.util.Log
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import org.webrtc.MediaConstraints
import org.webrtc.MediaStreamTrack
import org.webrtc.PeerConnection
import org.webrtc.RtpTransceiver
import org.webrtc.SessionDescription

data class WhepConfigurationOptions(
  val audioEnabled: Boolean? = true,
  val videoEnabled: Boolean? = true,
  val stunServerUrl: String? = null,
  val preferredVideoCodecs: List<String>,
  val preferredAudioCodecs: List<String>
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

    if (peerConnection == null) {
      setupPeerConnection()
    }

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
      val transceiver = peerConnection?.addTransceiver(MediaStreamTrack.MediaType.MEDIA_TYPE_VIDEO)
      transceiver?.direction = RtpTransceiver.RtpTransceiverDirection.RECV_ONLY

      setCodecPreferencesIfAvailable(
        transceiver,
        configurationOptions.preferredVideoCodecs,
        MediaStreamTrack.MediaType.MEDIA_TYPE_VIDEO,
        useReceiver = true
      )
    }

    if (audioEnabled) {
      val transceiver = peerConnection?.addTransceiver(MediaStreamTrack.MediaType.MEDIA_TYPE_AUDIO)
      transceiver?.direction = RtpTransceiver.RtpTransceiverDirection.RECV_ONLY

      setCodecPreferencesIfAvailable(
        transceiver,
        configurationOptions.preferredAudioCodecs,
        MediaStreamTrack.MediaType.MEDIA_TYPE_AUDIO,
        useReceiver = true
      )
    }

    val constraints = MediaConstraints()
    val sdpOffer = peerConnection!!.createOffer(constraints).getOrThrow()
    peerConnection?.setLocalDescription(sdpOffer)?.getOrThrow()

    val sdp = sendSdpOffer(sdpOffer.description)

    iceCandidates.forEach { sendCandidate(it) }

    val answer =
      SessionDescription(
        SessionDescription.Type.ANSWER,
        sdp
      )
    peerConnection?.setRemoteDescription(answer)

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
  fun disconnect() {
    peerConnection?.close()
    peerConnection?.dispose()
    peerConnection = null
    patchEndpoint = null
    iceCandidates.clear()
    videoTrack = null
    audioTrack = null
    cleanupFactory()
    cleanupEglBase()
  }

  public fun pause() {
    audioTrack?.setEnabled(false)
    this.videoTrack?.setEnabled(false)
  }

  public fun unpause() {
    audioTrack?.setEnabled(true)
    this.videoTrack?.setEnabled(true)
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

  fun removeReconnectionListeners() {
    reconnectionManager.removeListeners()
  }
}
