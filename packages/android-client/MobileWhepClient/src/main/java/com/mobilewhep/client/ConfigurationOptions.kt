package com.mobilewhep.client

data class ConfigurationOptions(
  val authToken: String? = null,
  val stunServerUrl: String? = null,
  val videoParameters: VideoParameters? = VideoParameters.presetHD43
)
