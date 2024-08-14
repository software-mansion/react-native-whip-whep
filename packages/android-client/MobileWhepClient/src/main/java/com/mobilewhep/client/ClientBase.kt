package com.mobilewhep.client

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
import org.json.JSONObject
import org.webrtc.DataChannel
import org.webrtc.DefaultVideoDecoderFactory
import org.webrtc.DefaultVideoEncoderFactory
import org.webrtc.EglBase
import org.webrtc.IceCandidate
import org.webrtc.MediaStream
import org.webrtc.PeerConnection
import org.webrtc.PeerConnectionFactory
import org.webrtc.RtpReceiver
import org.webrtc.VideoTrack
import java.io.IOException
import java.net.URI
import java.net.URL
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException
import kotlin.coroutines.suspendCoroutine

internal const val TAG = "ClientBase"

interface ClientBaseListener {
  fun onTrackAdded(track: VideoTrack)
}

open class ClientBase(
  val appContext: Context,
  private val serverUrl: String,
  private val connectionOptions: ConnectionOptions?
) : PeerConnection.Observer {
  var peerConnectionFactory: PeerConnectionFactory
  var peerConnection: PeerConnection
  val eglBase = EglBase.create()

  private var patchEndpoint: String? = null
  val iceCandidates = mutableListOf<IceCandidate>()

  private val client = OkHttpClient()

  private val coroutineScope: CoroutineScope =
    CoroutineScope(Dispatchers.Default)

  private var videoTrack: VideoTrack? = null
  private var listeners = mutableListOf<ClientBaseListener>()
  var onTrackAdded: (() -> Unit)? = null

  init {
    val iceServers =
      listOf(
        PeerConnection.IceServer
          .builder(connectionOptions?.stunServerUrl ?: "stun:stun.l.google.com:19302")
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

    peerConnectionFactory =
      PeerConnectionFactory
        .builder()
        .setVideoDecoderFactory(DefaultVideoDecoderFactory(eglBase.eglBaseContext))
        .setVideoEncoderFactory(DefaultVideoEncoderFactory(eglBase.eglBaseContext, true, true))
        .createPeerConnectionFactory()

    peerConnection = peerConnectionFactory.createPeerConnection(config, this)!!
  }

  suspend fun sendSdpOffer(sdpOffer: String) =
    suspendCoroutine { continuation ->
      val request =
        Request
          .Builder()
          .url(serverUrl)
          .post(sdpOffer.toRequestBody())
          .header("Accept", "application/sdp")
          .header("Content-Type", "application/sdp")
          .header("Authorization", "Bearer " + connectionOptions?.authToken)
          .build()

      client.newCall(request).enqueue(
        object : Callback {
          override fun onFailure(
            call: Call,
            e: IOException
          ) {
            Log.d(TAG, e.toString())
            continuation.resumeWithException(e)
            e.printStackTrace()
          }

          override fun onResponse(
            call: Call,
            response: Response
          ) {
            response.use {
              patchEndpoint = response.headers["location"]

              if (patchEndpoint == null) {
                val exception =
                  AttributeNotFoundError.LocationNotFound(
                    "Location attribute not found. Check if the SDP answer contains location parameter."
                  )
                continuation.resumeWithException(exception)
                return
              }

              if (response.body == null) {
                val exception =
                  AttributeNotFoundError.ResponseNotFound("Response to SDP offer not found. Check if the network request was successful.")
                continuation.resumeWithException(exception)
                return
              }

              continuation.resume(response.body!!.string())
            }
          }
        }
      )
    }

  suspend fun sendCandidate(candidate: IceCandidate) =
    suspendCoroutine { continuation ->
      if (patchEndpoint == null) {
        continuation.resumeWithException(
          AttributeNotFoundError.PatchEndpointNotFound("Patch endpoint not found. Make sure the SDP answer is correct.")
        )
        return@suspendCoroutine
      }

      val splitSdp = candidate.sdp.split(" ")
      val ufrag = splitSdp[splitSdp.indexOf("ufrag") + 1]

      if (ufrag == null) {
        continuation.resumeWithException(AttributeNotFoundError.UFragNotFound("ufrag not found. Make sure the SDP answer is correct."))
        return@suspendCoroutine
      }

      val jsonObject = JSONObject()

      jsonObject.put("candidate", candidate.sdp)
      jsonObject.put("sdpMLineIndex", candidate.sdpMLineIndex)
      jsonObject.put("sdpMid", candidate.sdpMid)
      // TODO: is ufrag necessary or is it just elixir webrtc thing?
      jsonObject.put("usernameFragment", ufrag)

      val serverUrl = URL(serverUrl)
      val requestURL =
        URI(serverUrl.protocol, null, serverUrl.host, serverUrl.port, patchEndpoint, null, null)

      val request =
        Request
          .Builder()
          .url(requestURL.toURL())
          .patch(jsonObject.toString().toRequestBody())
          .header("Content-Type", "application/trickle-ice-sdpfrag")
          .build()

      client.newCall(request).enqueue(
        object : Callback {
          override fun onFailure(
            call: Call,
            e: IOException
          ) {
            continuation.resumeWithException(e)
            e.printStackTrace()
          }

          override fun onResponse(
            call: Call,
            response: Response
          ) {
            response.use {
              if (!it.isSuccessful) {
                continuation.resumeWithException(
                  SessionNetworkError.CandidateSendingError("Candidate sending error - response was not successful.")
                )
                return
              }
              continuation.resume(Unit)
            }
          }
        }
      )
    }

  override fun onSignalingChange(p0: PeerConnection.SignalingState?) {
    Log.d(TAG, "RTC signaling state changed:: ${p0?.name}")
  }

  override fun onIceConnectionChange(p0: PeerConnection.IceConnectionState?) {
    when (p0) {
      PeerConnection.IceConnectionState.NEW ->
        Log.d(
          TAG,
          "The ICE agent is gathering addresses or is waiting to be given remote candidates through calls"
        )

      PeerConnection.IceConnectionState.CHECKING ->
        Log.d(
          TAG,
          "ICE is checking paths, this might take a moment."
        )

      PeerConnection.IceConnectionState.CONNECTED ->
        Log.d(
          TAG,
          "ICE has found a viable connection."
        )

      PeerConnection.IceConnectionState.COMPLETED ->
        Log.d(
          TAG,
          "The ICE agent has finished gathering candidates, has checked all pairs against one another, and has found a connection for all components."
        )

      PeerConnection.IceConnectionState.FAILED ->
        Log.d(
          TAG,
          "No viable ICE paths found, consider a retry or using TURN."
        )

      PeerConnection.IceConnectionState.DISCONNECTED ->
        Log.d(
          TAG,
          "ICE connection was disconnected, attempting to reconnect or refresh."
        )

      PeerConnection.IceConnectionState.CLOSED ->
        Log.d(
          TAG,
          "The ICE agent for this RTCPeerConnection has shut down and is no longer handling requests."
        )

      null -> Log.d(TAG, "The Peer Connection state is null.")
    }
  }

  override fun onIceConnectionReceivingChange(p0: Boolean) {
    Log.d(TAG, "onIceConnectionReceivingChange: $p0")
  }

  override fun onIceGatheringChange(p0: PeerConnection.IceGatheringState?) {
    Log.d(TAG, "RTC ICE gathering state changed: ${p0?.name}")
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
    Log.d(TAG, "Removed candidate from candidates list.")
  }

  override fun onAddStream(p0: MediaStream?) {
    Log.d(TAG, "RTC media stream added: ${p0?.id}")
  }

  override fun onRemoveStream(p0: MediaStream?) {
    Log.d(TAG, "RTC media stream removed: ${p0?.id}")
  }

  override fun onDataChannel(p0: DataChannel?) {
    Log.d(TAG, "RTC data channel opened: ${p0?.id()}")
  }

  override fun onRenegotiationNeeded() {
    Log.d(TAG, "Peer connection negotiation needed.")
  }

  override fun onConnectionChange(newState: PeerConnection.PeerConnectionState?) {
    when (newState) {
      PeerConnection.PeerConnectionState.NEW -> Log.d(TAG, "New connection")
      PeerConnection.PeerConnectionState.CONNECTING -> Log.d(TAG, "Connecting")
      PeerConnection.PeerConnectionState.CONNECTED -> Log.d(TAG, "Connection is fully connected")
      PeerConnection.PeerConnectionState.DISCONNECTED ->
        Log.d(
          TAG,
          "One or more transports has disconnected unexpectedly"
        )

      PeerConnection.PeerConnectionState.FAILED ->
        Log.d(
          TAG,
          "One or more transports has encountered an error"
        )

      PeerConnection.PeerConnectionState.CLOSED -> Log.d(TAG, "Connection has been closed")
      null -> Log.d(TAG, "Connection is null")
    }
  }

  override fun onAddTrack(
    receiver: RtpReceiver?,
    mediaStreams: Array<out MediaStream>?
  ) {
    coroutineScope.launch(Dispatchers.Main) {
      val videoTrack = receiver?.track() as? VideoTrack?
      this@ClientBase.videoTrack = videoTrack
      listeners.forEach { listener -> videoTrack?.let { listener.onTrackAdded(it) } }
    }
    onTrackAdded?.let { it() }
  }

  fun addTrackListener(listener: ClientBaseListener) {
    listeners.add(listener)
    videoTrack?.let { listener.onTrackAdded(it) }
  }
}
