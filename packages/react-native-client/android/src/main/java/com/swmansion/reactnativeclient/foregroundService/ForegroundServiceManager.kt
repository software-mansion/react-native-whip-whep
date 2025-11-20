package com.swmansion.reactnativeclient.foregroundService

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.os.Build
import android.os.IBinder
import expo.modules.kotlin.AppContext
import expo.modules.kotlin.exception.CodedException
import kotlinx.coroutines.CancellableContinuation
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlin.coroutines.resume

class ForegroundServiceManager(
  private val appContext: AppContext
) {
  private val reactContext by lazy {
    appContext.reactContext ?: throw CodedException("reactContext not found")
  }

  private var serviceState = ForegroundServiceState()
  private var serviceInstance: ScreenCaptureService? = null
  private var serviceConnectedContinuation: CancellableContinuation<Unit>? = null
  private val serviceIntent =
    Intent(
      appContext.reactContext,
      ScreenCaptureService::class.java
    )

  private val connection =
    object : ServiceConnection {
      override fun onServiceConnected(
        className: ComponentName,
        service: IBinder
      ) {
        serviceInstance = (service as ScreenCaptureService.LocalBinder).getService()
        serviceConnectedContinuation?.resume(Unit)
        serviceConnectedContinuation = null
      }

      override fun onServiceDisconnected(arg0: ComponentName) {
        serviceInstance = null
        serviceConnectedContinuation?.cancel(CancellationException("Service disconnected"))
        serviceConnectedContinuation = null
      }
    }

  fun updateService(update: ForegroundServiceState.() -> Unit) {
    serviceState.update()
  }

  suspend fun start() {
    val foregroundServiceTypes = serviceState.buildForegroundServiceTypes(appContext)

    if (foregroundServiceTypes.isEmpty()) {
      stop()
      return
    }

    serviceIntent.apply {
      putExtra("channelId", serviceState.channelId)
      putExtra("channelName", serviceState.channelName)
      putExtra("notificationContent", serviceState.notificationContent)
      putExtra("notificationTitle", serviceState.notificationTitle)
      putExtra("foregroundServiceTypes", foregroundServiceTypes.toIntArray())
    }

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
      reactContext.startForegroundService(serviceIntent)
    } else {
      reactContext.startService(serviceIntent)
    }

    bindServiceIfNeededAndAwait()
  }

  fun stop() {
    if (serviceInstance != null) {
      appContext.currentActivity?.unbindService(connection)
      serviceInstance = null
    }
    reactContext.stopService(serviceIntent)
    serviceConnectedContinuation?.cancel(CancellationException("Service stopped"))
    serviceConnectedContinuation = null
  }

  private suspend fun bindServiceIfNeededAndAwait() =
    suspendCancellableCoroutine { continuation ->
      if (serviceInstance == null) {
        serviceConnectedContinuation = continuation
        runCatching {
          appContext.currentActivity?.bindService(
            serviceIntent,
            connection,
            Context.BIND_AUTO_CREATE
          )
        }.onFailure { error ->
          continuation.cancel(CodedException("Failed to bind service: ${error.message}"))
        }
      } else {
        serviceInstance?.restartService(serviceIntent)
        continuation.resume(Unit)
        serviceConnectedContinuation = null
      }
    }
}

