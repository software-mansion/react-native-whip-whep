package com.swmansion.reactnativeclient

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
      }
    }
}
