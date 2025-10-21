package com.swmansion.reactnativeclient

import android.content.Context
import android.os.Build
import android.util.Log
import android.util.Rational
import com.mobilewhep.client.ClientBaseListener
import com.mobilewhep.client.ClientConnectOptions
import com.mobilewhep.client.ReconnectionManagerListener
import com.mobilewhep.client.WhepClient
import com.mobilewhep.client.WhepConfigurationOptions
import expo.modules.kotlin.functions.Coroutine
import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition
import expo.modules.kotlin.records.Field
import expo.modules.kotlin.records.Record
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.webrtc.VideoTrack

class PipSize : Record {
  @Field
  val width: Int = 0

  @Field
  val height: Int = 0
}

class ConnectOptions: Record {
  @Field
  val serverUrl: String = ""

  @Field
  val authToken: String? = null
}

class ReactNativeMobileWhepClientViewModule : Module(), ReconnectionManagerListener {
  interface OnTrackUpdateListener {
    fun onTrackUpdate(track: VideoTrack)
  }

  interface OnCleanupListener {
    suspend fun onCleanup()
  }

  private var whepClient: WhepClient? = null
  private var onWhepTrackUpdateListeners: MutableList<OnTrackUpdateListener> = mutableListOf()
  private var onCleanupListener: OnCleanupListener? = null

  fun emit(event: EmitableEvent) {
    sendEvent(event.name, event.data)
  }


  override fun onReconnectionStarted() {
    super.onReconnectionStarted()
    emit(WhepEmitableEvent.reconnectionStatusChanged(ReconnectionStatus.ReconnectionStarted))
  }

  override fun onReconnected() {
    super.onReconnected()
    emit(WhepEmitableEvent.reconnectionStatusChanged(ReconnectionStatus.Reconnected))
  }

  override fun onReconnectionRetriesLimitReached() {
    super.onReconnectionRetriesLimitReached()
    emit(WhepEmitableEvent.reconnectionStatusChanged(ReconnectionStatus.ReconnectionRetriesLimitReached))
  }

  override fun definition() =
    ModuleDefinition {
      Name("ReactNativeMobileWhepClientViewModule")

      Events(WhepEmitableEvent.allEvents)

      View(ReactNativeMobileWhepClientView::class) {
        Prop("pipEnabled") { view: ReactNativeMobileWhepClientView, pipEnabled: Boolean ->
          if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            view.setPictureInPictureEnabled(pipEnabled)
          }
        }

        Prop("autoStartPip") { view: ReactNativeMobileWhepClientView, startAutomatically: Boolean ->
          if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            view.setAutoEnterEnabled(startAutomatically)
          }
        }

        Prop("autoStopPip") { _: ReactNativeMobileWhepClientView, _: Boolean -> }

        Prop("pipSize"){ view: ReactNativeMobileWhepClientView, size: PipSize ->
          if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            view.setAspectRatio(Rational(size.width, size.height))
          }
        }

        AsyncFunction("createWhepClient") { view: ReactNativeMobileWhepClientView, configurationOptions: Map<String, Any>?, preferredVideoCodecs: List<String>?, preferredAudioCodecs: List<String>? ->
          val context: Context =
            appContext.reactContext ?: throw IllegalStateException("React context is not available")
          Log.d("Test", "Creating whep client")
          val options =
            WhepConfigurationOptions(
              stunServerUrl = configurationOptions?.get("stunServerUrl") as? String,
              audioEnabled = configurationOptions?.get("audioEnabled") as? Boolean ?: true,
              videoEnabled = configurationOptions?.get("videoEnabled") as? Boolean ?: true,
              preferredAudioCodecs = preferredAudioCodecs ?: listOf(),
              preferredVideoCodecs = preferredVideoCodecs ?: listOf()
            )
          onWhepTrackUpdateListeners.add(view)
          whepClient = WhepClient(context, options)
          whepClient?.addReconnectionListener(this@ReactNativeMobileWhepClientViewModule)
          whepClient?.addTrackListener(object :
            ClientBaseListener {
            override fun onTrackAdded(track: VideoTrack) {
              Log.d("Test", "Track added, calling listeners: $onWhepTrackUpdateListeners")
              onWhepTrackUpdateListeners.forEach { it.onTrackUpdate(track) }
            }
          })
          whepClient?.onConnectionStateChanged = { newState ->
            emit(WhepEmitableEvent.whepPeerConnectionStateChanged(newState))
          }
          view.setWhepClient(whepClient!!)
          view.setCleanupListener(object : OnCleanupListener {
            override suspend fun onCleanup() {
              Log.d("Test", "Cleanup listener called from view detachment")
              whepClient?.let { client ->
                client.disconnect()
                client.removeReconnectionListener(this@ReactNativeMobileWhepClientViewModule)
                client.removeTrackListeners()
                client.eglBase?.release()
              }
              onWhepTrackUpdateListeners.clear()
              whepClient = null
            }
          })
          Log.d("Test", "Finished creating client")
        }

        AsyncFunction("connect") Coroutine { options: ConnectOptions ->
          Log.d("Test", "Connecting in module")
          if (whepClient == null) {
            throw IllegalStateException("React context is not available")
          }
          withContext(Dispatchers.IO) {
            whepClient?.connect(ClientConnectOptions(serverUrl = options.serverUrl, authToken = options.authToken))
          }
        }

        AsyncFunction("disconnect") Coroutine { ->
          whepClient?.disconnect()
        }

        AsyncFunction("cleanup") Coroutine { view: ReactNativeMobileWhepClientView ->
          Log.d("Test", "Cleaning up whep client")
          whepClient?.let { client ->
            client.disconnect()
            client.removeReconnectionListener(this@ReactNativeMobileWhepClientViewModule)
            client.removeTrackListeners()
            client.eglBase?.release()
          }
          onWhepTrackUpdateListeners.clear()
          whepClient = null
        }

        AsyncFunction("pause") {
          whepClient?.pause()
        }

        AsyncFunction("unpause") {
          whepClient?.unpause()
        }

        AsyncFunction("startPip") { view: ReactNativeMobileWhepClientView ->
          if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            view.startPictureInPicture()
          }
        }

        AsyncFunction("stopPip") { _: ReactNativeMobileWhepClientView -> }
        AsyncFunction("togglePip") { _: ReactNativeMobileWhepClientView -> }
      }
    }
}
