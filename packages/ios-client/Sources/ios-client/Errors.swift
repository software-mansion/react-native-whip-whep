public enum CaptureDeviceError: Error {
    case VideoDeviceNotAvailable(description: String)
    case VideoSizeNotSupported(description: String)
}

public enum AttributeNotFoundError: Error {
    case LocationNotFound(description: String)
    case PatchEndpointNotFound(description: String)
    case UFragNotFound(description: String)
    case ResponseNotFound(description: String)
}

public enum SessionNetworkError: LocalizedError {
    case CandidateSendingError(description: String)
    case ConnectionError(description: String)
    case ConfigurationError(description: String)

    public var errorDescription: String? {
        switch self {
        case .CandidateSendingError(let description):
            return "Candidate sending error: \(description)"
        case .ConnectionError(let description):
            return "Connection error: \(description)"
        case .ConfigurationError(let description):
            return "Configuration error: \(description)"
        }
    }
}

public enum ScreenSharingError: LocalizedError {
    case NoExtension(description: String)

    public var errorDescription: String? {
        switch self {
        case .NoExtension(let description):
            return "No screen share extension bundle id set. Please set ScreenShareExtensionBundleId in Info.plist"
        }
    }
}
