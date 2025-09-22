package com.swmansion.reactnativeclient.helpers

import androidx.fragment.app.Fragment
import com.swmansion.reactnativeclient.ReactNativeMobileWhepClientView
import com.swmansion.reactnativeclient.ReactNativeMobileWhipClientView
import java.util.UUID

class PictureInPictureHelperFragment(private val videoView: ReactNativeMobileWhepClientView) : Fragment() {
  val id = "${PictureInPictureHelperFragment::class.java.simpleName}_${UUID.randomUUID()}"

  override fun onPictureInPictureModeChanged(isInPictureInPictureMode: Boolean) {
    super.onPictureInPictureModeChanged(isInPictureInPictureMode)

    if (isInPictureInPictureMode) {
      videoView.layoutForPiPEnter()
    } else {
      videoView.layoutForPiPExit()
    }
  }
}


class PictureInPictureWhipHelperFragment(private val videoView: ReactNativeMobileWhipClientView) : Fragment() {
  val id = "${PictureInPictureHelperFragment::class.java.simpleName}_${UUID.randomUUID()}"

  override fun onPictureInPictureModeChanged(isInPictureInPictureMode: Boolean) {
    super.onPictureInPictureModeChanged(isInPictureInPictureMode)

    if (isInPictureInPictureMode) {
      videoView.layoutForPiPEnter()
    } else {
      videoView.layoutForPiPExit()
    }
  }
}
