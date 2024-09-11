package com.swmansion.reactnativeclient

import android.content.Context
import android.graphics.Color
import android.graphics.drawable.ColorDrawable
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

class ReactNativeClientView(context: Context, appContext: AppContext) : ExpoView(context, appContext), ReactNativeClientModule.OnTrackUpdateListener {

  private val trackIdTextView: TextView
  private var activeVideoTrack: VideoTrack? = null
  private val videoView: VideoView

  init {
    ReactNativeClientModule.onTrackUpdateListeners.add(this)
    background = ColorDrawable(Color.RED)

    trackIdTextView = TextView(context).apply {
      setTextColor(Color.BLACK)
      textSize = 30f
    }
    addView(trackIdTextView)
    videoView = VideoView(context).apply {
      layoutParams = FrameLayout.LayoutParams(FrameLayout.LayoutParams.MATCH_PARENT, 200)
      player = whepClient
    }
    videoView.layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT)
    addView(videoView)
  }

  private fun setupTrack(videoTrack: VideoTrack) {
    Log.d("kotki", videoTrack.id())
    if (activeVideoTrack == videoTrack) return

    activeVideoTrack = videoTrack

    videoView.player?.videoTrack?.removeSink(videoView)
    videoView.player?.videoTrack = videoTrack
    videoTrack.addSink(videoView)
  }

  private fun update(track: VideoTrack) {
    CoroutineScope(Dispatchers.Main).launch {
      Log.d("kotki", track.id() ?: "też ni ma")
      setupTrack(track)
    }
  }

  private var trackId: String? = null
  fun init(trackId: String) {
    this.trackId = trackId
    trackIdTextView.text = whepClient?.videoTrack?.id() ?: ""
    Log.d("kotki", activeVideoTrack?.id() ?: "ni ma")
  }

  override fun onTrackUpdate(track: VideoTrack) {
    Log.d("kotki", "update")
    update(track)
  }
}
