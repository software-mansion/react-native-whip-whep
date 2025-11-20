package com.swmansion.reactnativeclient.foregroundService

import android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION
import expo.modules.kotlin.AppContext

data class ForegroundServiceState(
  var screenSharingEnabled: Boolean = false,
  var channelId: String = "com.swmansion.whipwhep.foregroundservice.channel",
  var channelName: String = "WhipWhep Notifications",
  var notificationContent: String = "Your screen share is active",
  var notificationTitle: String = "Tap to return to the call."
) {
  fun buildForegroundServiceTypes(appContext: AppContext): List<Int> =
    buildList {
      if (screenSharingEnabled) add(FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION)
    }
}

