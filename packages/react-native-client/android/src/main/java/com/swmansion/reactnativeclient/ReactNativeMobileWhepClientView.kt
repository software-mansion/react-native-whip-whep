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
  private var pendingVideoTrack: org.webrtc.VideoTrack? = null

  init {
    ReactNativeMobileWhepClientViewModule.onWhepTrackUpdateListeners.add(this)
  }
  
  private fun ensureVideoViewCreated() {
    if (videoView != null) {
      Log.d("ReactNativeMobileWhepClientView", "VideoView already exists")
      return
    }
    if (whepClient == null) {
      Log.e("ReactNativeMobileWhepClientView", "Cannot create VideoView: whepClient is null")
      return
    }
    
    Log.d("ReactNativeMobileWhepClientView", "Creating VideoView, parent dimensions: ${width}x${height}")
    videoView = VideoView(context, whepClient!!.eglBase)
    
    addView(videoView, FrameLayout.LayoutParams(
      ViewGroup.LayoutParams.MATCH_PARENT,
      ViewGroup.LayoutParams.MATCH_PARENT
    ))
    
    // Force layout the VideoView with parent's dimensions if available
    if (width > 0 && height > 0) {
      videoView!!.measure(
        View.MeasureSpec.makeMeasureSpec(width, View.MeasureSpec.EXACTLY),
        View.MeasureSpec.makeMeasureSpec(height, View.MeasureSpec.EXACTLY)
      )
      videoView!!.layout(0, 0, width, height)
      Log.d("ReactNativeMobileWhepClientView", "VideoView laid out with parent dimensions: ${width}x${height}")
    }
    
    Log.d("ReactNativeMobileWhepClientView", "VideoView created and added to hierarchy")
    
    // Wait for the TextureView surface to be ready, then set the player
    videoView!!.post {
      val isAvailable = videoView!!.isAvailable
      Log.d("ReactNativeMobileWhepClientView", "Post executed, surface available: $isAvailable")
      
      if (isAvailable) {
        // Surface is already available - set player immediately
        Log.d("ReactNativeMobileWhepClientView", "Surface already available, setting player now")
        videoView!!.player = whepClient
        // Add a small delay to ensure EGL renderer is fully initialized
        videoView!!.postDelayed({
          pendingVideoTrack?.let { track ->
            Log.d("ReactNativeMobileWhepClientView", "Setting up pending track after EGL init")
            setupVideoTrackSafely(track)
            pendingVideoTrack = null
          }
        }, 50)
      } else {
        // Surface not ready - wait for it
        Log.d("ReactNativeMobileWhepClientView", "Surface not available yet, setting up listener")
        val originalListener = videoView!!.surfaceTextureListener
        videoView!!.surfaceTextureListener = object : android.view.TextureView.SurfaceTextureListener {
          override fun onSurfaceTextureAvailable(surface: android.graphics.SurfaceTexture, width: Int, height: Int) {
            Log.d("ReactNativeMobileWhepClientView", "Surface texture available: ${width}x${height}")
            originalListener?.onSurfaceTextureAvailable(surface, width, height)
            videoView!!.player = whepClient
            Log.d("ReactNativeMobileWhepClientView", "Player set")
            pendingVideoTrack?.let { track ->
              Log.d("ReactNativeMobileWhepClientView", "Setting up pending video track after surface ready")
              setupVideoTrackSafely(track)
              pendingVideoTrack = null
            }
          }

          override fun onSurfaceTextureSizeChanged(surface: android.graphics.SurfaceTexture, width: Int, height: Int) {
            originalListener?.onSurfaceTextureSizeChanged(surface, width, height)
          }

          override fun onSurfaceTextureDestroyed(surface: android.graphics.SurfaceTexture): Boolean {
            return originalListener?.onSurfaceTextureDestroyed(surface) ?: true
          }

          override fun onSurfaceTextureUpdated(surface: android.graphics.SurfaceTexture) {
            originalListener?.onSurfaceTextureUpdated(surface)
          }
        }
      }
    }
  }

  private fun setupTrack(videoTrack: VideoTrack) {
    if (whepClient == null) {
      Log.e("ReactNativeMobileWhepClientView", "Setup track called without WHEP client.")
      return
    }
    
    Log.d("ReactNativeMobileWhepClientView", "setupTrack called with videoTrack: $videoTrack")
    
    ensureVideoViewCreated()
    
    // Store the track - it will be set up when the surface is ready
    Log.d("ReactNativeMobileWhepClientView", "Storing pending track")
    pendingVideoTrack = videoTrack
  }
  
  private fun setupVideoTrackSafely(videoTrack: VideoTrack) {
    try {
      Log.d("ReactNativeMobileWhepClientView", "Setting up video track sink")
      videoView!!.player?.videoTrack?.removeSink(videoView)
      videoView!!.player?.videoTrack = videoTrack
      videoTrack.addSink(videoView)
      Log.d("ReactNativeMobileWhepClientView", "Video track sink added successfully")
    } catch (e: Exception) {
      Log.e("ReactNativeMobileWhepClientView", "Error setting up video track: ${e.message}", e)
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
    
    // Clean up video view
    videoView?.let { view ->
      view.player?.videoTrack?.removeSink(view)
      view.release()
    }
    videoView = null
    pendingVideoTrack = null
    
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

  override fun onTrackUpdate(track: VideoTrack) {
    update(track)
  }
}
