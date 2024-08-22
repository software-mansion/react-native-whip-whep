package com.mobilewhep.client

/**
 * Type describing bandwidth limitation of a Track, including simulcast and non-simulcast tracks.
 * Can be`BandwidthLimit` or `SimulcastBandwidthLimit`
 */
sealed class TrackBandwidthLimit {
  /**
   * Type describing maximal bandwidth that can be used, in kbps. 0 is interpreted as unlimited bandwidth.
   */
  class BandwidthLimit(
    val limit: Int
  ) : TrackBandwidthLimit()

  /**
   *  Type describing bandwidth limit for simulcast track.
   *  It is a mapping (encoding => BandwidthLimit).
   *  If encoding isn't present in this mapping, it will be assumed that this particular encoding shouldn't have any bandwidth limit
   */
  class SimulcastBandwidthLimit(
    val limit: Map<String, BandwidthLimit>
  ) : TrackBandwidthLimit()
}
