package com.swmansion.reactnativeclient.helpers

import android.Manifest
import android.content.pm.PackageManager
import expo.modules.interfaces.permissions.Permissions
import expo.modules.interfaces.permissions.PermissionsStatus
import expo.modules.kotlin.AppContext
import expo.modules.kotlin.exception.Exceptions
import kotlin.coroutines.resume
import kotlin.coroutines.suspendCoroutine

object PermissionUtils {
  fun hasCameraPermission(appContext: AppContext?): Boolean = hasPermission(appContext, Manifest.permission.CAMERA)

  fun hasMicrophonePermission(appContext: AppContext?): Boolean = hasPermission(appContext, Manifest.permission.RECORD_AUDIO)

  suspend fun requestCameraPermission(appContext: AppContext?): Boolean = requestAccessIfNeeded(appContext, Manifest.permission.CAMERA)

  suspend fun requestMicrophonePermission(appContext: AppContext?): Boolean =
    requestAccessIfNeeded(appContext, Manifest.permission.RECORD_AUDIO)

  private suspend fun requestAccessIfNeeded(
    appContext: AppContext?,
    permission: String
  ): Boolean {
    val permissionsManager: Permissions =
      appContext?.permissions
        ?: throw Exceptions.PermissionsModuleNotFound()

    if (hasPermission(appContext, permission)) {
      return true
    }

    return suspendCoroutine { continuation ->
      permissionsManager.askForPermissions({ result ->
        continuation.resume(result[permission]?.status == PermissionsStatus.GRANTED)
      }, permission)
    }
  }

  private fun hasPermission(
    appContext: AppContext?,
    permission: String
  ): Boolean = appContext?.reactContext?.checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED
}
