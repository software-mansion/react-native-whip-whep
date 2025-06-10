package com.swmansion.reactnativeclient

import android.util.Rational
import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition

class ReactNativeMobileWhepClientViewModule : Module() {
  override fun definition() =
    ModuleDefinition {
      Name("ReactNativeMobileWhepClientViewModule")

      View(ReactNativeMobileWhepClientView::class) {
        Prop("playerType") { view: ReactNativeMobileWhepClientView, playerType: String ->
          view.init(playerType)
        }

        Prop("orientation") { view: ReactNativeMobileWhepClientView, orientation: String ->
          view.setOrientation(if (orientation.lowercase() == "landscape") Orientation.LANDSCAPE else Orientation.PORTRAIT)
        }

        Prop("pipEnabled") { view: ReactNativeMobileWhepClientView, pipEnabled: Boolean ->
          view.pipEnabled = pipEnabled
        }
        Prop("autoStartPip") { view: ReactNativeMobileWhepClientView, startAutomatically: Boolean ->
          view.pipController?.startAutomatically = startAutomatically
        }
        Prop("autoStopPip") { view: ReactNativeMobileWhepClientView, stopAutomatically: Boolean ->
          view.pipController?.stopAutomatically = stopAutomatically
        }
        Prop("pipSize"){ view: ReactNativeMobileWhepClientView, size: IntArray ->
          view.pipController?.preferredSize = size
        }
      }
    }
}
