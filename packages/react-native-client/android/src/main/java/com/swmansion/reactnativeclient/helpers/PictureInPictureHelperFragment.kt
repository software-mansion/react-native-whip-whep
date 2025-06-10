package com.swmansion.reactnativeclient.helpers

import androidx.fragment.app.Fragment
import com.mobilewhep.client.VideoView
import com.swmansion.reactnativeclient.ReactNativeMobileWhepClientView
import java.util.UUID

class PictureInPictureHelperFragment(private val videoView: ReactNativeMobileWhepClientView) : Fragment() {
  val id = "${PictureInPictureHelperFragment::class.java.simpleName}_${UUID.randomUUID()}"

  override fun onPictureInPictureModeChanged(isInPictureInPictureMode: Boolean) {
    super.onPictureInPictureModeChanged(isInPictureInPictureMode)

    if (isInPictureInPictureMode) {
      // We can't reliably detect when the PiP transition starts (while keeping the transition smooth 🙄), so we have to
      // unpause the playback after the onPause event, is called right after onPause. So the pause is not noticeable
//      if (videoView.wasAutoPaused) {
//        videoView.playerView.player?.play()
//      }
      videoView.layoutForPiPEnter()
//      videoView.onPictureInPictureStart(Unit)
    } else {
//      videoView.willEnterPiP = false
      videoView.layoutForPiPExit()
//      videoView.onPictureInPictureStop(Unit)
    }
  }
}
