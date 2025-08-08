package com.mobilewhep.client

data class ClientConnectOptions(
  val serverUrl: String,
  val authToken: String? = null
)
