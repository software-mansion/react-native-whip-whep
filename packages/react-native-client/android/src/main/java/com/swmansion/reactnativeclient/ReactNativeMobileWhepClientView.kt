package com.swmansion.reactnativeclient

import android.app.PictureInPictureParams
import android.content.Context
import android.os.Build
import android.util.Rational
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import androidx.annotation.RequiresApi
import androidx.fragment.app.FragmentActivity
import com.mobilewhep.client.VideoView
import com.swmansion.reactnativeclient.ReactNativeMobileWhepClientModule.Companion.whepClient
import com.swmansion.reactnativeclient.ReactNativeMobileWhepClientModule.Companion.whipClient
import com.swmansion.reactnativeclient.helpers.PictureInPictureHelperFragment
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
  }

  @RequiresApi(Build.VERSION_CODES.S)
  fun setAutoEnterEnabled(enabled: Boolean) {
    pictureInPictureParamsBuilder.setAutoEnterEnabled(enabled)
  }

  @RequiresApi(Build.VERSION_CODES.O)
  fun startPictureInPicture() {
    appContext.currentActivity?.enterPictureInPictureMode(pictureInPictureParamsBuilder.build())
  }

  @RequiresApi(Build.VERSION_CODES.O)
  fun setPictureInPictureEnabled(enabled: Boolean) {
    if (!enabled) {
      pictureInPictureParamsBuilder = PictureInPictureParams.Builder()
    }

    appContext.currentActivity?.setPictureInPictureParams(pictureInPictureParamsBuilder.build())
  }

  override fun onAttachedToWindow() {
    super.onAttachedToWindow()
    (currentActivity as? FragmentActivity)?.let {
      val fragment = PictureInPictureHelperFragment(this)
      pictureInPictureHelperTag = fragment.id
      it.supportFragmentManager.beginTransaction()
        .add(fragment, fragment.id)
        .commitAllowingStateLoss()
    }
//    applyAutoEnterPiP(currentActivity, autoEnterPiP)
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
//    applyAutoEnterPiP(currentActivity, false)
  }

  /**
   * For optimal picture in picture experience it's best to only have one view. This method
   * hides all children of the root view and makes the player the only visible child of the rootView.
   */
  fun layoutForPiPEnter() {
    (videoView.parent as? ViewGroup)?.removeView(videoView)
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
