package com.swmansion.whipwhepdemo

import android.app.Application
import android.util.Log
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.mobilewhep.client.ClientConnectOptions
import com.mobilewhep.client.VideoView
import com.mobilewhep.client.WhepClient
import com.mobilewhep.client.WhepConfigurationOptions
import com.mobilewhep.client.WhipClient
import com.mobilewhep.client.WhipConfigurationOptions
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

const val TAG = "WHEP_EXAMPLE"

const val AUTH_TOKEN = "example"

const val BROADCASTER_SERVER_URL = "https://broadcaster.elixir-webrtc.org/api/whep"

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

  // Observable so that the composables gating the video views on a non-null client actually
  // recompose when a client is created or torn down.
  var whepBroadcaster by mutableStateOf<WhepClient?>(null)
    private set
  var whepClient by mutableStateOf<WhepClient?>(null)
    private set
  var whipClient by mutableStateOf<WhipClient?>(null)
    private set

  // The server URL is no longer part of the client configuration - it is passed on connect.
  private var whepBroadcasterConnectOptions: ClientConnectOptions? = null
  private var whepConnectOptions: ClientConnectOptions? = null
  private var whipConnectOptions: ClientConnectOptions? = null

  /**
   * Every create and every teardown goes through this one job chain. Serializing them keeps two
   * rapid tab taps - or a teardown racing the recreation that follows a configuration change -
   * from interleaving and nulling out the client the finally selected tab needs.
   */
  private var clientJob: Job? = null

  /**
   * The chain has to outlive [viewModelScope]: the composition is disposed and the ViewModel
   * cleared in the same breath when the Activity goes away, so work launched on
   * [viewModelScope] would be cancelled before it released anything.
   */
  private val clientScope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)

  /**
   * The renderer currently attached to the live client. Compose only disposes the `AndroidView`
   * on a later frame, so [tearDownClients] releases it by hand: `cleanup()` releases the shared
   * `EglBase`, and a still-attached `SurfaceEglRenderer` would then be holding an EGL surface on
   * a released context.
   */
  private var videoView: VideoView? = null

  fun onVideoViewCreated(view: VideoView) {
    videoView = view
  }

  fun onVideoViewReleased(view: VideoView) {
    if (videoView === view) {
      videoView = null
    }
  }

  private fun createWhepBroadcasterClient() {
    try {
      whepBroadcaster =
        WhepClient(
          appContext = getApplication<Application>().applicationContext,
          configurationOptions =
            WhepConfigurationOptions(
              preferredVideoCodecs = listOf(),
              preferredAudioCodecs = listOf()
            )
        )
      whepBroadcasterConnectOptions =
        ClientConnectOptions(
          serverUrl = BROADCASTER_SERVER_URL,
          authToken = AUTH_TOKEN
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
          configurationOptions =
            WhepConfigurationOptions(
              preferredVideoCodecs = listOf(),
              preferredAudioCodecs = listOf()
            )
        )
      whepConnectOptions =
        ClientConnectOptions(
          serverUrl = getApplication<Application>().applicationContext.getString(R.string.WHEP_SERVER_URL),
          authToken = AUTH_TOKEN
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
          configOptions =
            WhipConfigurationOptions(
              videoDevice =
                WhipClient
                  .getCaptureDevices(getApplication<Application>().applicationContext)
                  .first()
                  .deviceName,
              preferredVideoCodecs = listOf(),
              preferredAudioCodecs = listOf()
            )
        )
      whipConnectOptions =
        ClientConnectOptions(
          serverUrl =
            getApplication<Application>().applicationContext.getString(
              R.string.WHIP_SERVER_URL
            ),
          authToken = AUTH_TOKEN
        )
    } catch (e: Exception) {
      Log.e(TAG, "Error when creating client: ${e.message}")
    }
  }

  /**
   * Client teardown and connection are best-effort: the WHIP resource DELETE is not implemented by
   * every server (the ex_webrtc demo server answers 404), and disconnecting a client that was never
   * connected throws as well. Without this guard the exception escapes the enclosing scope and
   * crashes the app.
   */
  private suspend fun runCatchingClient(
    action: String,
    block: suspend () -> Unit
  ): Boolean =
    try {
      block()
      true
    } catch (e: CancellationException) {
      // Never swallow cancellation - it has to reach the enclosing coroutine.
      throw e
    } catch (e: Exception) {
      Log.w(TAG, "Error when trying to $action: ${e.message}")
      false
    }

  /**
   * [WhepClient.cleanup] / [WhipClient.cleanup] - not `disconnect()` - are what release the EGL
   * context, the peer connection factory, the tracks and (for WHIP) the camera capturer. Dropping
   * the reference after a bare `disconnect()` leaks all of them and leaves the camera running.
   */
  private suspend fun tearDownClients() {
    // Idempotent - Compose calls it again from `onRelease` once it gets around to disposing.
    videoView?.release()
    videoView = null

    whepBroadcaster?.let { client ->
      runCatchingClient("clean up the WHEP broadcaster") { client.cleanup() }
    }
    whepBroadcaster = null

    whepClient?.let { client ->
      runCatchingClient("clean up the WHEP client") { client.cleanup() }
    }
    whepClient = null

    whipClient?.let { client ->
      // WhipClient.cleanup() does not release the WHIP resource on the server - disconnect() does.
      runCatchingClient("disconnect the WHIP client") { client.disconnect() }
      runCatchingClient("clean up the WHIP client") { client.cleanup() }
    }
    whipClient = null
  }

  fun switchTab(tab: Tabs) {
    if (selectedTabIndex.value == tab) return

    // Only the tab state is flipped here, so the tab bar follows the tap instead of waiting for
    // the teardown round-trips (the resource DELETE can 404 or hang, depending on the server).
    // Swapping the client is left to [prepareClientForSelectedTab], driven by the composition.
    selectedTabIndex.value = tab
    shouldShowPlayBtn.value = true
    shouldShowStreamBtn.value = true
    isLoading.value = false
  }

  /**
   * Creating the client is driven by the composition rather than by [switchTab] alone: this
   * ViewModel outlives the Activity, so after a configuration change the composition comes back
   * with every client already released and has to ask for a fresh one.
   */
  fun prepareClientForSelectedTab() {
    val tab = selectedTabIndex.value
    val previous = clientJob
    clientJob =
      clientScope.launch {
        previous?.join()
        tearDownClients()

        when (tab) {
          Tabs.WHEP_BROADCASTER_TAB -> createWhepBroadcasterClient()
          Tabs.WHEP_TAB -> createWhepClient()
          Tabs.WHIP_TAB -> createWhipClient()
        }
      }
  }

  fun releaseClients() {
    val previous = clientJob
    clientJob =
      clientScope.launch {
        previous?.join()
        tearDownClients()
      }
  }

  fun onBroadcasterPlay() {
    val client = whepBroadcaster
    val connectOptions = whepBroadcasterConnectOptions
    if (client == null || connectOptions == null) {
      Log.e(TAG, "Cannot connect the WHEP broadcaster: the client was not created")
      return
    }

    shouldShowPlayBtn.value = false
    isLoading.value = true
    client.onTrackAdded = { isLoading.value = false }
    viewModelScope.launch {
      val connected = runCatchingClient("connect the WHEP broadcaster") { client.connect(connectOptions) }
      if (!connected) {
        shouldShowPlayBtn.value = true
        isLoading.value = false
      }
    }
  }

  fun onPlay() {
    val client = whepClient
    val connectOptions = whepConnectOptions
    if (client == null || connectOptions == null) {
      Log.e(TAG, "Cannot connect the WHEP client: the client was not created")
      return
    }

    shouldShowPlayBtn.value = false
    isLoading.value = true
    client.onTrackAdded = { isLoading.value = false }
    viewModelScope.launch {
      val connected = runCatchingClient("connect the WHEP client") { client.connect(connectOptions) }
      if (!connected) {
        shouldShowPlayBtn.value = true
        isLoading.value = false
      }
    }
  }

  fun onStream() {
    val client = whipClient
    val connectOptions = whipConnectOptions
    if (client == null || connectOptions == null) {
      Log.e(TAG, "Cannot connect the WHIP client: the client was not created")
      return
    }

    shouldShowStreamBtn.value = false
    viewModelScope.launch {
      val connected = runCatchingClient("connect the WHIP client") { client.connect(connectOptions) }
      if (!connected) {
        shouldShowStreamBtn.value = true
      }
    }
  }
}
