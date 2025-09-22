package com.swmansion.reactnativeclient

import android.os.Build
import android.util.Rational
import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition
import expo.modules.kotlin.records.Field
import expo.modules.kotlin.records.Record

class PipSize : Record {
  @Field
  val width: Int = 0

  @Field
  val height: Int = 0
}

class ReactNativeMobileWhepClientViewModule : Module() {
  override fun definition() =
    ModuleDefinition {
      Name("ReactNativeMobileWhepClientViewModule")

      View(ReactNativeMobileWhepClientView::class) {
        Prop("pipEnabled") { view: ReactNativeMobileWhepClientView, pipEnabled: Boolean ->
          if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            view.setPictureInPictureEnabled(pipEnabled)
          }
        }

        Prop("autoStartPip") { view: ReactNativeMobileWhepClientView, startAutomatically: Boolean ->
          if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            view.setAutoEnterEnabled(startAutomatically)
          }
        }

        Prop("autoStopPip") { _: ReactNativeMobileWhepClientView, _: Boolean -> }

        Prop("pipSize"){ view: ReactNativeMobileWhepClientView, size: PipSize ->
          if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            view.setAspectRatio(Rational(size.width, size.height))
          }
        }

        AsyncFunction("startPip") { view: ReactNativeMobileWhepClientView ->
          if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            view.startPictureInPicture()
          }
        }

        AsyncFunction("stopPip") { _: ReactNativeMobileWhepClientView -> }
        AsyncFunction("togglePip") { _: ReactNativeMobileWhepClientView -> }
      }
    }
}
