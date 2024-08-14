package com.swmansion.whipwhepdemo

import android.content.Context
import android.graphics.Matrix
import android.graphics.SurfaceTexture
import android.os.Looper
import android.util.Log
import android.view.Surface
import android.view.TextureView
import com.mobilewhep.client.ClientBaseListener
import com.mobilewhep.client.WhipClient
import org.webrtc.EglBase
import org.webrtc.GlRectDrawer
import org.webrtc.RendererCommon
import org.webrtc.RendererCommon.RendererEvents
import org.webrtc.RendererCommon.ScalingType
import org.webrtc.SurfaceEglRenderer
import org.webrtc.ThreadUtils
import org.webrtc.VideoFrame
import org.webrtc.VideoSink
import org.webrtc.VideoTrack
import java.util.concurrent.CountDownLatch
import kotlin.math.ceil
import kotlin.math.max
import kotlin.math.roundToInt

class WHIPPlayerView: TextureView, TextureView.SurfaceTextureListener, VideoSink,
  RendererEvents, ClientBaseListener {
  var player: WhipClient? = null
    set(newPlayer) {
      newPlayer?.addTrackListener(this)
      newPlayer?.videoTrack?.addSink(this)
      field = newPlayer
    }

  private val videoLayoutMeasure = RendererCommon.VideoLayoutMeasure()
  private val eglRenderer: SurfaceEglRenderer

  private var scalingType: ScalingType? = null

  // Callback for reporting renderer events. Read-only after initialization so no lock required.
  private var rendererEvents: RendererEvents? = null

  // Accessed only on the main thread.
  private var rotatedFrameWidth = 0
  private var rotatedFrameHeight = 0
  private var enableFixedSize = false
  private var surfaceWidth = 0
  private var surfaceHeight = 0

  /**
   * Standard View constructor. In order to render something, you must first call init().
   */
  constructor(context: Context) : super(context) {
    eglRenderer = SurfaceEglRenderer("WHIPPlayerView")
    surfaceTextureListener = this
  }

  private fun init(sharedContext: EglBase.Context, rendererEvents: RendererEvents?, drawer: RendererCommon.GlDrawer? = GlRectDrawer()) {
    this.rendererEvents = rendererEvents
    rotatedFrameWidth = 0
    rotatedFrameHeight = 0
    eglRenderer.init(sharedContext, this, EglBase.CONFIG_PLAIN, drawer)
  }
  fun release() {
    eglRenderer.release()
  }

  fun setEnableHardwareScaler(enabled: Boolean) {
    ThreadUtils.checkIsOnMainThread()

    enableFixedSize = enabled
    updateSurfaceSize()
  }

  fun setScalingType(scalingType: ScalingType?) {
    ThreadUtils.checkIsOnMainThread()

    this.scalingType = scalingType

    videoLayoutMeasure.setScalingType(scalingType)
    requestLayout()
  }

  override fun onMeasure(
    widthSpec: Int,
    heightSpec: Int
  ) {
    ThreadUtils.checkIsOnMainThread()

    val size =
      videoLayoutMeasure.measure(widthSpec, heightSpec, rotatedFrameWidth, rotatedFrameHeight)
    setMeasuredDimension(size.x, size.y)

    Log.d(WHEP_TAG, "onMeasure() New size: ${size.x}x${size.y}")
  }

  override fun onLayout(
    changed: Boolean,
    left: Int,
    top: Int,
    right: Int,
    bottom: Int
  ) {
    ThreadUtils.checkIsOnMainThread()

    val aspectRatio =
      when (this.scalingType) {
        ScalingType.SCALE_ASPECT_FIT ->
          rotatedFrameWidth.toFloat() / max(rotatedFrameHeight, 1)

        else ->
          (right - left) / (bottom - top).toFloat()
      }

    eglRenderer.setLayoutAspectRatio(aspectRatio)
    updateSurfaceSize()

    Log.d(WHEP_TAG, "onLayout() aspect ratio $aspectRatio")
  }

  private fun updateSurfaceSize() {
    ThreadUtils.checkIsOnMainThread()

    if (enableFixedSize && rotatedFrameWidth != 0 && rotatedFrameHeight != 0 && width != 0 && height != 0) {
      val layoutAspectRatio = width / height.toFloat()
      val frameAspectRatio = rotatedFrameWidth / rotatedFrameHeight.toFloat()
      val drawnFrameWidth: Float
      val drawnFrameHeight: Float

      var width = this.width.toFloat()
      var height = this.height.toFloat()

      when (scalingType) {
        ScalingType.SCALE_ASPECT_FILL -> {
          if (frameAspectRatio > layoutAspectRatio) {
            drawnFrameWidth = rotatedFrameHeight * layoutAspectRatio
            drawnFrameHeight = rotatedFrameHeight.toFloat()
          } else {
            drawnFrameWidth = rotatedFrameWidth.toFloat()
            drawnFrameHeight = rotatedFrameWidth / layoutAspectRatio
          }
          // Aspect ratio of the drawn frame and the view is the same.
          width = Math.min(width, drawnFrameWidth)
          height = Math.min(height, drawnFrameHeight)
        }

        else -> {
          width = rotatedFrameWidth.toFloat()
          height = rotatedFrameHeight.toFloat()
        }
      }

      Log.d(
        WHEP_TAG,
        "updateSurfaceSize() " +
          "layout size: ${getWidth()} x ${getHeight()}, " +
          "frame size: $rotatedFrameWidth x $rotatedFrameHeight, " +
          "requested surface size: $width x $height, " +
          "old surface size: $surfaceWidth x $surfaceHeight"
      )

      if (ceil(width).roundToInt() != surfaceWidth || ceil(height).roundToInt() != surfaceHeight) {
        surfaceWidth = ceil(width).roundToInt()
        surfaceHeight = ceil(height).roundToInt()
        adjustAspectRatio(width, height)
      }
    } else {
      surfaceHeight = 0
      surfaceWidth = 0
    }
  }

  private fun adjustAspectRatio(
    videoWidth: Float,
    videoHeight: Float
  ) {
    val viewWidth = width
    val viewHeight = height
    val aspectRatio = videoHeight / videoWidth
    val newWidth: Int
    val newHeight: Int

    if (viewHeight > viewWidth * aspectRatio) {
      // limited by narrow width; restrict height
      newWidth = viewWidth
      newHeight = ceil(viewWidth * aspectRatio).roundToInt()
    } else {
      // limited by short height; restrict width
      newWidth = ceil(viewHeight / aspectRatio).roundToInt()
      newHeight = viewHeight
    }

    val xoff = (viewWidth - newWidth) / 2
    val yoff = (viewHeight - newHeight) / 2

    Log.d(
      WHEP_TAG,
      "video=$videoWidth x $videoHeight view=$viewWidth x $viewHeight" +
        " newView=$newWidth x $newHeight off=$xoff,$yoff"
    )

    val txform = Matrix()
    getTransform(txform)
    txform.setScale(newWidth.toFloat() / viewWidth, newHeight.toFloat() / viewHeight)
    txform.postTranslate(xoff.toFloat(), yoff.toFloat())
    setTransform(txform)
  }

  // TextureView.SurfaceTextureListener implementation
  override fun onSurfaceTextureAvailable(
    surface: SurfaceTexture,
    width: Int,
    height: Int
  ) {
    ThreadUtils.checkIsOnMainThread()
    player?.eglBase?.eglBaseContext?.let {
      init(it, null)
    }
    eglRenderer.createEglSurface(Surface(surfaceTexture))
    surfaceHeight = 0
    surfaceWidth = surfaceHeight
    updateSurfaceSize()
  }

  override fun onSurfaceTextureSizeChanged(
    surface: SurfaceTexture,
    width: Int,
    height: Int
  ) {
    ThreadUtils.checkIsOnMainThread()

    Log.d(WHEP_TAG, "surfaceChanged: size: $width x $height")
  }

  override fun onSurfaceTextureDestroyed(surface: SurfaceTexture): Boolean {
    ThreadUtils.checkIsOnMainThread()

    val completionLatch = CountDownLatch(1)
    eglRenderer.releaseEglSurface { completionLatch.countDown() }

    ThreadUtils.awaitUninterruptibly(completionLatch)

    return true
  }

  override fun onFirstFrameRendered() {
    rendererEvents?.onFirstFrameRendered()
  }

  override fun onFrameResolutionChanged(
    videoWidth: Int,
    videoHeight: Int,
    rotation: Int
  ) {
    Log.d(WHEP_TAG, "Resolution changed to $videoWidth x $videoHeight with rotation of $rotation")
    rendererEvents?.onFrameResolutionChanged(videoWidth, videoHeight, rotation)

    val rotatedWidth = if (rotation == 0 || rotation == 180) videoWidth else videoHeight
    val rotatedHeight = if (rotation == 0 || rotation == 180) videoHeight else videoWidth

    // run immediately if possible for ui thread tests
    postOrRun {
      rotatedFrameWidth = rotatedWidth
      rotatedFrameHeight = rotatedHeight
      updateSurfaceSize()
      requestLayout()
    }
  }

  private fun postOrRun(r: Runnable) {
    if (Thread.currentThread() === Looper.getMainLooper().thread) {
      r.run()
    } else {
      post(r)
    }
  }


  override fun onSurfaceTextureUpdated(surface: SurfaceTexture) {
  }

  override fun onFrame(p0: VideoFrame?) {
    eglRenderer.onFrame(p0)
  }

  override fun onTrackAdded(track: VideoTrack) {
    track.addSink(this)
  }
}
