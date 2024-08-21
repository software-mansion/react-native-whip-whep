package com.mobilewhep.client

data class ConfigurationOptions(
  val authToken: String? = null,
  val stunServerUrl: String? = null,
  val audioOnly: Boolean? = false,
  val videoOnly: Boolean? = false
)
