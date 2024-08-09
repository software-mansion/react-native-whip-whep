package com.swmansion.whipwhepdemo

data class ConnectionOptions(
  val serverUrl: String,
  val authToken: String? = null
)
