package com.mobilewhep.client.utils

import android.content.Context
import android.media.AudioAttributes
import com.mobilewhep.client.createAudioDeviceModule
import org.webrtc.DefaultVideoDecoderFactory
import org.webrtc.DefaultVideoEncoderFactory
import org.webrtc.EglBase
import org.webrtc.PeerConnectionFactory
import org.webrtc.audio.AudioDeviceModule

class PeerConnectionFactoryHelper private constructor() {
  companion object {
    private var whipPeerConnectionFactory: PeerConnectionFactory? = null
    private var whepPeerConnectionFactory: PeerConnectionFactory? = null

    fun getWhipFactory(
      appContext: Context,
      eglBase: EglBase
    ): PeerConnectionFactory {
      if (whipPeerConnectionFactory == null) {
        whipPeerConnectionFactory = create(appContext, eglBase)
      }
      return whipPeerConnectionFactory!!
    }

    fun clearWhipFactory() {
      whipPeerConnectionFactory?.dispose()
      whipPeerConnectionFactory = null
    }

    fun getWhepFactory(
      appContext: Context,
      eglBase: EglBase
    ): PeerConnectionFactory {
      if (whepPeerConnectionFactory == null) {
        whepPeerConnectionFactory = create(appContext, eglBase)
      }
      return whepPeerConnectionFactory!!
    }

    fun clearWhepFactory() {
      whepPeerConnectionFactory?.dispose()
      whepPeerConnectionFactory = null
    }

    private fun create(
      appContext: Context,
      eglBase: EglBase
    ): PeerConnectionFactory {
      PeerConnectionFactory.initialize(
        PeerConnectionFactory.InitializationOptions.builder(appContext)
          .setFieldTrials("WebRTC-Network-UseNWPathMonitor/Disabled/")
          .setEnableInternalTracer(false)
          .createInitializationOptions()
      )

      val audioAttributes: AudioAttributes =
        AudioAttributes
          .Builder()
          .setUsage(AudioAttributes.USAGE_MEDIA)
          .setContentType(AudioAttributes.CONTENT_TYPE_MOVIE)
          .build()
      val audioDeviceModule: AudioDeviceModule = createAudioDeviceModule(appContext, audioAttributes)

      return PeerConnectionFactory
        .builder()
        .setAudioDeviceModule(audioDeviceModule)
        .setVideoDecoderFactory(DefaultVideoDecoderFactory(eglBase.eglBaseContext))
        .setVideoEncoderFactory(DefaultVideoEncoderFactory(eglBase.eglBaseContext, true, true))
        .createPeerConnectionFactory()
    }
  }
}
