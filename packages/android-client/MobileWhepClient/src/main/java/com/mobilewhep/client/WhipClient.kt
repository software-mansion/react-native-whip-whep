package com.mobilewhep.client

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.util.Log
import androidx.core.content.ContextCompat
import com.mobilewhep.client.utils.PeerConnectionFactoryHelper
import kotlinx.coroutines.suspendCancellableCoroutine
import okhttp3.Call
import okhttp3.Callback
import okhttp3.Request
import okhttp3.Response
import org.webrtc.Camera1Enumerator
import org.webrtc.Camera2Enumerator
import org.webrtc.CameraEnumerationAndroid
import org.webrtc.CameraEnumerator
import org.webrtc.CameraVideoCapturer
import org.webrtc.MediaConstraints
import org.webrtc.MediaStreamTrack
import org.webrtc.PeerConnection
import org.webrtc.RtpTransceiver
import org.webrtc.SessionDescription
import org.webrtc.Size
import org.webrtc.SurfaceTextureHelper
import org.webrtc.VideoCapturer
import org.webrtc.VideoSource
import org.webrtc.VideoTrack
import java.io.IOException
import java.net.ConnectException
import java.net.URI
import java.net.URL
import java.util.UUID
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

data class WhipConfigurationOptions(
  val audioEnabled: Boolean = true,
  val videoEnabled: Boolean = true,
  val stunServerUrl: String? = null,
  val videoParameters: VideoParameters = VideoParameters.presetHD169,
  val videoDevice: String? = null,
  val preferredVideoCodecs: List<String>,
  val preferredAudioCodecs: List<String>
)

class WhipClient(
  appContext: Context,
  private val configOptions: WhipConfigurationOptions
) : ClientBase(
    appContext,
    stunServerUrl = configOptions.stunServerUrl
  ) {
  override var videoTrack: VideoTrack? = null
  private var videoCapturer: VideoCapturer? = null
  private var videoSource: VideoSource? = null

  init {
    setUpVideoAndAudioDevices()
  }

  override fun setupPeerConnection() {
    super.setupPeerConnection()

    val audioEnabled = configOptions.audioEnabled
    val videoEnabled = configOptions.videoEnabled
    val direction = RtpTransceiver.RtpTransceiverDirection.SEND_ONLY

    if (videoEnabled) {
      val transceiverInit = RtpTransceiver.RtpTransceiverInit(direction)
      val transceiver = peerConnection?.addTransceiver(videoTrack, transceiverInit)
      setCodecPreferencesIfAvailable(
        transceiver,
        configOptions.preferredVideoCodecs,
        MediaStreamTrack.MediaType.MEDIA_TYPE_VIDEO
      )
    }

    if (audioEnabled) {
      val audioTransceiverInit = RtpTransceiver.RtpTransceiverInit(direction)
      val transceiver = peerConnection?.addTransceiver(audioTrack, audioTransceiverInit)
      setCodecPreferencesIfAvailable(
        transceiver,
        configOptions.preferredAudioCodecs,
        MediaStreamTrack.MediaType.MEDIA_TYPE_AUDIO
      )
    }
  }

  /**
   * Gets the video and audio devices, prepares them, starts capture and adds it to the Peer Connection.
   *
   * @throws CaptureDeviceError.VideoDeviceNotAvailable if there is no video device.
   */
  private fun setUpVideoAndAudioDevices() {
    if (configOptions.videoDevice == null) {
      throw CaptureDeviceError.VideoDeviceNotAvailable("Video device not found. Check if it can be accessed and passed to the constructor.")
    }

    val audioEnabled = configOptions.audioEnabled
    val videoEnabled = configOptions.videoEnabled

    if (!audioEnabled && !videoEnabled) {
      Log.d(
        CLIENT_TAG,
        "Both audioEnabled and videoEnabled is set to false, which will result in no stream at all. " +
          "Consider changing one of the options to true."
      )
    }

    if (videoEnabled) {
      val videoTrackId = UUID.randomUUID().toString()

      val cameraEnumerator: CameraEnumerator =
        if (Camera2Enumerator.isSupported(appContext)) {
          Camera2Enumerator(appContext)
        } else {
          Camera1Enumerator(false)
        }

      val videoCapturer: CameraVideoCapturer? =
        configOptions.videoDevice.let {
          cameraEnumerator.createCapturer(it, null)
        }

      val videoSource: VideoSource =
        peerConnectionFactory.createVideoSource(videoCapturer!!.isScreencast)
      val surfaceTextureHelper = SurfaceTextureHelper.create("CaptureThread", PeerConnectionFactoryHelper.eglBase.eglBaseContext)
      videoCapturer.initialize(surfaceTextureHelper, appContext, videoSource.capturerObserver)
      val videoSize =
        setVideoSize(
          cameraEnumerator,
          configOptions.videoDevice,
          configOptions.videoParameters
        )
      try {
        videoCapturer.startCapture(
          videoSize!!.width,
          videoSize.height,
          configOptions.videoParameters.maxFps
        )
      } catch (e: Exception) {
        throw CaptureDeviceError.VideoSizeNotSupported(
          "VideoSize ${configOptions.videoParameters} is not supported by this device. Consider switching to another preset."
        )
      }

      val videoTrack: VideoTrack = peerConnectionFactory.createVideoTrack(videoTrackId, videoSource)

      this.videoSource = videoSource
      this.videoCapturer = videoCapturer

      videoTrack.setEnabled(true)
      this.videoTrack = videoTrack
    }

    if (audioEnabled) {
      val audioTrackId = UUID.randomUUID().toString()
      val audioSource = this.peerConnectionFactory.createAudioSource(MediaConstraints())
      val audioTrack = this.peerConnectionFactory.createAudioTrack(audioTrackId, audioSource)

      this.audioTrack = audioTrack

    }

    peerConnection?.enforceSendOnlyDirection()
  }

  private val REQUIRED_PERMISSIONS =
    arrayOf(Manifest.permission.CAMERA, Manifest.permission.RECORD_AUDIO)

  /**
   * Connects the client to the WHIP server using WebRTC Peer Connection.
   *
   * @throws SessionNetworkError.ConfigurationError if the stunServerUrl parameter
   *  of the initial configuration is incorrect, which leads to peerConnection being nil
   *  or in any other case where there has been an error in creating the peerConnection
   *
   */
  override suspend fun connect(connectOptions: ClientConnectOptions) {
    super.connect(connectOptions)

    if (peerConnection == null) {
      setupPeerConnection()
    }

    if (!hasPermissions(appContext, REQUIRED_PERMISSIONS)) {
      throw PermissionError.PermissionsNotGrantedError(
        "Permissions for camera and audio recording have not been granted. Please check your application settings."
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
    peerConnection!!.setRemoteDescription(answer)
  }

  /**
   * Closes the established Peer Connection.
   *
   * @throws SessionNetworkError.ConfigurationError if the stunServerUrl parameter
   *  of the initial configuration is incorrect, which leads to peerConnection being nil
   *  or in any other case where there has been an error in creating the peerConnection
   *
   */
  suspend fun disconnect() {
    peerConnection?.close()
    peerConnection?.dispose()
    peerConnection = null

    disconnectResource()
  }

  fun cleanup() {
    peerConnection?.close()
    peerConnection = null
    videoCapturer?.stopCapture()
  }

  private suspend fun disconnectResource() {
    suspendCancellableCoroutine { continuation ->
      if (connectOptions == null) {
        continuation.resumeWithException(
          SessionNetworkError.ConnectionError(
            "Cannot DELETE. Connection not setup. Remember to call connect first."
          )
        )
        return@suspendCancellableCoroutine
      }

      val serverUrl = URL(connectOptions!!.serverUrl)

      val requestURL =
        URI(serverUrl.protocol, null, serverUrl.host, serverUrl.port, patchEndpoint, null, null)

      var requestBuilder: Request.Builder =
        Request
          .Builder()
          .url(requestURL.toURL())
          .delete()
      if (connectOptions!!.authToken != null) {
        requestBuilder =
          requestBuilder.header("Authorization", "Bearer " + connectOptions!!.authToken)
      }

      val request = requestBuilder.build()
      val requestCall = client.newCall(request)

      continuation.invokeOnCancellation {
        requestCall.cancel()
      }

      requestCall.enqueue(
        object : Callback {
          override fun onFailure(
            call: Call,
            e: IOException
          ) {
            if (e is ConnectException) {
              continuation.resumeWithException(
                SessionNetworkError.ConnectionError(
                  "DELETE Failed, network error. Check if the server is up and running and the token and the server url is correct."
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
              if (!response.isSuccessful) {
                val exception =
                  AttributeNotFoundError.ResponseNotFound(
                    "DELETE Failed, invalid response. Check if the server is up and running and the token and the server url is correct."
                  )
                continuation.resumeWithException(exception)
              } else {
                continuation.resume(Unit)
              }
            }
          }
        }
      )
    }
  }

  private fun PeerConnection.enforceSendOnlyDirection() {
    transceivers.forEach { transceiver ->
      if (transceiver.direction == RtpTransceiver.RtpTransceiverDirection.SEND_RECV) {
        transceiver.direction = RtpTransceiver.RtpTransceiverDirection.SEND_ONLY
      }
    }
  }

  private fun setVideoSize(
    enumerator: CameraEnumerator,
    deviceName: String?,
    videoParameters: VideoParameters
  ): Size? {
    val sizes =
      enumerator
        .getSupportedFormats(deviceName)
        ?.map { Size(it.width, it.height) }
        ?: emptyList()

    val size =
      CameraEnumerationAndroid.getClosestSupportedSize(
        sizes,
        videoParameters.dimensions.width,
        videoParameters.dimensions.height
      )

    return size
  }

  private fun hasPermissions(
    context: Context,
    permissions: Array<String>
  ): Boolean {
    for (permission in permissions) {
      if (ContextCompat.checkSelfPermission(
          context,
          permission
        ) != PackageManager.PERMISSION_GRANTED
      ) {
        return false
      }
    }
    return true
  }



  companion object {
    private fun getEnumerator(context: Context): CameraEnumerator =
      if (Camera2Enumerator.isSupported(context)) {
        Camera2Enumerator(context)
      } else {
        Camera1Enumerator(true)
      }

    fun getCaptureDevices(context: Context): List<CaptureDevice> {
      val enumerator = getEnumerator(context)
      return enumerator.deviceNames.map { name ->
        CaptureDevice(
          name,
          enumerator.isFrontFacing(name),
          enumerator.isBackFacing(name)
        )
      }
    }
  }
}
