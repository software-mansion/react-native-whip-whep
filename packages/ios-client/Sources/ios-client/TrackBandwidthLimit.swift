/// Type describing bandwidth limit for simulcast track.
/// It is a mapping (encoding => BandwidthLimit).
/// If encoding isn't present in this mapping, it will be assumed that this particular encoding shouldn't have any bandwidth limit
public typealias SimulcastBandwidthLimit = [String: Int]

/// Type describing maximal bandwidth that can be used, in kbps. 0 is interpreted as unlimited bandwidth.
public typealias BandwidthLimit = Int

/// Type describing bandwidth limitation of a Track, including simulcast and non-simulcast tracks.
/// An enum of `BandwidthLimit` and `SimulcastBandwidthLimit`
public enum TrackBandwidthLimit {
    case BandwidthLimit(BandwidthLimit)
    case SimulcastBandwidthLimit(SimulcastBandwidthLimit)
}
