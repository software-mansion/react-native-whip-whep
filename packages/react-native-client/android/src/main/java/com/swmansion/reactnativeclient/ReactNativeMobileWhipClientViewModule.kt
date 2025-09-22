package com.swmansion.reactnativeclient

import android.os.Build
import android.util.Rational
import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition

class ReactNativeMobileWhipClientViewModule : Module() {
  override fun definition() =
    ModuleDefinition {
      Name("ReactNativeMobileWhipClientViewModule")

      View(ReactNativeMobileWhipClientView::class) {}
    }
}
