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
  private var playerType: String = "WHIP"

  var player: WhipClient? = null

  init {
    ReactNativeMobileWhipClientViewModule.onWhipTrackUpdateListeners.add(this)
  }

  fun init(playerType: String) {
    this.playerType = playerType
  }

  private fun setupTrack(videoTrack: VideoTrack) {
    if (player == null) {
      Log.d("test", "Player is null")
      return
    }
    if (videoView == null) {
      Log.d("test", "Creating view. Eglbase is: ${player!!.eglBase}")
      videoView = VideoView(context, player!!.eglBase)
      videoView!!.player = player
      
      // Set proper layout parameters to fill the parent
      val layoutParams = android.view.ViewGroup.LayoutParams(
        android.view.ViewGroup.LayoutParams.MATCH_PARENT,
        android.view.ViewGroup.LayoutParams.MATCH_PARENT
      )
      videoView!!.layoutParams = layoutParams
      
      addView(videoView)
      
      // Force a layout pass
      this@ReactNativeMobileWhipClientView.requestLayout()
      videoView!!.requestLayout()
    }
    
    // Wait for the view to be properly laid out
    videoView!!.post {
      // Wait for the parent view to be laid out first
      if (this@ReactNativeMobileWhipClientView.width == 0 || this@ReactNativeMobileWhipClientView.height == 0) {
        Log.d("test", "Parent view not laid out yet, waiting...")
        this@ReactNativeMobileWhipClientView.post {
          setupTrack(videoTrack)
        }
        return@post
      }
      
      // Now wait for the VideoView to be laid out
      if (videoView!!.width == 0 || videoView!!.height == 0) {
        Log.d("test", "VideoView not laid out yet, waiting...")
        videoView!!.post {
          // Try one more time after layout
          if (videoView!!.width == 0 || videoView!!.height == 0) {
            Log.d("test", "VideoView still not laid out, trying with parent dimensions...")
            // Use parent dimensions as fallback
            val parentWidth = this@ReactNativeMobileWhipClientView.width
            val parentHeight = this@ReactNativeMobileWhipClientView.height
            Log.d("test", "Parent dimensions: ${parentWidth}x${parentHeight}")
            if (parentWidth > 0 && parentHeight > 0) {
              // Force the VideoView to have the same dimensions as parent
              videoView!!.layout(0, 0, parentWidth, parentHeight)
              Log.d("test", "Forced VideoView layout to parent dimensions")
            }
            setupVideoTrack(videoTrack)
          } else {
            setupVideoTrack(videoTrack)
          }
        }
      } else {
        setupVideoTrack(videoTrack)
      }
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
