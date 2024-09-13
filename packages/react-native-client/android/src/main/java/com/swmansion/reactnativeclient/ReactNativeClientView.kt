package com.swmansion.reactnativeclient

import android.content.Context
import android.graphics.Color
import android.util.Log
import android.widget.FrameLayout
import android.widget.TextView
import com.mobilewhep.client.VideoView
import com.swmansion.reactnativeclient.ReactNativeClientModule.Companion.whepClient
import expo.modules.kotlin.AppContext
import expo.modules.kotlin.views.ExpoView
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import org.webrtc.VideoTrack

class ReactNativeClientView(
  context: Context,
  appContext: AppContext,
) : ExpoView(context, appContext),
  ReactNativeClientModule.OnTrackUpdateListener {
  private val videoView: VideoView

  init {
    ReactNativeClientModule.onTrackUpdateListeners.add(this)
    videoView =
      VideoView(context).apply {
        layoutParams = FrameLayout.LayoutParams(FrameLayout.LayoutParams.MATCH_PARENT, 200)
      }
    videoView.layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT)
    addView(videoView)
  }

  private fun setupTrack(videoTrack: VideoTrack) {
    videoView.player = whepClient
    videoView.player?.videoTrack?.removeSink(videoView)
    videoView.player?.videoTrack = videoTrack
    videoTrack.addSink(videoView)
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
