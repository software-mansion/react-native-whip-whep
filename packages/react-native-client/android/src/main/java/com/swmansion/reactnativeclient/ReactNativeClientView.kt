package com.swmansion.reactnativeclient

import android.content.Context
import android.graphics.Color
import android.graphics.drawable.ColorDrawable
import android.provider.CalendarContract.Colors
import android.widget.FrameLayout
import com.mobilewhep.client.ClientBase
import com.mobilewhep.client.VideoView
import expo.modules.kotlin.AppContext
import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition
import expo.modules.kotlin.views.ExpoView

class ReactNativeClientView(context: Context, appContext: AppContext) : ExpoView(context, appContext) {
  init {
      foreground = ColorDrawable(Color.RED)
  }

  private var trackId: String? = null
  fun init(trackId: String) {
    this.trackId = trackId
  }

}
