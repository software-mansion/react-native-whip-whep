import WebRTC

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

        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 201 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw NSError(domain: "HTTPError", code: statusCode, userInfo: nil)
        }

        let responseString = String(data: data, encoding: .utf8)
        var location: String? = nil
        if let foundLocation = httpResponse.allHeaderFields["Location"] as? String {
            location = foundLocation
            print("Location: \(foundLocation)")
        }
        
        return (responseString!, location)
    }
        
    static func sendCandidate(candidate: RTCIceCandidate, patchEndpoint: String?, serverUrl: URL) async throws {
        guard patchEndpoint != nil else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Patch endpoint is nil"])
        }
        
        let splitSdp = candidate.sdp.split(separator: " ")
        guard let ufragIndex = splitSdp.firstIndex(of: "ufrag") else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to find 'ufrag' in SDP"])
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

        var request = URLRequest(url: serverUrl)
        request.httpMethod = "PATCH"
        request.httpBody = jsonData
        request.setValue("application/trickle-ice-sdpfrag", forHTTPHeaderField: "Content-Type")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 204 else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Response was not successful"])
        }
    }
    
//    func connect(peerConnection: RTCPeerConnection, iceCandidates: [RTCIceCandidate], patchEndpoint: String?, connectionOptions: ConnectionOptions) async throws {
//        var error: NSError?
//        let videoTransceiver = peerConnection.addTransceiver(of: .video)!
//        videoTransceiver.setDirection(.recvOnly, error: &error)
//
//        let audioTransceiver = peerConnection.addTransceiver(of: .audio)!
//        audioTransceiver.setDirection(.recvOnly, error: &error)
//
//        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
//        let offer = try await peerConnection.offer(for: constraints)
//        try await peerConnection.setLocalDescription(offer)
//
//        let sdpAnswer = try await Helper.sendSdpOffer(sdpOffer: offer.sdp, connectionOptions: connectionOptions)
//        
//        for candidate in iceCandidates {
//            do {
//                try await Helper.sendCandidate(candidate: candidate, patchEndpoint: patchEndpoint!, connectionOptions: connectionOptions)
//            } catch {
//                print("Error sending ICE candidate: \(error)")
//            }
//        }
//
//        let remoteDescription = RTCSessionDescription(type: .answer, sdp: sdpAnswer)
//        try await peerConnection.setRemoteDescription(remoteDescription)
//    }
    
    
}
