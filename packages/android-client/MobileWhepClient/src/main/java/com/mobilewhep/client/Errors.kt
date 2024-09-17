package com.mobilewhep.client

sealed class CaptureDeviceError(
  private val description: String
) : Exception(description) {
  class VideoDeviceNotAvailable(
    description: String
  ) : CaptureDeviceError(description)

  class VideoSizeNotSupported(
    description: String
  ) : CaptureDeviceError(description)
}

sealed class AttributeNotFoundError(
  private val description: String
) : Exception(description) {
  class LocationNotFound(
    description: String
  ) : AttributeNotFoundError(description)

  class PatchEndpointNotFound(
    description: String
  ) : AttributeNotFoundError(description)

  class UFragNotFound(
    description: String
  ) : AttributeNotFoundError(description)

  class ResponseNotFound(
    description: String
  ) : AttributeNotFoundError(description)
}

sealed class SessionNetworkError(
  private val description: String
) : Exception(description) {
  class CandidateSendingError(
    description: String
  ) : SessionNetworkError(description)

  class ConnectionError(
    description: String
  ) : SessionNetworkError(description)

  class ConfigurationError(
    description: String
  ) : SessionNetworkError(description)
}

sealed class PermissionError(
  private val description: String
) : Exception(description) {
  class PermissionsNotGrantedError(
    description: String
  ) : PermissionError(description)
}
