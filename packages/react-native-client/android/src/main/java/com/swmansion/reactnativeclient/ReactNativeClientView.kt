package com.swmansion.reactnativeclient

import android.content.Context
import android.widget.FrameLayout
import com.mobilewhep.client.ClientBase
import com.mobilewhep.client.VideoView
import expo.modules.kotlin.AppContext
import expo.modules.kotlin.views.ExpoView

class ReactNativeClientView(context: Context, appContext: AppContext) : ExpoView(context, appContext) {
  private var videoView: VideoView = VideoView(context)

  init {
    addView(videoView)
    LayoutParams(
      LayoutParams.MATCH_PARENT,
      LayoutParams.MATCH_PARENT
    ).also {
      videoView.layoutParams = it
    }
  }

  fun setClient(client: ClientBase) {
    videoView.player = client
  }
}
