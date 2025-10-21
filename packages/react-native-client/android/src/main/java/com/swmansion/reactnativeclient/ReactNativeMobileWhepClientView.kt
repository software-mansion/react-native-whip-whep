package com.swmansion.reactnativeclient

import android.app.PictureInPictureParams
import android.content.Context
import android.os.Build
import android.util.Log
import android.util.Rational
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import androidx.annotation.RequiresApi
import androidx.fragment.app.FragmentActivity
import com.mobilewhep.client.VideoView
import com.swmansion.reactnativeclient.ReactNativeMobileWhepClientViewModule.Companion.whepClient
import com.swmansion.reactnativeclient.helpers.PictureInPictureHelperFragment
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
  ReactNativeMobileWhepClientViewModule.OnTrackUpdateListener {
  private var videoView: VideoView? = null
  private var currentWhepClientInstance: Any? = null

  init {
    ReactNativeMobileWhepClientViewModule.onWhepTrackUpdateListeners.add(this)
  }

  private fun setupTrack(videoTrack: VideoTrack) {
    if (whepClient == null) {
      Log.e("Test", "Setup track called without WHEP client.")
      return
    }

    reassignedWhepClientIfNeeded()

    if (videoView == null) {
      videoView = VideoView(context, whepClient!!.eglBase)
      videoView!!.player = whepClient

      addView(videoView, FrameLayout.LayoutParams(
        ViewGroup.LayoutParams.MATCH_PARENT,
        ViewGroup.LayoutParams.MATCH_PARENT
      ))
    }
    videoView!!.post {

      videoView!!.player?.videoTrack?.removeSink(videoView)
      videoView!!.player?.videoTrack = videoTrack
      videoTrack.addSink(videoView)

    }
  }

  private fun reassignedWhepClientIfNeeded() {
    Log.d("Test", "Checking reasignment")
    if (currentWhepClientInstance != whepClient) {
      Log.d("Test", "Reasigning whep client")
      videoView?.let { view ->
        whepClient?.videoTrack?.removeSink(view)
        removeView(view)
      }
      videoView = null
      currentWhepClientInstance = whepClient
    }
  }

  private val currentActivity = appContext.throwingActivity
  private val decorView = currentActivity.window.decorView
  private val rootView = decorView.findViewById<ViewGroup>(android.R.id.content)
  private val rootViewChildrenOriginalVisibility: ArrayList<Int> = arrayListOf()
  private var pictureInPictureHelperTag: String? = null

  @RequiresApi(Build.VERSION_CODES.O)
  private var pictureInPictureParamsBuilder = PictureInPictureParams.Builder()

  @RequiresApi(Build.VERSION_CODES.O)
  fun setAspectRatio(rational: Rational) {
    pictureInPictureParamsBuilder.setAspectRatio(rational)
    updatePictureInPictureParams()
  }

  @RequiresApi(Build.VERSION_CODES.S)
  fun setAutoEnterEnabled(enabled: Boolean) {
    pictureInPictureParamsBuilder.setAutoEnterEnabled(enabled)
    updatePictureInPictureParams()
  }

  @RequiresApi(Build.VERSION_CODES.O)
  fun startPictureInPicture() {
    currentActivity.enterPictureInPictureMode(pictureInPictureParamsBuilder.build())
    updatePictureInPictureParams()
  }

  @RequiresApi(Build.VERSION_CODES.O)
  fun setPictureInPictureEnabled(enabled: Boolean) {
    if (!enabled) {
      pictureInPictureParamsBuilder = PictureInPictureParams.Builder()
      updatePictureInPictureParams()
    }
  }

  @RequiresApi(Build.VERSION_CODES.O)
  fun updatePictureInPictureParams() {
    currentActivity.setPictureInPictureParams(pictureInPictureParamsBuilder.build())
  }

  override fun onAttachedToWindow() {
    Log.d("Test", "On attached to window")
    super.onAttachedToWindow()

//    whepClient?.videoTrack?.let { track ->
//      Log.d("Test", "Whep client already has a track. Setting up")
//      setupTrack(track)
//    }

    (currentActivity as? FragmentActivity)?.let {
      val fragment = PictureInPictureHelperFragment(this)
      pictureInPictureHelperTag = fragment.id
      it.supportFragmentManager.beginTransaction()
        .add(fragment, fragment.id)
        .commitAllowingStateLoss()
    }
  }

  override fun onDetachedFromWindow() {
    super.onDetachedFromWindow()

    (currentActivity as? FragmentActivity)?.let {
      val fragment = it.supportFragmentManager.findFragmentByTag(pictureInPictureHelperTag ?: "")
        ?: return
      it.supportFragmentManager.beginTransaction()
        .remove(fragment)
        .commitAllowingStateLoss()
    }
  }

  fun cleanup() {
    Log.d("Test", "Cleanup in view")
    videoView?.let { view ->
      Log.d("Test", "Removing sink")
      whepClient?.videoTrack?.removeSink(view)
      removeView(view)
    }
    videoView = null
  }

  fun layoutForPiPEnter() {
    (videoView!!.parent as? ViewGroup)?.removeView(videoView)
    for (i in 0 until rootView.childCount) {
      if (rootView.getChildAt(i) != videoView) {
        rootViewChildrenOriginalVisibility.add(rootView.getChildAt(i).visibility)
        rootView.getChildAt(i).visibility = View.GONE
      }
    }
    rootView.addView(videoView, FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT))
  }

  fun layoutForPiPExit() {
    rootView.removeView(videoView)
    for (i in 0 until rootView.childCount) {
      rootView.getChildAt(i).visibility = rootViewChildrenOriginalVisibility[i]
    }
    rootViewChildrenOriginalVisibility.clear()
    this.addView(videoView)
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
