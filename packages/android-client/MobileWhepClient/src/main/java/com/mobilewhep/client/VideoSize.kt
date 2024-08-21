package com.mobilewhep.client

enum class VideoSize(
  val width: Int,
  val height: Int,
  val frameRate: Int
) {
  SD(640, 480, 30),
  HD(1280, 720, 30),
  FULL_HD(1920, 1080, 30),
  UHD_4K(3840, 2160, 30)
}
