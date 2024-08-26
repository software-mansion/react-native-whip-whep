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

public enum SessionNetworkError: Error {
    case CandidateSendingError(description: String)
    case ConnectionError(description: String)
    case ConfigurationError(description: String)
}
