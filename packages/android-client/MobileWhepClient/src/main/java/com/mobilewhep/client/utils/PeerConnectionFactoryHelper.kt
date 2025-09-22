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
    private var peerConnectionFactory: PeerConnectionFactory? = null
//    val eglBase = EglBase.create()

    fun getFactory(appContext: Context, eglBase: EglBase): PeerConnectionFactory {
      if (peerConnectionFactory == null) {
        peerConnectionFactory = create(appContext, eglBase)
      }
      return peerConnectionFactory!!
    }

    private fun create(appContext: Context, eglBase: EglBase): PeerConnectionFactory {
      PeerConnectionFactory.initialize(
        PeerConnectionFactory.InitializationOptions.builder(appContext).createInitializationOptions()
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
