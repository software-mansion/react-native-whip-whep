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
    case .CandidateSendingError(description: let description):
      return "Candidate sending error: \(description)"
    case .ConnectionError(description: let description):
      return "Connection error: \(description)"
    case .ConfigurationError(description: let description):
      return "Configuration error: \(description)"
    }
  }
}
