package com.swmansion.reactnativeclient

import android.content.Context
import android.os.Build
import android.util.Rational
import com.mobilewhep.client.ClientBaseListener
import com.mobilewhep.client.ClientConnectOptions
import com.mobilewhep.client.ReconnectionManagerListener
import com.mobilewhep.client.WhepClient
import com.mobilewhep.client.WhepConfigurationOptions
import com.swmansion.reactnativeclient.ReactNativeMobileWhepClientModule.Companion
import expo.modules.kotlin.functions.Coroutine
import expo.modules.kotlin.jni.JavaScriptValue
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

  companion object {
    var onWhepTrackUpdateListeners: MutableList<OnTrackUpdateListener> = mutableListOf()
    var whepClient: WhepClient? = null
  }

  fun emit(event: EmitableEvent) {
    sendEvent(event.name, event.data)
  }


  override fun onReconnectionStarted() {
    super.onReconnectionStarted()
    emit(EmitableEvent.reconnectionStatusChanged(ReconnectionStatus.ReconnectionStarted))
  }

  override fun onReconnected() {
    super.onReconnected()
    emit(EmitableEvent.reconnectionStatusChanged(ReconnectionStatus.Reconnected))
  }

  override fun onReconnectionRetriesLimitReached() {
    super.onReconnectionRetriesLimitReached()
    emit(EmitableEvent.reconnectionStatusChanged(ReconnectionStatus.ReconnectionRetriesLimitReached))
  }

  override fun definition() =
    ModuleDefinition {
      Name("ReactNativeMobileWhepClientViewModule")

      Events(EmitableEvent.allEvents)

      View(ReactNativeMobileWhepClientView::class) {
        Prop("playerType") { view: ReactNativeMobileWhepClientView, playerType: String ->
          view.init(playerType)
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

        AsyncFunction("createWhepClient") { configurationOptions: Map<String, Any>?, preferredVideoCodecs: List<String>?, preferredAudioCodecs: List<String>? ->
          val context: Context =
            appContext.reactContext ?: throw IllegalStateException("React context is not available")
          val options =
            WhepConfigurationOptions(
              stunServerUrl = configurationOptions?.get("stunServerUrl") as? String,
              audioEnabled = configurationOptions?.get("audioEnabled") as? Boolean ?: true,
              videoEnabled = configurationOptions?.get("videoEnabled") as? Boolean ?: true,
              preferredAudioCodecs = preferredAudioCodecs ?: listOf(),
              preferredVideoCodecs = preferredVideoCodecs ?: listOf()
            )
          whepClient = WhepClient(context, options)
          whepClient?.addReconnectionListener(this@ReactNativeMobileWhepClientViewModule)
          whepClient?.addTrackListener(object :
            ClientBaseListener {
            override fun onTrackAdded(track: VideoTrack) {
              onWhepTrackUpdateListeners.forEach { it.onTrackUpdate(track) }
            }
          })
          whepClient?.onConnectionStateChanged = { newState ->
            emit(EmitableEvent.whepPeerConnectionStateChanged(newState))
          }
        }

        AsyncFunction("connectWhep") Coroutine { options: ConnectOptions ->
          if (whepClient == null) {
            throw IllegalStateException("React context is not available")
          }
          withContext(Dispatchers.IO) {
            whepClient?.connect(ClientConnectOptions(serverUrl = options.serverUrl, authToken = options.authToken))
          }
        }

        AsyncFunction("disconnectWhep") Coroutine { ->
          whepClient?.disconnect()
        }

//        Potentially we want to cleanup whep the same way we do it with whip
//        AsyncFunction("cleanupWhep") Coroutine { ->
//          whepClient = null
//        }

        AsyncFunction("pauseWhep") {
          whepClient?.pause()
        }

        AsyncFunction("unpauseWhep") {
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
