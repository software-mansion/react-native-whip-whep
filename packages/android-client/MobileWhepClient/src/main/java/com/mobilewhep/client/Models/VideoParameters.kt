package com.mobilewhep.client

data class Dimensions(
  val width: Int,
  val height: Int
) {
  fun flip(): Dimensions = Dimensions(width = this.height, height = this.width)
}

/**
 * A set of parameters representing a video feed.
 *
 * @property dimensions: specified width x height of the video
 * @property maxBitrate: specifies maximum bitrate of video stream
 * @property maxFps: specifies maximum frame rate of the video stream
 * <p>
 * Contains a set of useful presets.
 */
public data class VideoParameters(
  val dimensions: Dimensions,
  val maxBitrate: BandwidthLimit,
  val maxFps: Int
) {
  companion object {
    // 4:3 aspect ratio
    val presetQVGA43 =
      VideoParameters(
        dimensions = Dimensions(width = 240, height = 180),
        maxBitrate = 90,
        maxFps = 10
      )
    val presetVGA43 =
      VideoParameters(
        dimensions = Dimensions(width = 480, height = 360),
        maxBitrate = 225,
        maxFps = 20
      )
    val presetQHD43 =
      VideoParameters(
        dimensions = Dimensions(width = 720, height = 540),
        maxBitrate = 450,
        maxFps = 25
      )
    val presetHD43 =
      VideoParameters(
        dimensions = Dimensions(width = 960, height = 720),
        maxBitrate = 1_500,
        maxFps = 30
      )
    val presetFHD43 =
      VideoParameters(
        dimensions = Dimensions(width = 1440, height = 1080),
        maxBitrate = 2_800,
        maxFps = 30
      )

    // 16:9 aspect ratio
    val presetQVGA169 =
      VideoParameters(
        dimensions = Dimensions(width = 320, height = 180),
        maxBitrate = 120,
        maxFps = 10
      )
    val presetVGA169 =
      VideoParameters(
        dimensions = Dimensions(width = 640, height = 360),
        maxBitrate = 300,
        maxFps = 20
      )
    val presetQHD169 =
      VideoParameters(
        dimensions = Dimensions(width = 960, height = 540),
        maxBitrate = 600,
        maxFps = 25
      )
    val presetHD169 =
      VideoParameters(
        dimensions = Dimensions(width = 1280, height = 720),
        maxBitrate = 2_000,
        maxFps = 30
      )
    val presetFHD169 =
      VideoParameters(
        dimensions = Dimensions(width = 1920, height = 1080),
        maxBitrate = 3_000,
        maxFps = 30
      )

    // Screen share
    val presetScreenShareVGA =
      VideoParameters(
        dimensions = Dimensions(width = 640, height = 360),
        maxBitrate = 200,
        maxFps = 3
      )
    val presetScreenShareHD5 =
      VideoParameters(
        dimensions = Dimensions(width = 1280, height = 720),
        maxBitrate = 400,
        maxFps = 5
      )
    val presetScreenShareHD15 =
      VideoParameters(
        dimensions = Dimensions(width = 1280, height = 720),
        maxBitrate = 1_000,
        maxFps = 15
      )
    val presetScreenShareFHD15 =
      VideoParameters(
        dimensions = Dimensions(width = 1920, height = 1080),
        maxBitrate = 1_500,
        maxFps = 15
      )
    val presetScreenShareFHD30 =
      VideoParameters(
        dimensions = Dimensions(width = 1920, height = 1080),
        maxBitrate = 3_000,
        maxFps = 30
      )

    val presets43 =
      listOf(
        presetQVGA43,
        presetVGA43,
        presetQHD43,
        presetHD43,
        presetFHD43
      )

    val presets169 =
      listOf(
        presetQVGA169,
        presetVGA169,
        presetQHD169,
        presetHD169,
        presetFHD169
      )

    val presetsScreenShare =
      listOf(
        presetScreenShareVGA,
        presetScreenShareHD5,
        presetScreenShareHD15,
        presetScreenShareFHD15,
        presetScreenShareFHD30
      )
  }
}
