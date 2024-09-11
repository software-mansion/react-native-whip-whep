package com.swmansion.reactnativeclient

import android.content.Context
import android.util.Log
import com.mobilewhep.client.ClientBaseListener
import com.mobilewhep.client.ConfigurationOptions
import com.mobilewhep.client.VideoParameters
import com.mobilewhep.client.WhepClient
import com.mobilewhep.client.WhipClient
import expo.modules.kotlin.functions.Coroutine
import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.webrtc.VideoTrack

class ReactNativeClientModule : Module(), ClientBaseListener {
  interface OnTrackUpdateListener {
    fun onTrackUpdate(track: VideoTrack)
  }

  companion object{
    var onTrackUpdateListeners: MutableList<OnTrackUpdateListener> = mutableListOf()
    lateinit var whepClient: WhepClient
    lateinit var whipClient: WhipClient
  }

  override fun definition() = ModuleDefinition {
    Name("ReactNativeClient")

    Constants(
      "PI" to Math.PI
    )

    // Defines event names that the module can send to JavaScript.
    Events("onChange", "trackAdded")

    // Defines a JavaScript synchronous function that runs the native code on the JavaScript thread.
    Function("hello") {
      "Hello world! 👋"
    }

    AsyncFunction ("createClient") { serverUrl: String, configurationOptions: Map<String, Any>? ->
      val context: Context = appContext.reactContext ?: throw IllegalStateException("React context is not available")
      val options = ConfigurationOptions(
        authToken = configurationOptions?.get("authToken") as? String,
        stunServerUrl = configurationOptions?.get("stunServerUrl") as? String,
        audioEnabled = configurationOptions?.get("audioEnabled") as? Boolean ?: true,
        videoEnabled = configurationOptions?.get("videoEnabled") as? Boolean ?: true,
        videoParameters = configurationOptions?.get("videoParameters") as? VideoParameters ?: VideoParameters.presetFHD43
      )
      whepClient = WhepClient(context, serverUrl, options)
      whepClient!!.addTrackListener(this@ReactNativeClientModule)
    }

    AsyncFunction("connect")  Coroutine { ->
      withContext(Dispatchers.Main) {
        whepClient?.connect() ?: throw Exception("Client not found")
      }
    }

    Function ("disconnect") {
      whepClient?.disconnect() ?: throw Exception("Client not found")
    }

    AsyncFunction ("createWhipClient") { serverUrl: String, configurationOptions: Map<String, Any>? ->
      val context: Context = appContext.reactContext ?: throw IllegalStateException("React context is not available")
      val options = ConfigurationOptions(
        authToken = configurationOptions?.get("authToken") as? String,
        stunServerUrl = configurationOptions?.get("stunServerUrl") as? String,
        audioEnabled = configurationOptions?.get("audioEnabled") as? Boolean ?: true,
        videoEnabled = configurationOptions?.get("videoEnabled") as? Boolean ?: true,
        videoParameters = configurationOptions?.get("videoParameters") as? VideoParameters ?: VideoParameters.presetFHD43
      )
      whipClient = WhipClient(context, serverUrl, options)
      sendEvent("onChange", mapOf("status" to "whipClientCreated"))
    }

    AsyncFunction("connectWhip") Coroutine  { ->
      withContext(Dispatchers.Main) {
        whipClient?.connect() ?: throw Exception("Client not found")
      }
    }

    Function ("disconnectWhip") {
      whipClient?.disconnect() ?: throw Exception("Client not found")
    }

    // Defines a JavaScript function that always returns a Promise and whose native code
    // is by default dispatched on the different thread than the JavaScript runtime runs on.
    AsyncFunction("setValueAsync") { value: String ->
      // Send an event to JavaScript.
      sendEvent("onChange", mapOf(
        "value" to value
      ))
    }

  }

  override fun onTrackAdded(track: VideoTrack) {
    sendEvent("trackAdded", mapOf(track.id() to track.kind()))
    onTrackUpdateListeners.forEach { it.onTrackUpdate(track) }
    Log.d("kotki", onTrackUpdateListeners.toString())
  }
}
