package com.swmansion.reactnativeclient

import android.content.Context
import com.mobilewhep.client.VideoView
import com.swmansion.reactnativeclient.ReactNativeMobileWhepClientModule.Companion.whepClient
import com.swmansion.reactnativeclient.ReactNativeMobileWhepClientModule.Companion.whipClient
import expo.modules.kotlin.AppContext
import expo.modules.kotlin.views.ExpoView
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import org.webrtc.VideoFrame
import org.webrtc.VideoTrack

enum class Orientation {
    PORTRAIT,
    LANDSCAPE
}

class ReactNativeMobileWhepClientView(
  context: Context,
  appContext: AppContext,
) : ExpoView(context, appContext),
  ReactNativeMobileWhepClientModule.OnTrackUpdateListener {
  private val videoView: VideoView
  private var playerType: String = "WHEP"
  private var orientation: Orientation = Orientation.PORTRAIT

  init {
    ReactNativeMobileWhepClientModule.onTrackUpdateListeners.add(this)
    videoView = VideoView(context)
    addView(videoView)
  }

  fun init(playerType: String) {
    this.playerType = playerType
  }

  fun setOrientation(orientation: Orientation) {
    this.orientation = orientation
    reinitializeVideoTrackSink()
  }

  private fun setupTrack(videoTrack: VideoTrack) {
    videoView.post {
      if (playerType == "WHIP") {
        videoView.player = whipClient
      } else {
        videoView.player = whepClient
      }

      videoView.player?.videoTrack = videoTrack
      reinitializeVideoTrackSink()
    }
  }

  private fun reinitializeVideoTrackSink() {
    videoView.player?.videoTrack?.let { track ->
      track.removeSink(videoView)
      track.addSink {
        val rotation = when (orientation) {
          Orientation.PORTRAIT -> 0
          Orientation.LANDSCAPE -> -90
        }

        videoView.onFrame(VideoFrame(it.buffer, rotation, -1))
      }

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
