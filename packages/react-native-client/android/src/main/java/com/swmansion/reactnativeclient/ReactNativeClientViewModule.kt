package com.swmansion.reactnativeclient

import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition

class ReactNativeClientViewModule : Module() {
  override fun definition() =
    ModuleDefinition {
      Name("ReactNativeClientViewModule")

      View(ReactNativeClientView::class) {

        Prop("trackId") { view: ReactNativeClientView, trackId: String ->
          view.init(trackId)
        }
      }
    }
}
