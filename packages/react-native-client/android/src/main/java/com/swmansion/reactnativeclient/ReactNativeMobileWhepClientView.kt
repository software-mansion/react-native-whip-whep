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
import com.mobilewhep.client.ClientBaseListener
import com.mobilewhep.client.ClientConnectOptions
import com.mobilewhep.client.ReconnectionManagerListener
import com.mobilewhep.client.VideoView
import com.mobilewhep.client.WhepClient
import com.mobilewhep.client.WhepConfigurationOptions
import com.swmansion.reactnativeclient.helpers.PictureInPictureHelperFragment
import expo.modules.kotlin.AppContext
import expo.modules.kotlin.views.ExpoView
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.webrtc.VideoTrack
import kotlin.text.get

class ReactNativeMobileWhepClientView(
  context: Context,
  appContext: AppContext,
) : ExpoView(context, appContext), ClientBaseListener {
  private var videoView: VideoView? = null
  private var whepClient: WhepClient? = null

  fun createWhepClient(configurationOptions: Map<String, Any>?, preferredVideoCodecs: List<String>?, preferredAudioCodecs: List<String>?) {
    val context: Context =
      appContext.reactContext ?: throw IllegalStateException("React context is not available")
    val options =
      WhepConfigurationOptions(
        stunServerUrl = configurationOptions?.get("stunServerUrl") as? String,
        audioEnabled = configurationOptions?.get("audioEnabled") as? Boolean ?: true,
        videoEnabled = configurationOptions?.get("videoEnabled") as? Boolean ?: true,
        preferredAudioCodecs = preferredAudioCodecs ?: listOf(),
        preferredVideoCodecs = preferredVideoCodecs ?: listOf()
      )
    whepClient = WhepClient(context, options)

    whepClient?.addTrackListener(this)
  }

  suspend fun connect(options: ConnectOptions)  {
    if (whepClient == null) {
      throw IllegalStateException("Connect called before whep client was created")
    }
    withContext(Dispatchers.IO) {
      whepClient?.connect(ClientConnectOptions(serverUrl = options.serverUrl, authToken = options.authToken))
    }
  }

  fun disconnect()  {
    whepClient?.disconnect()
  }

  fun pause()  {
    whepClient?.pause()
  }

  fun unpause()  {
    whepClient?.unpause()
  }

  fun setReconnectionListener(listener: ReconnectionManagerListener) {
    whepClient?.addReconnectionListener(listener)
  }

  fun setConnectionStateChangeListener(listener: ReactNativeMobileWhepClientViewModule.OnConnectionStateChangeListener) {
    whepClient?.onConnectionStateChanged = { newState ->
      CoroutineScope(Dispatchers.Main).launch {
        listener.onConnectionStateChange(newState)
      }
    }
  }

  private fun setupTrack(videoTrack: VideoTrack) {
    if (whepClient == null) {
      return
    }

    if (videoView == null) {
      videoView = VideoView(context, whepClient!!.eglBase)
      videoView!!.player = whepClient

      addView(videoView, FrameLayout.LayoutParams(
        ViewGroup.LayoutParams.MATCH_PARENT,
        ViewGroup.LayoutParams.MATCH_PARENT
      ))
    }

    videoView!!.post {
      // If VideoView has no dimensions, use parent dimensions
      if (videoView!!.width == 0 || videoView!!.height == 0) {
        val parentWidth = this@ReactNativeMobileWhepClientView.width
        val parentHeight = this@ReactNativeMobileWhepClientView.height
        if (parentWidth > 0 && parentHeight > 0) {
          videoView!!.layout(0, 0, parentWidth, parentHeight)
        }
      }

      videoView!!.player?.videoTrack?.removeSink(videoView)
      videoView!!.player?.videoTrack = videoTrack
      videoTrack.addSink(videoView)
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
    super.onAttachedToWindow()

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

    videoView?.let { view ->
      whepClient?.videoTrack?.removeSink(view)
      removeView(view)
    }
    videoView = null

    val client = whepClient
    whepClient = null
    CoroutineScope(Dispatchers.IO).launch {
      client?.cleanup()
    }

    (currentActivity as? FragmentActivity)?.let {
      val fragment = it.supportFragmentManager.findFragmentByTag(pictureInPictureHelperTag ?: "")
        ?: return
      it.supportFragmentManager.beginTransaction()
        .remove(fragment)
        .commitAllowingStateLoss()
    }
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

  override fun onTrackAdded(track: VideoTrack) {
    update(track)
  }
}
