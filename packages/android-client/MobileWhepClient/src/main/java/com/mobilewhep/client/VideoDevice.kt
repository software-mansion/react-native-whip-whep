package com.mobilewhep.client

import org.webrtc.CameraEnumerator

data class VideoDevice(
  val cameraEnumerator: CameraEnumerator,
  val deviceName: String
)
