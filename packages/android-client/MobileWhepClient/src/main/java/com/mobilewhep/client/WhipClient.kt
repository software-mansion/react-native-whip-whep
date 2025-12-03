package com.mobilewhep.client

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.util.DisplayMetrics
import android.util.Log
import android.view.WindowManager
import androidx.core.content.ContextCompat
import com.mobilewhep.client.utils.PeerConnectionFactoryHelper
import kotlinx.coroutines.suspendCancellableCoroutine
import okhttp3.Call
import okhttp3.Callback
import okhttp3.Request
import okhttp3.Response
import org.webrtc.AudioSource
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
import org.webrtc.ScreenCapturerAndroid
import org.webrtc.SessionDescription
import org.webrtc.Size
import org.webrtc.SurfaceTextureHelper
import org.webrtc.VideoSource
import org.webrtc.VideoTrack
import java.io.EOFException
import java.io.IOException
import java.net.ConnectException
import java.net.URI
import java.net.URL
import java.util.UUID
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException
import kotlin.math.roundToInt

data class WhipConfigurationOptions(
  val audioEnabled: Boolean = true,
  val videoEnabled: Boolean = true,
  val stunServerUrl: String? = null,
  val videoParameters: VideoParameters = VideoParameters.presetHD169,
  val videoDevice: String? = null,
  val preferredVideoCodecs: List<String>,
  val preferredAudioCodecs: List<String>,
  val isScreenSharingMode: Boolean = false
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
  private var audioSource: AudioSource? = null
  private var screenCapturer: ScreenCapturerAndroid? = null
  private var cameraSurfaceTextureHelper: SurfaceTextureHelper? = null
  private var screenSurfaceTextureHelper: SurfaceTextureHelper? = null

  public var currentCameraDeviceId: String? = null
  private val peerConnectionFactory = PeerConnectionFactoryHelper.getWhipFactory(appContext, eglBase)
  private var isSharingScreen: Boolean = false
  private val isScreenSharingMode: Boolean

  init {
    isScreenSharingMode = configOptions.isScreenSharingMode
    if (!isScreenSharingMode) {
      setUpVideoAndAudioDevices()
    }
  }

  fun getPeerConnectionFactory(): PeerConnectionFactory = peerConnectionFactory

  fun setupPeerConnection() {
    super.setupPeerConnection(peerConnectionFactory)

    val audioEnabled = configOptions.audioEnabled
    val videoEnabled = configOptions.videoEnabled
    val direction = RtpTransceiver.RtpTransceiverDirection.SEND_ONLY

    Log.d(
      CLIENT_TAG,
      "Setting up peer connection - videoTrack: ${videoTrack != null}, audioTrack: ${audioTrack != null}, isSharingScreen: $isSharingScreen"
    )

    if (videoEnabled && videoTrack != null) {
      val transceiverInit = RtpTransceiver.RtpTransceiverInit(direction)
      val transceiver = peerConnection?.addTransceiver(videoTrack, transceiverInit)
      Log.d(CLIENT_TAG, "Added video transceiver for ${if (isScreenSharingMode) "screen share" else "camera"}")
      setCodecPreferencesIfAvailable(
        transceiver,
        configOptions.preferredVideoCodecs,
        MediaStreamTrack.MediaType.MEDIA_TYPE_VIDEO,
        factory = peerConnectionFactory
      )
    } else if (videoEnabled) {
      Log.e(CLIENT_TAG, "Video enabled but videoTrack is null!")
    }

    if (audioEnabled && audioTrack != null) {
      val audioTransceiverInit = RtpTransceiver.RtpTransceiverInit(direction)
      val transceiver = peerConnection?.addTransceiver(audioTrack, audioTransceiverInit)
      Log.d(CLIENT_TAG, "Added audio transceiver")
      setCodecPreferencesIfAvailable(
        transceiver,
        configOptions.preferredAudioCodecs,
        MediaStreamTrack.MediaType.MEDIA_TYPE_AUDIO,
        factory = peerConnectionFactory
      )
    } else if (audioEnabled) {
      Log.e(CLIENT_TAG, "Audio enabled but audioTrack is null!")
    }
  }

  /**
   * Gets the video and audio devices, prepares them, starts capture and adds it to the Peer Connection.
   *
   * @throws CaptureDeviceError.VideoDeviceNotAvailable if there is no video device.
   */
  private fun setUpVideoAndAudioDevices() {
    val audioEnabled = configOptions.audioEnabled
    val videoEnabled = configOptions.videoEnabled

    if (videoEnabled && configOptions.videoDevice == null) {
      throw CaptureDeviceError.VideoDeviceNotAvailable("Video device not found. Check if it can be accessed and passed to the constructor.")
    }

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
      cameraSurfaceTextureHelper = surfaceTextureHelper
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

      this.audioSource = audioSource
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

      if (isScreenSharingMode) {
        if (videoTrack == null ||
          screenCapturer == null ||
          (configOptions.audioEnabled && audioTrack == null)
        ) {
          Log.w(CLIENT_TAG, "Screen sharing setup incomplete during connect.\nAudio track: $audioTrack,\nVideo track: $videoTrack")
          throw SessionNetworkError.ConfigurationError(
            "Failed to connect: screen sharing setup not complete. Check if permissions were granted."
          )
        }
      } else {
        if (videoTrack == null ||
          videoCapturer == null ||
          (configOptions.audioEnabled && audioTrack == null)
        ) {
          setUpVideoAndAudioDevices()
        }
      }

      if (peerConnection == null) {
        setupPeerConnection()
      }
      val requiredPermissions =
        if (isScreenSharingMode) {
          if (configOptions.audioEnabled) {
            arrayOf(Manifest.permission.RECORD_AUDIO)
          } else {
            emptyArray()
          }
        } else {
          REQUIRED_PERMISSIONS
        }

      if (requiredPermissions.isNotEmpty() && !hasPermissions(appContext, requiredPermissions)) {
        val permissionType = if (isScreenSharingMode) "audio recording" else "camera and audio recording"
        throw PermissionError.PermissionsNotGrantedError(
          "Permissions for $permissionType have not been granted. Please check your application settings."
        )
      }

      val constraints = MediaConstraints()
      peerConnection?.let {
        Log.d(CLIENT_TAG, "Creating SDP offer for ${if (isScreenSharingMode) "screen share" else "camera"}")
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
      throw SessionNetworkError.ConnectionError("Connection failed: ${e.message ?: e.javaClass.simpleName}")
    }
  }

  fun stopScreenShare() {
    if (!isSharingScreen) {
      Log.w(CLIENT_TAG, "Screen sharing is not active")
      return
    }

    Log.d(CLIENT_TAG, "Stopping screen share")

    cleanupScreenCapturer()
    cleanupVideoTrack()

    isSharingScreen = false

    Log.d(CLIENT_TAG, "Screen share stopped")
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
    if (isSharingScreen) {
      stopScreenShare()
    }
    cleanupPeerConnection()
    disconnectResource()
  }

  private fun cleanupPeerConnection() {
    peerConnection?.close()
    peerConnection?.dispose()
    peerConnection = null
  }

  private fun cleanupVideoCapturer() {
    videoCapturer?.stopCapture()
    videoCapturer?.dispose()
    videoCapturer = null

    cameraSurfaceTextureHelper?.dispose()
    cameraSurfaceTextureHelper = null
  }

  private fun cleanupScreenCapturer() {
    screenCapturer?.stopCapture()
    screenCapturer?.dispose()
    screenCapturer = null

    screenSurfaceTextureHelper?.dispose()
    screenSurfaceTextureHelper = null
  }

  private fun cleanupVideoTrack() {
    videoSource?.dispose()
    videoSource = null

    videoTrack?.dispose()
    videoTrack = null
  }

  private fun cleanupAudioTrack() {
    audioSource?.dispose()
    audioSource = null

    audioTrack?.dispose()
    audioTrack = null
  }

  fun cleanup() {
    cleanupVideoCapturer()
    cleanupScreenCapturer()
    cleanupVideoTrack()
    cleanupAudioTrack()
    cleanupPeerConnection()
    cleanupFactory()
    cleanupEglBase()
  }

  fun switchCamera(deviceId: String) {
    if (isSharingScreen) {
      Log.w(CLIENT_TAG, "Cannot switch camera while screen sharing")
      return
    }

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

  /**
   * Starts screen sharing using MediaProjection.
   * Note: MediaProjection permission must be obtained at the Activity level before calling this.
   *
   * @param mediaProjectionIntent The intent received from MediaProjection permission dialog
   */
  fun startScreenShare(mediaProjectionIntent: Intent) {
    Log.d(CLIENT_TAG, "Starting screen share with MediaProjection")

    isSharingScreen = true

    cleanupVideoCapturer()
    cleanupVideoTrack()

    val screenCapturer =
      ScreenCapturerAndroid(
        mediaProjectionIntent,
        object : android.media.projection.MediaProjection.Callback() {
          override fun onStop() {
            super.onStop()
            Log.d(CLIENT_TAG, "Screen capture stopped")
            isSharingScreen = false
          }
        }
      )

    val videoSource: VideoSource = peerConnectionFactory.createVideoSource(true)
    val surfaceTextureHelper = SurfaceTextureHelper.create("ScreenCaptureThread", eglBase.eglBaseContext)
    screenSurfaceTextureHelper = surfaceTextureHelper

    screenCapturer.initialize(surfaceTextureHelper, appContext, videoSource.capturerObserver)

    val screenDimensions = getScreenDimensions()
    val targetDimensions = downscaleResolution(screenDimensions, configOptions.videoParameters.dimensions)

    try {
      screenCapturer.startCapture(
        targetDimensions.width,
        targetDimensions.height,
        configOptions.videoParameters.maxFps
      )
      Log.d(CLIENT_TAG, "Screen capture started with dimensions ${targetDimensions.width}x${targetDimensions.height}")
    } catch (e: Exception) {
      Log.e(CLIENT_TAG, "Failed to start screen capture: ${e.message}", e)
      throw CaptureDeviceError.VideoSizeNotSupported(
        "Failed to start screen capture: ${e.message}"
      )
    }

    val videoTrackId = UUID.randomUUID().toString()
    val videoTrack: VideoTrack = peerConnectionFactory.createVideoTrack(videoTrackId, videoSource)

    this.videoSource = videoSource
    this.screenCapturer = screenCapturer
    this.currentCameraDeviceId = null

    videoTrack.setEnabled(true)
    this.videoTrack = videoTrack

    if (configOptions.audioEnabled && audioTrack == null) {
      val audioTrackId = UUID.randomUUID().toString()
      val audioSource = peerConnectionFactory.createAudioSource(MediaConstraints())
      val audioTrack = peerConnectionFactory.createAudioTrack(audioTrackId, audioSource)
      audioTrack.setEnabled(true)
      this.audioSource = audioSource
      this.audioTrack = audioTrack
      Log.d(CLIENT_TAG, "Audio track created for screen share")
    }

    notifyTrackListeners()

    Log.d(CLIENT_TAG, "Screen share setup complete")
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
                e is EOFException || e.message?.contains("unexpected end of stream") == true -> {
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

  private fun getScreenDimensions(): Dimensions {
    val windowManager = appContext.getSystemService(Context.WINDOW_SERVICE) as WindowManager
    val displayMetrics = DisplayMetrics()
    windowManager.defaultDisplay.getRealMetrics(displayMetrics)

    return Dimensions(width = displayMetrics.widthPixels, height = displayMetrics.heightPixels)
  }

  private fun downscaleResolution(
    from: Dimensions,
    to: Dimensions
  ): Dimensions =
    when {
      from.height > to.height -> {
        val ratio = from.height.toFloat() / from.width.toFloat()
        val newHeight = to.height
        val newWidth = (newHeight.toFloat() / ratio).roundToInt()
        Dimensions(width = newWidth, height = newHeight)
      }
      from.width > to.width -> {
        val ratio = from.height.toFloat() / from.width.toFloat()
        val newWidth = to.width
        val newHeight = (newWidth.toFloat() * ratio).roundToInt()
        Dimensions(width = newWidth, height = newHeight)
      }
      else -> from
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
