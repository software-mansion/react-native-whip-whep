import CoreMedia
import Foundation

/// Type refering to video dimensions.
public typealias Dimensions = CMVideoDimensions

public extension Dimensions {
    static let aspect16By9 = 16.0 / 9.0
    static let aspect4By3 = 4.0 / 3.0
}

extension Dimensions: Equatable {
    public static func == (lhs: Dimensions, rhs: Dimensions) -> Bool {
        lhs.width == rhs.width && lhs.height == rhs.height
    }
}

public extension Dimensions {
    /// Swaps height with width.
    func flip() -> Dimensions {
        return Dimensions(width: height, height: width)
    }
}
