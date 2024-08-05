import WebRTC

public enum AVCaptureDeviceError: Error {
    case AudioDeviceNotAvailable(description: String)
    case VideoDeviceNotAvailable(description: String)
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

protocol RTCPeerConnectionFactoryType: AnyObject, RTCPeerConnectionDelegate {
    var peerConnectionFactory: RTCPeerConnectionFactory? { get set }
    var peerConnection: RTCPeerConnection? { get set }
    var isConnectionSetUp: Bool { get set }
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

    static func setUpPeerConnection(
        player: RTCPeerConnectionFactoryType, configurationOptions: ConfigurationOptions? = nil
    ) {
        let encoderFactory = RTCDefaultVideoEncoderFactory()
        let decoderFactory = RTCDefaultVideoDecoderFactory()
        player.peerConnectionFactory = RTCPeerConnectionFactory(
            encoderFactory: encoderFactory,
            decoderFactory: decoderFactory)

        let stunServerUrl = configurationOptions?.stunServerUrl ?? "stun:stun.l.google.com:19302"
        let stunServer = RTCIceServer(urlStrings: [stunServerUrl])
        let iceServers = [stunServer]

        let config = RTCConfiguration()
        config.iceServers = iceServers
        config.sdpSemantics = .unifiedPlan
        config.continualGatheringPolicy = .gatherContinually
        config.candidateNetworkPolicy = .all
        config.tcpCandidatePolicy = .disabled

        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        player.peerConnection = player.peerConnectionFactory!.peerConnection(
            with: config,
            constraints: constraints,
            delegate: player)

        if player.peerConnection! == nil {
            print("Failed to establish RTCPeerConnection. Check initial configuration")
        }

        player.isConnectionSetUp = true
    }

    /**
    Sends an SDP offer to the WHIP/WHEP server and awaits a response.

    - Parameter sdpOffer: An offer to be sent to the WHIP/WHEP server.
    - Parameter serverUrl: A URL address of the WHIP/WHEP server.
    - Parameter authToken: An authorization token of the WHIP/WHEP  server.

    - Throws: `SessionNetworkError.ConnectionError` if the  connection could not be established or the response code is incorrect,
     for example due to server being down, wrong server URL or token.

    - Returns: A tuple containing the response to the `sdpOffer` and the location which will later be set as a patch endpoint,
    */
    static func sendSdpOffer(sdpOffer: String, serverUrl: URL, authToken: String?) async throws -> (
        responseString: String, location: String?
    ) {
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
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw SessionNetworkError.ConnectionError(
                description:
                    "Network error. Check if the server is up and running and the token and the server url is correct.")
        }
        guard let httpResponse = response as? HTTPURLResponse,
            httpResponse.statusCode == 201
        else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw SessionNetworkError.ConnectionError(
                description:
                    "Network error. Check if the server is up and running and the token and the server url is correct.")
        }

        let responseString = String(data: data!, encoding: .utf8)
        var location: String? = nil
        if let foundLocation = httpResponse.allHeaderFields["Location"] as? String {
            location = foundLocation
            print("Location: \(foundLocation)")
        }

        return (responseString ?? "", location)
    }

    /**
    Sends an ICE candidate to WHIP/WHEP server in order to provide a streaming device.

    - Parameter candidate: Represents a single ICE candidate.
    - Parameter patchEndpoint: And endpoint obtained from the SDP response that accepts PATCH requests.
    - Parameter serverUrl: URL address of the WHIP/WHEP server.

    - Throws: `AttributeNotFoundError.PatchEndpointNotFound` if the patch endpoint has not been properly set up,
     `AttributeNotFoundError.UFragNotFound` if the SDP of the candidate does not contain the ufrag,
     `SessionNetworkError.CandidateSendingError` if the candidate could not be sent and
     `NSError` for when the candidate data dictionary could not be serialized to JSON.
    */
    static func sendCandidate(candidate: RTCIceCandidate, patchEndpoint: String?, serverUrl: URL) async throws {
        guard patchEndpoint != nil else {
            throw AttributeNotFoundError.PatchEndpointNotFound(
                description: "Patch endpoint not found. Make sure the SDP answer is correct.")
        }

        let splitSdp = candidate.sdp.split(separator: " ")
        guard let ufragIndex = splitSdp.firstIndex(of: "ufrag") else {
            throw AttributeNotFoundError.UFragNotFound(
                description: "ufrag not found. Make sure the SDP answer is correct.")
        }
        let ufrag = String(splitSdp[ufragIndex + 1])

        let candidateDict =
            [
                "candidate": candidate.sdp,
                "sdpMLineIndex": candidate.sdpMLineIndex,
                "sdpMid": candidate.sdpMid ?? "",
                "usernameFragment": ufrag,
            ] as [String: Any]

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
            throw SessionNetworkError.CandidateSendingError(
                description: "Candidate sending error - response was not successful.")
        }
    }
}
