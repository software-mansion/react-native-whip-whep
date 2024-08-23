package com.mobilewhep.client

/**
 * Type describing bandwidth limitation of a Track.
 * Can be`BandwidthLimit` only
 */
sealed class TrackBandwidthLimit {
  /**
   * Type describing maximal bandwidth that can be used, in kbps. 0 is interpreted as unlimited bandwidth.
   */
  class BandwidthLimit(
    val limit: Int
  ) : TrackBandwidthLimit()
}
