package com.swmansion.androidexample

import android.content.Context
import android.graphics.SurfaceTexture
import android.view.TextureView
import org.webrtc.EglBase
import org.webrtc.GlRectDrawer
import org.webrtc.RendererCommon
import org.webrtc.SurfaceEglRenderer
import org.webrtc.VideoFrame
import org.webrtc.VideoSink
import org.webrtc.VideoTrack

class WHIPPlayerView: TextureView, TextureView.SurfaceTextureListener, VideoSink,
  RendererCommon.RendererEvents,WHIPPlayerListener {
  var player: WHIPPlayer? = null
    set(newPlayer) {
      newPlayer?.addTrackListener(this)
      field = newPlayer
    }

  private val eglRenderer: SurfaceEglRenderer
  private var rendererEvents: RendererCommon.RendererEvents? = null

  /**
   * Standard View constructor. In order to render something, you must first call init().
   */
  constructor(context: Context) : super(context) {
    eglRenderer = SurfaceEglRenderer("WHIPPlayerView")
    surfaceTextureListener = this
  }

  internal fun init(sharedContext: EglBase.Context, rendererEvents: RendererCommon.RendererEvents?, drawer: RendererCommon.GlDrawer? = GlRectDrawer()) {
    this.rendererEvents = rendererEvents
    eglRenderer.init(sharedContext, this, EglBase.CONFIG_PLAIN, drawer)
  }
  fun release() {
    eglRenderer.release()
  }

  override fun onTrackAdded(track: VideoTrack) {
    init(player!!.eglBase.eglBaseContext, null)
    track.addSink(this)
  }

  override fun onSurfaceTextureAvailable(surface: SurfaceTexture, width: Int, height: Int) {
    TODO("Not yet implemented")
  }

  override fun onSurfaceTextureSizeChanged(surface: SurfaceTexture, width: Int, height: Int) {
    TODO("Not yet implemented")
  }

  override fun onSurfaceTextureDestroyed(surface: SurfaceTexture): Boolean {
    TODO("Not yet implemented")
  }

  override fun onSurfaceTextureUpdated(surface: SurfaceTexture) {
    TODO("Not yet implemented")
  }

  override fun onFrame(p0: VideoFrame?) {
    eglRenderer.onFrame(p0)
  }

  override fun onFirstFrameRendered() {
    TODO("Not yet implemented")
  }

  override fun onFrameResolutionChanged(p0: Int, p1: Int, p2: Int) {
    TODO("Not yet implemented")
  }
}
