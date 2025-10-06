package com.swmansion.reactnativeclient

import android.content.Context
import android.util.Log
import com.mobilewhep.client.VideoView
import com.mobilewhep.client.WhipClient
import expo.modules.kotlin.AppContext
import expo.modules.kotlin.views.ExpoView
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import org.webrtc.VideoTrack

class ReactNativeMobileWhipClientView(
  context: Context,
  appContext: AppContext,
) : ExpoView(context, appContext),
  ReactNativeMobileWhipClientViewModule.OnTrackUpdateListener {
  private var videoView: VideoView? = null

  var player: WhipClient? = null

  init {
    ReactNativeMobileWhipClientViewModule.onWhipTrackUpdateListeners.add(this)
  }

  private fun setupTrack(videoTrack: VideoTrack) {
    if (player == null) return
    
    if (videoView == null) {
      videoView = VideoView(context, player!!.eglBase)
      videoView!!.player = player
      
      // Set layout parameters to fill parent
      videoView!!.layoutParams = android.view.ViewGroup.LayoutParams(
        android.view.ViewGroup.LayoutParams.MATCH_PARENT,
        android.view.ViewGroup.LayoutParams.MATCH_PARENT
      )
      
      addView(videoView)
    }
    
    // Wait for layout, then setup video track
    videoView!!.post {
      // If VideoView has no dimensions, use parent dimensions
      if (videoView!!.width == 0 || videoView!!.height == 0) {
        val parentWidth = this@ReactNativeMobileWhipClientView.width
        val parentHeight = this@ReactNativeMobileWhipClientView.height
        if (parentWidth > 0 && parentHeight > 0) {
          videoView!!.layout(0, 0, parentWidth, parentHeight)
        }
      }
      
      setupVideoTrack(videoTrack)
    }
  }

  private fun setupVideoTrack(videoTrack: VideoTrack) {
    Log.d("test", "Setting up video track with dimensions: ${videoView!!.width}x${videoView!!.height}")
    videoView!!.player?.videoTrack?.removeSink(videoView)
    videoView!!.player?.videoTrack = videoTrack
    videoTrack.addSink(videoView)
    Log.d("test", "Video track setup complete")
  }

  private fun update(track: VideoTrack) {
    CoroutineScope(Dispatchers.Main).launch {
      setupTrack(track)
    }
  }

  override fun onTrackUpdate(track: VideoTrack) {
    update(track)
  }

  override fun onAttachedToWindow() {
    super.onAttachedToWindow()
    Log.d("test", "View attached to window")
    
    // Ensure the view is properly laid out before setting up video track
    post {
      if (videoView != null && player != null) {
        Log.d("test", "View is laid out, setting up video track")
        // Re-trigger video track setup if player and videoView are ready
        player?.videoTrack?.let { track ->
          setupTrack(track)
        }
      }
    }
  }
}
