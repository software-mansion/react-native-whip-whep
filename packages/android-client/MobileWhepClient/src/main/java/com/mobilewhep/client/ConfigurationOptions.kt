package com.mobilewhep.client

data class ConfigurationOptions(
  val authToken: String? = null,
  val stunServerUrl: String? = null,
  val videoSize: VideoSize? = VideoSize.HD
)
