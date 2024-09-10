package com.swmansion.reactnativeclient

import android.content.Context
import com.mobilewhep.client.ClientBase
import com.mobilewhep.client.ClientBaseListener
import com.mobilewhep.client.ConfigurationOptions
import com.mobilewhep.client.VideoParameters
import com.mobilewhep.client.WhepClient
import com.mobilewhep.client.WhipClient
import expo.modules.kotlin.functions.Coroutine
import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.webrtc.VideoTrack

class ReactNativeClientModule : Module(), ClientBaseListener {
  // Each module class must implement the definition function. The definition consists of components
  // that describes the module's functionality and behavior.
  // See https://docs.expo.dev/modules/module-api for more details about available components.
  private var whepClient: WhepClient? = null
  private var whipClient: WhipClient? = null

  override fun definition() = ModuleDefinition {
    // Sets the name of the module that JavaScript code will use to refer to the module. Takes a string as an argument.
    // Can be inferred from module's class name, but it's recommended to set it explicitly for clarity.
    // The module will be accessible from `requireNativeModule('ReactNativeClient')` in JavaScript.
    Name("ReactNativeClient")

    // Sets constant properties on the module. Can take a dictionary or a closure that returns a dictionary.
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

    // Enables the module to be used as a native view. Definition components that are accepted as part of
    // the view definition: Prop, Events.

  }

  override fun onTrackAdded(track: VideoTrack) {
    sendEvent("trackAdded", mapOf(track.id() to track.kind()))
  }
}
