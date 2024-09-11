package com.swmansion.reactnativeclient

import android.content.Context
import android.graphics.Color
import android.graphics.drawable.ColorDrawable
import android.widget.TextView
import expo.modules.kotlin.AppContext
import expo.modules.kotlin.views.ExpoView

class ReactNativeClientView(context: Context, appContext: AppContext) : ExpoView(context, appContext) {

  private val trackIdTextView: TextView

  init {
      background = ColorDrawable(Color.RED)
    trackIdTextView = TextView(context).apply {
      setTextColor(Color.BLACK)
      textSize = 30f           // Optional: change text size
    }

    // Add TextView to this view
    addView(trackIdTextView)
  }

  private var trackId: String? = null
  fun init(trackId: String) {
    this.trackId = trackId
    trackIdTextView.text = trackId
  }

}
