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
      videoView = VideoView(context, player!!.eglBase)
      videoView!!.player = player
      addView(videoView)
    }
    videoView!!.post {
      videoView!!.player?.videoTrack?.removeSink(videoView)
      videoView!!.player?.videoTrack = videoTrack
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
