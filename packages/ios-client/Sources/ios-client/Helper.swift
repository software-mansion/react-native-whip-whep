import WebRTC

enum AVCaptureDeviceError: Error {
    case AudioDeviceNotAvailable(description: String)
    case VideoDeviceNotAvailable(description: String)
}

enum AttributeNotFoundError: Error {
    case LocationNotFound(description: String)
    case PatchEndpointNotFound(description: String)
    case UFragNotFound(description: String)
    case ResponseNotFound(description: String)
}

enum SessionNetworkError: Error {
    case CandidateSendingError(description: String)
    case ConnectionError(description: String)
    case ConfigurationError(description: String)
}

extension RTCPeerConnection {
  // currently `Membrane RTC Engine` can't handle track of diretion `sendRecv` therefore
  // we need to change all `sendRecv` to `sendOnly`.
  func enforceSendOnlyDirection() {
    self.transceivers.forEach { transceiver in
      if transceiver.direction == .sendRecv {
        transceiver.setDirection(.sendOnly, error: nil)
      }
    }
  }
}

extension RTCRtpEncodingParameters {
  static func create(rid: String, active: Bool, scaleResolutionDownBy: NSNumber) -> RTCRtpEncodingParameters {
    let encoding = RTCRtpEncodingParameters()
    encoding.rid = rid
    encoding.isActive = active
    encoding.scaleResolutionDownBy = scaleResolutionDownBy
    return encoding
  }
  

  static func create(active: Bool) -> RTCRtpEncodingParameters {
    let encoding = RTCRtpEncodingParameters()
    encoding.isActive = active
    return encoding
  }
}

@available(macOS 12.0, *)
class Helper: NSObject {
    static func sendSdpOffer(sdpOffer: String, serverUrl: URL, authToken: String?) async throws -> (responseString: String, location: String?) {
        var request = URLRequest(url: serverUrl)
        request.httpMethod = "POST"
        request.httpBody = sdpOffer.data(using: .utf8)
        request.addValue("application/sdp", forHTTPHeaderField: "Accept")
        request.addValue("application/sdp", forHTTPHeaderField: "Content-Type")
        if let token = authToken {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        var data: Data?
        var response: URLResponse?
        do{
            (data, response) = try await URLSession.shared.data(for: request)
        }catch{
            throw SessionNetworkError.ConnectionError(description: "Network error. Check if the server is up and running, the token and the server url is correct")
        }
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 201 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw SessionNetworkError.ConnectionError(description: "Network error. Check if the server is up and running, the token and the server url is correct")
        }

        let responseString = String(data: data!, encoding: .utf8)
        var location: String? = nil
        if let foundLocation = httpResponse.allHeaderFields["Location"] as? String {
            location = foundLocation
            print("Location: \(foundLocation)")
        }
        
        return (responseString ?? "", location)
    }
        
    static func sendCandidate(candidate: RTCIceCandidate, patchEndpoint: String?, serverUrl: URL) async throws {
        guard patchEndpoint != nil else {
            throw AttributeNotFoundError.PatchEndpointNotFound(description: "Patch endpoint not found. Make sure the SDP answer is correct.")
        }
        
        let splitSdp = candidate.sdp.split(separator: " ")
        guard let ufragIndex = splitSdp.firstIndex(of: "ufrag") else {
            throw AttributeNotFoundError.UFragNotFound(description: "ufrag not found. Make sure the SDP answer is correct.")
        }
        let ufrag = String(splitSdp[ufragIndex + 1])
        
        let candidateDict = [
            "candidate": candidate.sdp,
            "sdpMLineIndex": candidate.sdpMLineIndex,
            "sdpMid": candidate.sdpMid ?? "",
            "usernameFragment": ufrag
        ] as [String : Any]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: candidateDict, options: []) else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "JSON serialization error"])
        }

        var components = URLComponents(string: serverUrl.absoluteString)
        components?.path = ""
        components?.path = patchEndpoint!
        let url = components?.url
        var request = URLRequest(url: url!)
        request.httpMethod = "PATCH"
        request.httpBody = jsonData
        request.setValue("application/trickle-ice-sdpfrag", forHTTPHeaderField: "Content-Type")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 204 else {
            throw SessionNetworkError.CandidateSendingError(description: "Candidate sending error - response was not successful.")
        }
    }
}
