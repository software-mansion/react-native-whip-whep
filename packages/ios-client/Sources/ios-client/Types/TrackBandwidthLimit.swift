/// Type describing maximal bandwidth that can be used, in kbps. 0 is interpreted as unlimited bandwidth.
public typealias BandwidthLimit = Int

/// Type describing bandwidth limitation of a Track
/// An enum of `BandwidthLimit`
public enum TrackBandwidthLimit {
    case BandwidthLimit(BandwidthLimit)
}
