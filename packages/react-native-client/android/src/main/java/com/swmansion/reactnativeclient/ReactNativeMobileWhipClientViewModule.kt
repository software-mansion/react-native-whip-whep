package com.swmansion.reactnativeclient

import android.os.Build
import android.util.Rational
import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition

class ReactNativeMobileWhipClientViewModule : Module() {
  override fun definition() =
    ModuleDefinition {
      Name("ReactNativeMobileWhipClientViewModule")

      View(ReactNativeMobileWhipClientView::class) {
        Prop("playerType") { view: ReactNativeMobileWhipClientView, playerType: String ->
          view.init(playerType)
        }

        Prop("pipEnabled") { view: ReactNativeMobileWhipClientView, pipEnabled: Boolean ->
          if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            view.setPictureInPictureEnabled(pipEnabled)
          }
        }

        Prop("autoStartPip") { view: ReactNativeMobileWhipClientView, startAutomatically: Boolean ->
          if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            view.setAutoEnterEnabled(startAutomatically)
          }
        }

        Prop("autoStopPip") { _: ReactNativeMobileWhipClientView, _: Boolean -> }

        Prop("pipSize"){ view: ReactNativeMobileWhipClientView, size: PipSize ->
          if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            view.setAspectRatio(Rational(size.width, size.height))
          }
        }

        AsyncFunction("startPip") { view: ReactNativeMobileWhipClientView ->
          if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            view.startPictureInPicture()
          }
        }

        AsyncFunction("stopPip") { _: ReactNativeMobileWhipClientView -> }
        AsyncFunction("togglePip") { _: ReactNativeMobileWhipClientView -> }
      }
    }
}
