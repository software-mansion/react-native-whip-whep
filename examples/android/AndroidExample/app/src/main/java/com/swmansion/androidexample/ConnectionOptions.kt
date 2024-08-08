package com.swmansion.androidexample

data class ConnectionOptions(
  val serverUrl: String,
  val whepEndpoint: String,
  val authToken: String? = null
)