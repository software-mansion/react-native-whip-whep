package com.mobilewhep.client

import android.content.Context
import android.media.AudioAttributes
import android.util.Log
import com.mobilewhep.client.utils.PeerConnectionFactoryHelper
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
import org.webrtc.AudioTrack
import org.webrtc.DataChannel
import org.webrtc.IceCandidate
import org.webrtc.MediaStream
import org.webrtc.MediaStreamTrack
import org.webrtc.PeerConnection
import org.webrtc.RtpCapabilities
import org.webrtc.RtpReceiver
import org.webrtc.RtpTransceiver
import org.webrtc.VideoTrack
import org.webrtc.audio.AudioDeviceModule
import java.io.IOException
import java.net.ConnectException
import java.net.URI
import java.net.URL
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException
import kotlin.coroutines.suspendCoroutine

internal const val CLIENT_TAG = "WHIP/WHEP Client"

interface ClientBaseListener {
  fun onTrackAdded(track: VideoTrack)
}

open class ClientBase(
  val appContext: Context,
  val stunServerUrl: String?
) : PeerConnection.Observer {

  protected val peerConnectionFactory = PeerConnectionFactoryHelper.getFactory(appContext)

  protected var peerConnection: PeerConnection? = null
  var connectOptions: ClientConnectOptions? = null

  val peerConnectionState: PeerConnection.PeerConnectionState?
    get() = peerConnection?.connectionState()


  protected var patchEndpoint: String? = null
  protected val iceCandidates = mutableListOf<IceCandidate>()

  protected val client = OkHttpClient()
  private val audioAttributes: AudioAttributes =
    AudioAttributes
      .Builder()
      .setUsage(AudioAttributes.USAGE_MEDIA)
      .setContentType(AudioAttributes.CONTENT_TYPE_MOVIE)
      .build()
  private val audioDeviceModule: AudioDeviceModule = createAudioDeviceModule(appContext, audioAttributes)

  private val coroutineScope: CoroutineScope =
    CoroutineScope(Dispatchers.Default)

  open var videoTrack: VideoTrack? = null
  open var audioTrack: AudioTrack? = null
  private var listeners = mutableListOf<ClientBaseListener>()
  var onTrackAdded: (() -> Unit)? = null
  var onConnectionStateChanged: ((PeerConnection.PeerConnectionState) -> Unit)? = null

  open fun setupPeerConnection() {
    val iceServers =
      listOf(
        PeerConnection.IceServer
          .builder(stunServerUrl ?: "stun:stun.l.google.com:19302")
          .createIceServer()
      )

    val config = PeerConnection.RTCConfiguration(iceServers)

    config.sdpSemantics = PeerConnection.SdpSemantics.UNIFIED_PLAN
    config.continualGatheringPolicy = PeerConnection.ContinualGatheringPolicy.GATHER_CONTINUALLY
    config.candidateNetworkPolicy = PeerConnection.CandidateNetworkPolicy.ALL
    config.tcpCandidatePolicy = PeerConnection.TcpCandidatePolicy.DISABLED

    try {
      peerConnection = peerConnectionFactory.createPeerConnection(config, this)!!

    } catch (e: NullPointerException) {
      throw SessionNetworkError.ConfigurationError("Failed to establish RTCPeerConnection. Check initial configuration")
    }
  }

  open suspend fun connect(connectOptions: ClientConnectOptions) {
    this.connectOptions = connectOptions
  }

  /**
   * Sends an SDP offer to the WHIP/WHEP server.
   *
   * @param sdpOffer - The offer to send to the server.
   *
   * @throws AttributeNotFoundError.ResponseNotFound if there is no response to the offer
   * @throws AttributeNotFoundError.LocationNotFound if the response does not contain the location parameter
   * @throws SessionNetworkError.ConnectionError if the  connection could not be established or the response code is incorrect,
   * for example due to server being down, wrong server URL or token.
   *
   * @return A SDP response.
   */
  suspend fun sendSdpOffer(sdpOffer: String) =
    suspendCoroutine { continuation ->
      if (connectOptions == null) {
        continuation.resumeWithException(
          SessionNetworkError.ConnectionError(
            "Cannot send the SDP Offer. Connection not setup. Remember to call connect first."
          )
        )
        return@suspendCoroutine
      }

      var requestBuilder: Request.Builder =
        Request
          .Builder()
          .url(connectOptions!!.serverUrl)
          .post(sdpOffer.toRequestBody())
          .header("Accept", "application/sdp")
          .header("Content-Type", "application/sdp")
      if (connectOptions!!.authToken != null) {
        requestBuilder =
          requestBuilder.header("Authorization", "Bearer " + connectOptions!!.authToken)
      }

      val request = requestBuilder.build()

      client.newCall(request).enqueue(
        object : Callback {
          override fun onFailure(
            call: Call,
            e: IOException
          ) {
            if (e is ConnectException) {
              continuation.resumeWithException(
                SessionNetworkError.ConnectionError(
                  "Network error. Check if the server is up and running and the token and the server url is correct."
                )
              )
            } else {
              Log.e(CLIENT_TAG, e.toString())
              continuation.resumeWithException(e)
              e.printStackTrace()
            }
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

  /**
   * Sends an ICE candidate to WHIP/WHEP server in order to provide a streaming device.
   *
   * @param candidate - Represents a single ICE candidate.
   *
   * @throws AttributeNotFoundError.PatchEndpointNotFound if the patch endpoint has not been properly set up
   * @throws AttributeNotFoundError.UFragNotFound if the SDP of the candidate does not contain the ufrag
   * @throws SessionNetworkError.CandidateSendingError` if the candidate could not be sent
   */
  suspend fun sendCandidate(candidate: IceCandidate) =
    suspendCoroutine { continuation ->
      if (connectOptions == null) {
        continuation.resumeWithException(
          SessionNetworkError.ConnectionError(
            "Cannot send the send ICE Candidate. Connection not setup. Remember to call connect first."
          )
        )
        return@suspendCoroutine
      }

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

      val serverUrl = URL(connectOptions!!.serverUrl)
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
    Log.d(CLIENT_TAG, "RTC signaling state changed:: ${p0?.name}")
  }

  protected fun getMatchedCodecs(
    preferredCodecs: List<String>,
    mediaType: MediaStreamTrack.MediaType,
    useReceiver: Boolean = false
  ): List<RtpCapabilities.CodecCapability> {
    if (preferredCodecs.isEmpty()) {
      return emptyList()
    }

    val availableCodecs =
      if (useReceiver) {
        peerConnectionFactory.getRtpReceiverCapabilities(mediaType).codecs
      } else {
        peerConnectionFactory.getRtpSenderCapabilities(mediaType).codecs
      }
    return preferredCodecs.mapNotNull { preferredCodec ->
      availableCodecs.firstOrNull { it.name.equals(preferredCodec, ignoreCase = true) }
    }
  }

  protected fun setCodecPreferencesIfAvailable(
    transceiver: RtpTransceiver?,
    preferredCodecs: List<String>,
    mediaType: MediaStreamTrack.MediaType,
    useReceiver: Boolean = false
  ) {
    val matchedCodecs = getMatchedCodecs(preferredCodecs, mediaType, useReceiver)
    if (matchedCodecs.isNotEmpty()) {
      transceiver?.setCodecPreferences(matchedCodecs)
    }
  }

  /**
   Reacts to changes in the ICE Connection state and logs a message depending on the current state.
   */
  override fun onIceConnectionChange(p0: PeerConnection.IceConnectionState?) {
    when (p0) {
      PeerConnection.IceConnectionState.NEW ->
        Log.d(
          CLIENT_TAG,
          "The ICE agent is gathering addresses or is waiting to be given remote candidates through calls"
        )

      PeerConnection.IceConnectionState.CHECKING ->
        Log.d(
          CLIENT_TAG,
          "ICE is checking paths, this might take a moment."
        )

      PeerConnection.IceConnectionState.CONNECTED ->
        Log.d(
          CLIENT_TAG,
          "ICE has found a viable connection."
        )

      PeerConnection.IceConnectionState.COMPLETED ->
        Log.d(
          CLIENT_TAG,
          "The ICE agent has finished gathering candidates, has checked all pairs against one another, " +
            "and has found a connection for all components."
        )

      PeerConnection.IceConnectionState.FAILED ->
        Log.d(
          CLIENT_TAG,
          "No viable ICE paths found, consider a retry or using TURN."
        )

      PeerConnection.IceConnectionState.DISCONNECTED ->
        Log.d(
          CLIENT_TAG,
          "ICE connection was disconnected, attempting to reconnect or refresh."
        )

      PeerConnection.IceConnectionState.CLOSED ->
        Log.d(
          CLIENT_TAG,
          "The ICE agent for this RTCPeerConnection has shut down and is no longer handling requests."
        )

      null -> Log.d(CLIENT_TAG, "The Peer Connection state is null.")
    }
  }

  override fun onIceConnectionReceivingChange(p0: Boolean) {
    Log.d(CLIENT_TAG, "onIceConnectionReceivingChange: $p0")
  }

  override fun onIceGatheringChange(p0: PeerConnection.IceGatheringState?) {
    Log.d(CLIENT_TAG, "RTC ICE gathering state changed: ${p0?.name}")
  }

  /**
   Reacts to new candidate found and sends it to the WHIP/WHEP server.
   */
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
    Log.d(CLIENT_TAG, "Removed candidate from candidates list.")
  }

  override fun onAddStream(p0: MediaStream?) {
    Log.d(CLIENT_TAG, "RTC media stream added: ${p0?.id}")
  }

  override fun onRemoveStream(p0: MediaStream?) {
    Log.d(CLIENT_TAG, "RTC media stream removed: ${p0?.id}")
  }

  override fun onDataChannel(p0: DataChannel?) {
    Log.d(CLIENT_TAG, "RTC data channel opened: ${p0?.id()}")
  }

  override fun onRenegotiationNeeded() {
    Log.d(CLIENT_TAG, "Peer connection negotiation needed.")
  }

  /**
   Reacts to changes in the Peer Connection state and logs a message depending on the current state
   */
  override fun onConnectionChange(newState: PeerConnection.PeerConnectionState) {
    onConnectionStateChanged?.invoke(newState)
    when (newState) {
      PeerConnection.PeerConnectionState.NEW -> Log.d(CLIENT_TAG, "New connection")
      PeerConnection.PeerConnectionState.CONNECTING -> Log.d(CLIENT_TAG, "Connecting")
      PeerConnection.PeerConnectionState.CONNECTED -> Log.d(CLIENT_TAG, "Connection is fully connected")
      PeerConnection.PeerConnectionState.DISCONNECTED ->
        Log.d(
          CLIENT_TAG,
          "One or more transports has disconnected unexpectedly"
        )

      PeerConnection.PeerConnectionState.FAILED ->
        Log.d(
          CLIENT_TAG,
          "One or more transports has encountered an error"
        )

      PeerConnection.PeerConnectionState.CLOSED -> Log.d(CLIENT_TAG, "Connection has been closed")
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
