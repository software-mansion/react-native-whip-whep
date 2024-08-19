package com.mobilewhep.client

sealed class CaptureDeviceError(
  val description: String
) : Throwable() {
  class VideoDeviceNotAvailable(
    description: String
  ) : CaptureDeviceError(description)
}

sealed class AttributeNotFoundError(
  val description: String
) : Throwable() {
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
  val description: String
) : Throwable() {
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
  val description: String
) : Throwable() {
  class PermissionsNotGrantedError(
    description: String
  ) : PermissionError(description)
}
