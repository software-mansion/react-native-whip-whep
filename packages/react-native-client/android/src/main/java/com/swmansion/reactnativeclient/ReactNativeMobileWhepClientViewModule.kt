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
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withContext
import org.webrtc.PeerConnection
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

  interface OnConnectionStateChangeListener {
    suspend fun onConnectionStateChange(newState: PeerConnection.PeerConnectionState)
  }

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
        OnViewDestroys  { view: ReactNativeMobileWhepClientView ->
          runBlocking {
            view.cleanup()
          }
        }

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
          view.createWhepClient(configurationOptions, preferredVideoCodecs, preferredAudioCodecs)
          view.setReconnectionListener(this@ReactNativeMobileWhepClientViewModule)
          view.setConnectionStateChangeListener(object : OnConnectionStateChangeListener {
            override suspend fun onConnectionStateChange(newState: PeerConnection.PeerConnectionState) {
              emit(WhepEmitableEvent.whepPeerConnectionStateChanged(newState))
            }
          })
        }

        AsyncFunction("connect") Coroutine { view: ReactNativeMobileWhepClientView, options: ConnectOptions ->
          view.connect(options)
        }

        AsyncFunction("disconnect") Coroutine { view: ReactNativeMobileWhepClientView ->
          view.disconnect()
        }

        AsyncFunction("pause") { view: ReactNativeMobileWhepClientView ->
          view.pause()
        }

        AsyncFunction("unpause") { view: ReactNativeMobileWhepClientView ->
          view.unpause()
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
