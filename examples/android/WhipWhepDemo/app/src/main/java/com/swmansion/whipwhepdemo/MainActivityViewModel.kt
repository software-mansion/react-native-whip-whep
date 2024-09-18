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

class MainActivityViewModel(
  application: Application
) : AndroidViewModel(application) {
  var isLoading = mutableStateOf(false)
  var shouldShowPlayBtn = mutableStateOf(true)
  var shouldShowStreamBtn = mutableStateOf(true)

  var whepClient: WhepClient? = null
  var whipClient: WhipClient? = null

  init {
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

      whipClient =
        WhipClient(
          appContext = getApplication<Application>().applicationContext,
          serverUrl =
          getApplication<Application>().applicationContext.getString(
            R.string.WHIP_SERVER_URL
          ),
          configurationOptions = ConfigurationOptions(authToken = "example"),
          videoDevice = WhipClient.getCaptureDevices(getApplication<Application>().applicationContext)
            .first().deviceName
        )
    } catch (e: Exception) {
      Log.e(TAG, "Error when creating client: ${e.message}")
    }
  }

  fun disconnect() {
    whepClient?.disconnect()
    whipClient?.disconnect()
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
