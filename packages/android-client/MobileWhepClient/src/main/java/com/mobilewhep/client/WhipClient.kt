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
import org.webrtc.PeerConnectionFactory
import org.webrtc.RtpTransceiver
import org.webrtc.SessionDescription
import org.webrtc.Size
import org.webrtc.SurfaceTextureHelper
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
  private var videoCapturer: CameraVideoCapturer? = null
  private var videoSource: VideoSource? = null

  public var currentCameraDeviceId: String? = null
  private val peerConnectionFactory = PeerConnectionFactoryHelper.getWhipFactory(appContext, eglBase)

  init {
    setUpVideoAndAudioDevices()
  }

  fun getPeerConnectionFactory(): PeerConnectionFactory = peerConnectionFactory

  fun setupPeerConnection() {
    super.setupPeerConnection(peerConnectionFactory)

    val audioEnabled = configOptions.audioEnabled
    val videoEnabled = configOptions.videoEnabled
    val direction = RtpTransceiver.RtpTransceiverDirection.SEND_ONLY

    if (videoEnabled) {
      val transceiverInit = RtpTransceiver.RtpTransceiverInit(direction)
      val transceiver = peerConnection?.addTransceiver(videoTrack, transceiverInit)
      setCodecPreferencesIfAvailable(
        transceiver,
        configOptions.preferredVideoCodecs,
        MediaStreamTrack.MediaType.MEDIA_TYPE_VIDEO,
        factory = peerConnectionFactory
      )
    }

    if (audioEnabled) {
      val audioTransceiverInit = RtpTransceiver.RtpTransceiverInit(direction)
      val transceiver = peerConnection?.addTransceiver(audioTrack, audioTransceiverInit)
      setCodecPreferencesIfAvailable(
        transceiver,
        configOptions.preferredAudioCodecs,
        MediaStreamTrack.MediaType.MEDIA_TYPE_AUDIO,
        factory = peerConnectionFactory
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
      val surfaceTextureHelper = SurfaceTextureHelper.create("CaptureThread", eglBase.eglBaseContext)
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
      this.currentCameraDeviceId = configOptions.videoDevice

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
    try {
      super.connect(connectOptions)

      if (videoTrack == null ||
        videoCapturer == null ||
        (configOptions.audioEnabled && audioTrack == null)
      ) {
        setUpVideoAndAudioDevices()
      }

      if (peerConnection == null) {
        setupPeerConnection()
      }

      if (!hasPermissions(appContext, REQUIRED_PERMISSIONS)) {
        throw PermissionError.PermissionsNotGrantedError(
          "Permissions for camera and audio recording have not been granted. Please check your application settings."
        )
      }

      val constraints = MediaConstraints()
      peerConnection?.let {
        val sdpOffer = it.createOffer(constraints).getOrThrow()
        it.setLocalDescription(sdpOffer).getOrThrow()

        val sdp = sendSdpOffer(sdpOffer.description)

        iceCandidates.forEach { sendCandidate(it) }

        val answer =
          SessionDescription(
            SessionDescription.Type.ANSWER,
            sdp
          )
        it.setRemoteDescription(answer)
      } ?: {
        throw SessionNetworkError.ConfigurationError("Failed to connect: no peer connection")
      }
    } catch (e: PermissionError.PermissionsNotGrantedError) {
      cleanupPeerConnection()
      throw e
    } catch (e: SessionNetworkError) {
      cleanupPeerConnection()
      throw e
    } catch (e: AttributeNotFoundError) {
      cleanupPeerConnection()
      throw e
    } catch (e: Exception) {
      Log.e(CLIENT_TAG, "Failed to connect: ${e.message}", e)
      cleanupPeerConnection()
      throw SessionNetworkError.ConnectionError("Connection failed: ${e.message ?: "Unknown error"}")
    }
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
    cleanupPeerConnection()
    disconnectResource()
  }

  private fun cleanupPeerConnection() {
    peerConnection?.close()
    peerConnection?.dispose()
    peerConnection = null
  }

  fun cleanup() {
    videoCapturer?.stopCapture()
    videoCapturer?.dispose()
    videoCapturer = null

    videoSource?.dispose()
    videoSource = null

    videoTrack?.dispose()
    videoTrack = null

    audioTrack?.dispose()
    audioTrack = null

    cleanupPeerConnection()
    cleanupFactory()
    cleanupEglBase()
  }

  fun switchCamera(deviceId: String) {
    val enumerator: CameraEnumerator =
      if (Camera2Enumerator.isSupported(appContext)) Camera2Enumerator(appContext) else Camera1Enumerator(false)

    val availableDevices = enumerator.deviceNames
    if (!availableDevices.contains(deviceId)) {
      Log.w(CLIENT_TAG, "Device with ID $deviceId not found. Available devices: $availableDevices")
      return
    }

    try {
      videoCapturer?.switchCamera(
        object : CameraVideoCapturer.CameraSwitchHandler {
          override fun onCameraSwitchDone(isFrontCamera: Boolean) {
            // Camera switch completed successfully
            currentCameraDeviceId = deviceId
          }

          override fun onCameraSwitchError(errorDescription: String?) {
            Log.e(CLIENT_TAG, "Camera switch error: $errorDescription")
          }
        },
        deviceId
      )
    } catch (e: Exception) {
      Log.e(CLIENT_TAG, "Failed to switch camera to $deviceId: ${e.message}")
    }
  }

  protected fun cleanupFactory() {
    PeerConnectionFactoryHelper.clearWhipFactory()
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
            val errorMessage =
              when {
                e is ConnectException -> {
                  "DELETE Failed, network error. Check if the server is up and running and the token and the server url is correct."
                }
                e is java.io.EOFException || e.message?.contains("unexpected end of stream") == true -> {
                  "Server closed connection unexpectedly during disconnect. The WHIP server may have already terminated the session or crashed."
                }
                else -> {
                  "Failed to disconnect: ${e.message}"
                }
              }

            Log.e(CLIENT_TAG, "Disconnect failed: $errorMessage", e)
            continuation.resumeWithException(
              SessionNetworkError.ConnectionError(errorMessage)
            )
          }

          override fun onResponse(
            call: Call,
            response: Response
          ) {
            response.use {
              if (!response.isSuccessful) {
                val exception =
                  AttributeNotFoundError.ResponseNotFound(
                    "DELETE Failed, invalid response. Status code: ${response.code}. Check if the server is up and running and the token and the server url is correct."
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
