package com.swmansion.reactnativeclient

import android.content.Context
import com.mobilewhep.client.VideoView
import com.swmansion.reactnativeclient.ReactNativeMobileWhepClientModule.Companion.whipClient
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
  ReactNativeMobileWhepClientModule.OnTrackUpdateListener {
  private var videoView: VideoView? = null

  init {
    ReactNativeMobileWhepClientModule.onWhipTrackUpdateListeners.add(this)
  }

  private fun setupTrack(videoTrack: VideoTrack) {
    if (videoView == null) {
      videoView = VideoView(context, whipClient!!.eglBase)
      addView(videoView)
    }
    videoView!!.post {
      videoView!!.player = whipClient

      videoView!!.player?.videoTrack = videoTrack
      videoView!!.player?.videoTrack?.removeSink(videoView)
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
