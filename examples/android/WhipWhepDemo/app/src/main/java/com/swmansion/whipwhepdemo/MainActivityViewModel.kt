package com.swmansion.whipwhepdemo

import android.app.Application
import android.util.Log
import androidx.compose.runtime.mutableStateOf
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.mobilewhep.client.ConfigurationOptions
import com.mobilewhep.client.WhepClient
import com.mobilewhep.client.WhipClient
import kotlinx.coroutines.launch

const val TAG = "WHEP_EXAMPLE"

enum class Tabs {
  WHEP_BROADCASTER_TAB,
  WHEP_TAB,
  WHIP_TAB
}

class MainActivityViewModel(
  application: Application
) : AndroidViewModel(application) {
  var isLoading = mutableStateOf(false)
  var shouldShowPlayBtn = mutableStateOf(true)
  var shouldShowStreamBtn = mutableStateOf(true)
  var selectedTabIndex = mutableStateOf(Tabs.WHEP_BROADCASTER_TAB)

  var whepBroadcaster: WhepClient? = null
  var whepClient: WhepClient? = null
  var whipClient: WhipClient? = null

  init {
    createWhepBroadcasterClient()
  }

  private fun createWhepBroadcasterClient() {
    try {
      whepBroadcaster =
        WhepClient(
          appContext = getApplication<Application>().applicationContext,
          serverUrl = "https://broadcaster.elixir-webrtc.org/api/whep",
          configurationOptions =
            ConfigurationOptions(
              authToken = "example"
            )
        )
    } catch (e: Exception) {
      Log.e(TAG, "Error when creating client: ${e.message}")
    }
  }

  private fun createWhepClient() {
    try {
      whepClient =
        WhepClient(
          appContext = getApplication<Application>().applicationContext,
          serverUrl = getApplication<Application>().applicationContext.getString(R.string.WHEP_SERVER_URL),
          configurationOptions =
            ConfigurationOptions(
              authToken = "example"
            )
        )
    } catch (e: Exception) {
      Log.e(TAG, "Error when creating client: ${e.message}")
    }
  }

  private fun createWhipClient() {
    try {
      whipClient =
        WhipClient(
          appContext = getApplication<Application>().applicationContext,
          serverUrl =
            getApplication<Application>().applicationContext.getString(
              R.string.WHIP_SERVER_URL
            ),
          configurationOptions = ConfigurationOptions(authToken = "example"),
          videoDevice =
            WhipClient.getCaptureDevices(getApplication<Application>().applicationContext)
              .first().deviceName
        )
    } catch (e: Exception) {
      Log.e(TAG, "Error when creating client: ${e.message}")
    }
  }

  fun switchTab(tab: Tabs) {
    whepBroadcaster?.disconnect()
    whepBroadcaster = null
    whipClient?.disconnect()
    whipClient = null
    whepClient?.disconnect()
    whepClient = null

    when (tab) {
      Tabs.WHEP_BROADCASTER_TAB -> createWhepBroadcasterClient()
      Tabs.WHEP_TAB -> createWhepClient()
      Tabs.WHIP_TAB -> createWhipClient()
    }

    shouldShowPlayBtn.value = true
    shouldShowStreamBtn.value = true
    isLoading.value = false
    selectedTabIndex.value = tab
  }

  fun disconnect() {
    whepBroadcaster?.disconnect()
    whepClient?.disconnect()
    whipClient?.disconnect()
  }

  fun onBroadcasterPlay() {
    shouldShowPlayBtn.value = false
    isLoading.value = true
    whepBroadcaster?.onTrackAdded = { isLoading.value = false }
    viewModelScope.launch {
      whepBroadcaster?.connect()
    }
  }

  fun onPlay() {
    shouldShowPlayBtn.value = false
    isLoading.value = true
    whepClient?.onTrackAdded = { isLoading.value = false }
    viewModelScope.launch {
      whepClient?.connect()
    }
  }

  fun onStream() {
    shouldShowStreamBtn.value = false
    viewModelScope.launch {
      whipClient?.connect()
    }
  }
}
