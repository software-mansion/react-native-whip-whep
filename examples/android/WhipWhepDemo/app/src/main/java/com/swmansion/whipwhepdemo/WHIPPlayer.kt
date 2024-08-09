package com.swmansion.whipwhepdemo

import android.content.Context
import android.content.pm.PackageManager
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
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
import org.webrtc.Camera1Enumerator
import org.webrtc.Camera2Enumerator
import org.webrtc.CameraEnumerator
import org.webrtc.CameraVideoCapturer
import org.webrtc.DataChannel
import org.webrtc.DefaultVideoDecoderFactory
import org.webrtc.DefaultVideoEncoderFactory
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
import org.webrtc.SurfaceTextureHelper
import org.webrtc.VideoCapturer
import org.webrtc.VideoSource
import org.webrtc.VideoTrack
import java.io.IOException
import java.util.UUID
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException
import kotlin.coroutines.suspendCoroutine

internal interface WHIPPlayerListener {
  fun onTrackAdded(track: VideoTrack)
}

internal const val TAG2 = "WHIPClient"

class WHIPPlayer(private val appContext: Context, private val connectionOptions: ConnectionOptions) :
  PeerConnection.Observer {
  private val peerConnectionFactory: PeerConnectionFactory
  private val peerConnection: PeerConnection
  internal val eglBase = EglBase.create()

  private var patchEndpoint: String? = null
  private val iceCandidates = mutableListOf<IceCandidate>()

  private val client = OkHttpClient()

  private var listeners = mutableListOf<WHIPPlayerListener>()

  private val coroutineScope: CoroutineScope =
    CoroutineScope(Dispatchers.Default)

  private var videoTrack: VideoTrack? = null
  private var videoCapturer: VideoCapturer? = null
  private var videoSource: VideoSource? = null

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
      .setVideoEncoderFactory(DefaultVideoEncoderFactory(eglBase.eglBaseContext, true, true))
      .createPeerConnectionFactory()

    peerConnection = peerConnectionFactory.createPeerConnection(config, this)!!
    setUpVideoAndAudioDevices()
  }

  private suspend fun sendSdpOffer(sdpOffer: String) = suspendCoroutine { continuation ->
    val request = Request.Builder()
      .url(connectionOptions.serverUrl + connectionOptions.whepEndpoint)
      .post(sdpOffer.toRequestBody())
      .header("Accept", "application/sdp")
      .header("Content-Type", "application/sdp")
      .header("Authorization", "Bearer " + connectionOptions?.authToken)
      .build()

    Log.d(TAG2, request.headers.toString())
    Log.d(TAG2, request.body.toString())

    client.newCall(request).enqueue(object : Callback {
      override fun onFailure(call: Call, e: IOException) {
        Log.d(TAG2, e.toString())
        continuation.resumeWithException(e)
        e.printStackTrace()
      }

      override fun onResponse(call: Call, response: Response) {
        response.use {
          Log.d(TAG2, response.headers.toString())
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

    Log.d(TAG2, ufrag)

    val jsonObject = JSONObject()

    jsonObject.put("candidate", candidate.sdp)
    jsonObject.put("sdpMLineIndex", candidate.sdpMLineIndex)
    jsonObject.put("sdpMid", candidate.sdpMid)
    // TODO: is ufrag necessary or is it just elixir webrtc thing?
    jsonObject.put("usernameFragment", ufrag)

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
    val constraints = MediaConstraints()
    val sdpOffer = peerConnection.createOffer(constraints).getOrThrow()
    peerConnection.setLocalDescription(sdpOffer).getOrThrow()

    Log.d(TAG2, sdpOffer.description)

    val sdp = sendSdpOffer(sdpOffer.description)

    iceCandidates.forEach { sendCandidate(it) }

    val answer = SessionDescription(
      SessionDescription.Type.ANSWER,
      sdp
    )
    peerConnection.setRemoteDescription(answer)
    Log.d(TAG2, answer.toString())
  }

  fun release() {
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

  private fun setUpVideoAndAudioDevices() {
    val videoTrackId = UUID.randomUUID().toString()
    val cameraEnumerator: CameraEnumerator = if (Camera2Enumerator.isSupported(appContext)) {
      Camera2Enumerator(appContext)
    } else {
      Camera1Enumerator(false)
    }

    val deviceName = cameraEnumerator.deviceNames.find {
      cameraEnumerator.isFrontFacing(it)
    }

    val videoCapturer: CameraVideoCapturer? = deviceName?.let {
      cameraEnumerator.createCapturer(it, null)
    }

    val videoSource: VideoSource = peerConnectionFactory.createVideoSource(videoCapturer!!.isScreencast)
    val surfaceTextureHelper = SurfaceTextureHelper.create("CaptureThread", eglBase.eglBaseContext)
    videoCapturer?.initialize(surfaceTextureHelper, appContext, videoSource.capturerObserver)
    videoCapturer?.startCapture(1024, 720, 30)
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

    Log.d(TAG2, videoTrack.id())
  }

  override fun onSignalingChange(p0: PeerConnection.SignalingState?) {
    Log.d(TAG2, "onSignalingChange: $p0")
  }

  override fun onIceConnectionChange(p0: PeerConnection.IceConnectionState?) {
    Log.d(TAG2, "onIceConnectionChange: $p0")
  }

  override fun onIceConnectionReceivingChange(p0: Boolean) {
    Log.d(TAG2, "onIceConnectionReceivingChange: $p0")
  }

  override fun onIceGatheringChange(p0: PeerConnection.IceGatheringState?) {
    Log.d(TAG2, "onIceGatheringChange: $p0")
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
    Log.d(TAG2, "onAddStream: $p0")
  }

  override fun onRemoveStream(p0: MediaStream?) {
    Log.d(TAG2, "onRemoveStream: $p0")
  }

  override fun onDataChannel(p0: DataChannel?) {
    Log.d(TAG2, "onDataChannel: $p0")
  }

  override fun onRenegotiationNeeded() {
    Log.d(TAG2, "onRenegotiationNeeded")
  }

  override fun onAddTrack(receiver: RtpReceiver?, mediaStreams: Array<out MediaStream>?) {
    Log.d(TAG2, "Track added")
    coroutineScope.launch(Dispatchers.Main) {
      val videoTrack = receiver?.track() as? VideoTrack?
      this@WHIPPlayer.videoTrack = videoTrack
      Log.d("TRACK", videoTrack!!.id())
      listeners.forEach { listener -> videoTrack?.let { listener.onTrackAdded(it) } }
    }
    onTrackAdded?.let { it() }
  }

  internal fun addTrackListener(listener: WHIPPlayerListener) {
    listeners.add(listener)
    videoTrack?.let { listener.onTrackAdded(it) }
  }
}
