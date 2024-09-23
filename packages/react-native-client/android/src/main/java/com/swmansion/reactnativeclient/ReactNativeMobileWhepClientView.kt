package com.swmansion.reactnativeclient

import android.content.Context
import android.widget.FrameLayout
import com.mobilewhep.client.VideoView
import com.swmansion.reactnativeclient.ReactNativeMobileWhepClientModule.Companion.whepClient
import com.swmansion.reactnativeclient.ReactNativeMobileWhepClientModule.Companion.whipClient
import expo.modules.kotlin.AppContext
import expo.modules.kotlin.views.ExpoView
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import org.webrtc.VideoTrack

class ReactNativeMobileWhepClientView(
  context: Context,
  appContext: AppContext,
) : ExpoView(context, appContext),
  ReactNativeMobileWhepClientModule.OnTrackUpdateListener {
  private val videoView: VideoView
  private var playerType: String = "WHEP"

  init {
    ReactNativeMobileWhepClientModule.onTrackUpdateListeners.add(this)
    videoView =
      VideoView(context).apply {
        layoutParams = FrameLayout.LayoutParams(FrameLayout.LayoutParams.MATCH_PARENT, 200)
      }
    videoView.layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT)
    addView(videoView)
  }

  fun init(playerType: String) {
    this.playerType = playerType
  }

  private fun setupTrack(videoTrack: VideoTrack) {
    videoView.post {
      if (playerType == "WHIP") {
        videoView.player = whipClient
      } else {
        videoView.player = whepClient
      }

      videoView.player?.videoTrack?.removeSink(videoView)
      videoView.player?.videoTrack = videoTrack

      videoTrack.addSink(videoView)
    }
  }

  private fun update(track: VideoTrack) {
    CoroutineScope(Dispatchers.Main).launch {
      setupTrack(track)
    }
  }

  override fun onTrackUpdate(track: VideoTrack) {
    update(track)
  }
}
