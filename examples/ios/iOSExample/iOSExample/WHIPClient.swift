import Foundation
import WebRTC

class WHIPClient: NSObject {
    var iceUsername: String?
    var icePassword: String?
    var candidates: [RTCIceCandidate] = []
    var endOfCandidates: Bool = false
    var pc: RTCPeerConnection?
    var token: String?
    var iceTrickleTimer: Timer?

    override init() {
        self.iceUsername = nil
        self.icePassword = nil
        self.candidates = []
        self.endOfCandidates = false
    }

    func onOffer(_ offer: String) -> String {
        return offer
    }

    func onAnswer(_ answer: String) -> String {
        return answer
    }
    
    func publish(url: URL, token: String?) async throws {
        guard self.pc == nil else {
            throw NSError(domain: "WHIPClient", code: 0, userInfo: [NSLocalizedDescriptionKey: "Already publishing"])
        }
        
        let configuration = RTCConfiguration()
        let constraints = RTCMediaConstraints(mandatoryConstraints: ["OfferToReceiveAudio": "true", "OfferToReceiveVideo": "true"], optionalConstraints: nil)
        self.pc = RTCPeerConnectionFactory().peerConnection(with: configuration, constraints: constraints, delegate: self)
        self.token = token
        
        //Create SDP offer
        let offer = try await pc?.offer(for: constraints)
        print(offer)
        
        var headers = ["Content-Type": "application/sdp"]
        if let authToken = token {
            headers["Authorization"] = "Bearer \(authToken)"
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = offer?.sdp.data(using: .utf8)
        request.allHTTPHeaderFields  = headers
        
        let session = URLSession.shared

        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 else {
            throw NSError(domain: "HTTPError", code: (response as? HTTPURLResponse)?.statusCode ?? 400, userInfo: nil)
        }
        print(response)
        
        if httpResponse.statusCode != 201 {
            throw NSError(domain: "HTTPError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Request rejected with status \(httpResponse.statusCode)"])
        }
        
        guard let location = httpResponse.allHeaderFields["Location"] as? String else {
            throw NSError(domain: "HTTPError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Response missing location header"])
        }
        
        guard let resourceURL = URL(string: location, relativeTo: request.url) else {
            throw NSError(domain: "URL Error", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to create URL from Location header"])
        }
        
        print("Resource URL: \(resourceURL)")

    }
}

extension WHIPClient: RTCPeerConnectionDelegate {
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        
    }
    
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        print("Nowy kandydat ICE:", candidate);
        guard candidate.sdpMLineIndex == 0 else { // Odpowiada JS: if (event.candidate.sdpMLineIndex > 0) { return; }
            return
        }

        self.candidates.append(candidate)

        if candidate.sdp.isEmpty {
            self.endOfCandidates = true
        }

        // Równoważnik setTimeout w Swift
//        if iceTrickleTimer == nil {
//            iceTrickleTimer = Timer.scheduledTimer(withTimeInterval: 0, repeats: false) { _ in
//                self.patchIceCandidates()
//            }
//        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCPeerConnectionState) {
        switch stateChanged {
        case .connected:
            print("Connection is fully connected")
        case .disconnected:
            print("One or more transports has disconnected unexpectedly")
        case .failed:
            print("One or more transports has encountered an error")
        case .closed:
            print("Connection has been closed")
        default:
            print("Some other state: \(stateChanged)")
        }
    }

}

//class WHIPClient: NSObject {
//    var iceCandidates: [RTCIceCandidate] = []
//    var endOfCandidates = false
//    var pc: RTCPeerConnection?
//    var resourceURL: URL?
//    var token: String?
//    var etag: String?
//    var iceUsername: String?
//    var icePassword: String?
//    var iceRestartTimeout: Timer?
//
//    func publish(pc: RTCPeerConnection, url: URL, token: String?) throws {
//        guard self.pc == nil else {
//            throw NSError(domain: "WHIPClient", code: 0, userInfo: [NSLocalizedDescriptionKey: "Already publishing"])
//        }
//        
//        self.pc = pc
//        self.token = token
//        
//        pc.delegate = self
//        
//        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
//        
//        
//        pc.offer(for: constraints) { [weak self] (sdp, error) in
//            guard let strongSelf = self else { return }
//            if let error = error {
//                // Obsługa błędu, np. pokazanie alertu lub logowanie
//                print("Error generating offer: \(error)")
//                return
//            }
//            
//            guard let offer = sdp else {
//                print("Offer is nil")
//                return
//            }
//            
//            var request = URLRequest(url: url)
//            request.httpMethod = "POST"
//            request.httpBody = offer.sdp.data(using: .utf8)
//            request.addValue("application/sdp", forHTTPHeaderField: "Content-Type")
//            if let token = strongSelf.token {
//                request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
//            }
//            
//            URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
//                guard let self = self, let httpResponse = response as? HTTPURLResponse else { return }
//                
//                guard error == nil, httpResponse.statusCode == 200 else {
//                    print("HTTP error: \(error?.localizedDescription ?? "Unknown")")
//                    return
//                }
//                
//                guard let location = httpResponse.allHeaderFields["Location"] as? String,
//                      let responseURL = URL(string: location, relativeTo: url) else {
//                    print("Location header is missing")
//                    return
//                }
//                
//                self.resourceURL = responseURL
//                
//                if let data = data, let answerSDP = String(data: data, encoding: .utf8) {
//                    Task {
//                        do {
//                            try await self.handleResponse(data: data)
//                        } catch {
//                            print("Failed to set remote description: \(error)")
//                        }
//                    }
//                }
//                
//                if let etag = httpResponse.allHeaderFields["ETag"] as? String {
//                    self.etag = etag
//                }
//                
//                self.scheduleIceCandidatesPatch()
//                
//            }.resume()
//        }
//    }
//    
//    func handleResponse(data: Data) async throws {
//        if let answerSDP = String(data: data, encoding: .utf8) {
//            let sessionDescription = RTCSessionDescription(type: .answer, sdp: answerSDP)
//            try await self.pc?.setRemoteDescription(sessionDescription)
//        }
//    }
//
//    func scheduleIceCandidatesPatch() {
//            iceRestartTimeout?.invalidate()
//            iceRestartTimeout = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { [weak self] _ in
//                self?.patchIceCandidates()
//            }
//    }
//    
//    private func createIceCandidatesFragment() -> String {
//        var fragment = "a=ice-ufrag:\(iceUsername ?? "")\r\na=ice-pwd:\(icePassword ?? "")\r\n"
//        for candidate in iceCandidates {
//            fragment += "a=\(candidate.sdp)\r\n"
//        }
//        if endOfCandidates {
//            fragment += "a=end-of-candidates\r\n"
//        }
//        return fragment
//    }
//    
//    private func patchIceCandidates() {
//        guard let url = resourceURL else { return }
//        
//        let fragment = createIceCandidatesFragment()
//        var request = URLRequest(url: url)
//        request.httpMethod = "PATCH"
//        request.httpBody = fragment.data(using: .utf8)
//        request.addValue("application/trickle-ice-sdpfrag", forHTTPHeaderField: "Content-Type")
//        
//        if let etag = etag {
//            request.addValue(etag, forHTTPHeaderField: "If-Match")
//        }
//        
//        if let token = token {
//            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
//        }
//        
//        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
//            guard let self = self else { return }
//            if error != nil || (response as? HTTPURLResponse)?.statusCode != 200 {
//                print("Error patching ICE candidates")
//                return
//            }
//            // Handle response for ICE restart, if needed
//        }.resume()
//    }
//}
