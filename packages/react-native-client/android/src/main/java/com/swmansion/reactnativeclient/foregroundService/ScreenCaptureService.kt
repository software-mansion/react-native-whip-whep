package com.swmansion.reactnativeclient.foregroundService

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.os.Binder
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

class ScreenCaptureService : Service() {
  companion object {
    private const val FOREGROUND_SERVICE_ID = 1669
  }

  private val binder = LocalBinder()

  inner class LocalBinder : Binder() {
    fun getService(): ScreenCaptureService = this@ScreenCaptureService
  }

  override fun onBind(intent: Intent): IBinder = binder

  override fun onStartCommand(
    intent: Intent?,
    flags: Int,
    startId: Int
  ): Int {
    restartService(intent)
    return START_NOT_STICKY
  }

  fun restartService(intent: Intent?) {
    val channelId = intent!!.getStringExtra("channelId")!!
    val channelName = intent.getStringExtra("channelName")!!
    val notificationTitle = intent.getStringExtra("notificationTitle")!!
    val notificationContent = intent.getStringExtra("notificationContent")!!
    val foregroundServiceTypesArray = intent.getIntArrayExtra("foregroundServiceTypes")!!
    val foregroundServiceType = foregroundServiceTypesArray.reduce { acc, value -> acc or value }

    val pendingIntent =
      PendingIntent.getActivity(
        this,
        0,
        intent,
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
      )

    val notification: Notification =
      NotificationCompat
        .Builder(this, channelId)
        .setContentTitle(notificationTitle)
        .setContentText(notificationContent)
        .setContentIntent(pendingIntent)
        .setSmallIcon(android.R.drawable.ic_dialog_info)
        .build()

    createNotificationChannel(channelId, channelName)
    startForegroundWithNotification(notification, foregroundServiceType)
  }

  private fun startForegroundWithNotification(
    notification: Notification,
    foregroundServiceType: Int
  ) {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
      startForeground(
        FOREGROUND_SERVICE_ID,
        notification,
        foregroundServiceType
      )
    } else {
      startForeground(
        FOREGROUND_SERVICE_ID,
        notification
      )
    }
  }

  private fun createNotificationChannel(
    channelId: String,
    channelName: String
  ) {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
      return
    }

    val serviceChannel =
      NotificationChannel(
        channelId,
        channelName,
        NotificationManager.IMPORTANCE_LOW
      )
    val notificationManager = getSystemService(NOTIFICATION_SERVICE) as? NotificationManager
    notificationManager?.createNotificationChannel(serviceChannel)
  }
}

