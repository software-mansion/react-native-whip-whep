package com.mobilewhep.client

import android.content.Context
import android.media.AudioAttributes
import android.util.Log
import org.webrtc.audio.AudioDeviceModule
import org.webrtc.audio.JavaAudioDeviceModule

fun createAudioDeviceModule(
  appContext: Context,
  audioAttributes: AudioAttributes
): AudioDeviceModule {
  val audioRecordErrorCallback =
    object : JavaAudioDeviceModule.AudioRecordErrorCallback {
      override fun onWebRtcAudioRecordInitError(errorMessage: String?) {
        Log.e("AudioDeviceModule", "onWebRtcAudioRecordInitError: $errorMessage")
      }

      override fun onWebRtcAudioRecordStartError(
        errorCode: JavaAudioDeviceModule.AudioRecordStartErrorCode?,
        errorMessage: String?
      ) {
        Log.e("AudioDeviceModule", "onWebRtcAudioRecordStartError: $errorCode. $errorMessage")
      }

      override fun onWebRtcAudioRecordError(errorMessage: String?) {
        Log.e("AudioDeviceModule", "onWebRtcAudioRecordError: $errorMessage")
      }
    }

  val audioTrackErrorCallback =
    object : JavaAudioDeviceModule.AudioTrackErrorCallback {
      override fun onWebRtcAudioTrackInitError(errorMessage: String?) {
        Log.e("AudioDeviceModule", "onWebRtcAudioTrackInitError: $errorMessage")
      }

      override fun onWebRtcAudioTrackStartError(
        errorCode: JavaAudioDeviceModule.AudioTrackStartErrorCode?,
        errorMessage: String?
      ) {
        Log.e("AudioDeviceModule", "onWebRtcAudioTrackStartError: $errorCode. $errorMessage")
      }

      override fun onWebRtcAudioTrackError(errorMessage: String?) {
        Log.e("AudioDeviceModule", "onWebRtcAudioTrackError: $errorMessage")
      }
    }

  val audioRecordStateCallback: JavaAudioDeviceModule.AudioRecordStateCallback =
    object : JavaAudioDeviceModule.AudioRecordStateCallback {
      override fun onWebRtcAudioRecordStart() {
        Log.i("AudioDeviceModule", "Audio recording starts")
      }

      override fun onWebRtcAudioRecordStop() {
        Log.i("AudioDeviceModule", "Audio recording stops")
      }
    }

  val audioTrackStateCallback: JavaAudioDeviceModule.AudioTrackStateCallback =
    object : JavaAudioDeviceModule.AudioTrackStateCallback {
      override fun onWebRtcAudioTrackStart() {
        Log.i("AudioDeviceModule", "Audio playout starts")
      }

      override fun onWebRtcAudioTrackStop() {
        Log.i("AudioDeviceModule", "Audio playout stops")
      }
    }

  return JavaAudioDeviceModule
    .builder(appContext)
    .setUseHardwareAcousticEchoCanceler(true)
    .setUseHardwareNoiseSuppressor(true)
    .setAudioRecordErrorCallback(audioRecordErrorCallback)
    .setAudioTrackErrorCallback(audioTrackErrorCallback)
    .setAudioRecordStateCallback(audioRecordStateCallback)
    .setAudioTrackStateCallback(audioTrackStateCallback)
    .setAudioAttributes(audioAttributes)
    .createAudioDeviceModule()
}
