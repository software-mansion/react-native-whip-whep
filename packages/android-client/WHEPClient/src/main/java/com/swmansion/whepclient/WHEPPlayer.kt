package com.swmansion.whepclient

import android.content.Context
import android.util.Log
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import okhttp3.Call
import okhttp3.Callback
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import okhttp3.Response
import org.json.JSONException
import org.json.JSONObject
import org.webrtc.DataChannel
import org.webrtc.DefaultVideoDecoderFactory
import org.webrtc.EglBase
import org.webrtc.IceCandidate
import org.webrtc.MediaConstraints
import org.webrtc.MediaStream
import org.webrtc.MediaStreamTrack
import org.webrtc.PeerConnection
import org.webrtc.PeerConnectionFactory
import org.webrtc.RtpReceiver
import org.webrtc.RtpTransceiver
import org.webrtc.SessionDescription
import org.webrtc.VideoTrack
import java.io.IOException
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException
import kotlin.coroutines.suspendCoroutine

internal interface WHEPPlayerListener {
  fun onTrackAdded(track: VideoTrack)
}

internal const val TAG = "WHEPClient"

class WHEPPlayer(appContext: Context, private val connectionOptions: ConnectionOptions) :
  PeerConnection.Observer {
  private val peerConnectionFactory: PeerConnectionFactory
  private val peerConnection: PeerConnection
  internal val eglBase = EglBase.create()

  private var patchEndpoint: String? = null
  private val iceCandidates = mutableListOf<IceCandidate>()

  private val client = OkHttpClient()

  private var listeners = mutableListOf<WHEPPlayerListener>()

  private val coroutineScope: CoroutineScope =
    CoroutineScope(Dispatchers.Default)

  private var videoTrack: VideoTrack? = null

  var onTrackAdded: (() -> Unit)? = null

  init {
    val iceServers = listOf(
      PeerConnection.IceServer
        .builder("stun:stun.l.google.com:19302")
        .createIceServer()
    )

    val config = PeerConnection.RTCConfiguration(iceServers)

    config.sdpSemantics = PeerConnection.SdpSemantics.UNIFIED_PLAN
    config.continualGatheringPolicy = PeerConnection.ContinualGatheringPolicy.GATHER_CONTINUALLY
    config.candidateNetworkPolicy = PeerConnection.CandidateNetworkPolicy.ALL
    config.tcpCandidatePolicy = PeerConnection.TcpCandidatePolicy.DISABLED


    PeerConnectionFactory.initialize(
      PeerConnectionFactory.InitializationOptions.builder(appContext).createInitializationOptions()
    )

    peerConnectionFactory = PeerConnectionFactory
      .builder()
      .setVideoDecoderFactory(DefaultVideoDecoderFactory(eglBase.eglBaseContext))
      .createPeerConnectionFactory()

    peerConnection = peerConnectionFactory.createPeerConnection(config, this)!!
  }

  private suspend fun sendSdpOffer(sdpOffer: String) = suspendCoroutine { continuation ->
    val request = Request.Builder()
      .url(connectionOptions.serverUrl + connectionOptions.whepEndpoint)
      .post(sdpOffer.toRequestBody())
      .header("Accept", "application/sdp")
      .header("Content-Type", "application/sdp")
      .build()

    client.newCall(request).enqueue(object : Callback {
      override fun onFailure(call: Call, e: IOException) {
        continuation.resumeWithException(e)
        e.printStackTrace()
      }

      override fun onResponse(call: Call, response: Response) {
        response.use {
          patchEndpoint = response.headers["location"]
          continuation.resume(response.body!!.string())
        }
      }
    })
  }

  private suspend fun sendCandidate(candidate: IceCandidate) = suspendCoroutine { continuation ->
    if (patchEndpoint == null) return@suspendCoroutine

    val splitSdp = candidate.sdp.split(" ")
    val ufrag = splitSdp[splitSdp.indexOf("ufrag") + 1]

    val jsonObject = JSONObject()
    try {
      jsonObject.put("candidate", candidate.sdp)
      jsonObject.put("sdpMLineIndex", candidate.sdpMLineIndex)
      jsonObject.put("sdpMid", candidate.sdpMid)
      // TODO: is ufrag necessary or is it just elixir webrtc thing?
      jsonObject.put("usernameFragment", ufrag)
    } catch (e: JSONException) {
      e.printStackTrace()
    }

    val request = Request.Builder()
      .url(connectionOptions.serverUrl + patchEndpoint!!)
      .patch(jsonObject.toString().toRequestBody())
      .header("Content-Type", "application/trickle-ice-sdpfrag")
      .build()

    client.newCall(request).enqueue(object : Callback {
      override fun onFailure(call: Call, e: IOException) {
        continuation.resumeWithException(e)
        e.printStackTrace()
      }

      override fun onResponse(call: Call, response: Response) {
        response.use {
          continuation.resume(Unit)
        }
      }
    })
  }

  suspend fun connect() {
    peerConnection.addTransceiver(MediaStreamTrack.MediaType.MEDIA_TYPE_VIDEO).direction =
      RtpTransceiver.RtpTransceiverDirection.RECV_ONLY
    peerConnection.addTransceiver(MediaStreamTrack.MediaType.MEDIA_TYPE_AUDIO).direction =
      RtpTransceiver.RtpTransceiverDirection.RECV_ONLY

    val constraints = MediaConstraints()
    val sdpOffer = peerConnection.createOffer(constraints).getOrThrow()
    peerConnection.setLocalDescription(sdpOffer).getOrThrow()

    Log.d(TAG, sdpOffer.description)

    val sdp = sendSdpOffer(sdpOffer.description)

    iceCandidates.forEach { sendCandidate(it) }

    val answer = SessionDescription(
      SessionDescription.Type.ANSWER,
      sdp
    )
    peerConnection.setRemoteDescription(answer)
  }

  fun release() {
    peerConnection.dispose()
    peerConnectionFactory.dispose()
    eglBase.release()
  }

  override fun onSignalingChange(p0: PeerConnection.SignalingState?) {
    Log.d(TAG, "onSignalingChange: $p0")
  }

  override fun onIceConnectionChange(p0: PeerConnection.IceConnectionState?) {
    Log.d(TAG, "onIceConnectionChange: $p0")
  }

  override fun onIceConnectionReceivingChange(p0: Boolean) {
    Log.d(TAG, "onIceConnectionReceivingChange: $p0")
  }

  override fun onIceGatheringChange(p0: PeerConnection.IceGatheringState?) {
    Log.d(TAG, "onIceGatheringChange: $p0")
  }

  override fun onIceCandidate(candidate: IceCandidate) {
    if (patchEndpoint == null) {
      iceCandidates.add(candidate)
    } else {
      coroutineScope.launch {
        sendCandidate(candidate)
      }
    }
  }

  override fun onIceCandidatesRemoved(p0: Array<out IceCandidate>?) {

  }

  override fun onAddStream(p0: MediaStream?) {
    Log.d(TAG, "onAddStream: $p0")
  }

  override fun onRemoveStream(p0: MediaStream?) {
    Log.d(TAG, "onRemoveStream: $p0")
  }

  override fun onDataChannel(p0: DataChannel?) {
    Log.d(TAG, "onDataChannel: $p0")
  }

  override fun onRenegotiationNeeded() {
    Log.d(TAG, "onRenegotiationNeeded")
  }

  override fun onAddTrack(receiver: RtpReceiver?, mediaStreams: Array<out MediaStream>?) {
    coroutineScope.launch(Dispatchers.Main) {
      val videoTrack = receiver?.track() as? VideoTrack?
      this@WHEPPlayer.videoTrack = videoTrack
      listeners.forEach { listener -> videoTrack?.let { listener.onTrackAdded(it) } }
    }
    onTrackAdded?.let { it() }
  }

  internal fun addTrackListener(listener: WHEPPlayerListener) {
    listeners.add(listener)
    videoTrack?.let { listener.onTrackAdded(it) }
  }
}
