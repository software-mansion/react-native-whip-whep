import Foundation
import WebRTC
import AVFoundation

class WHEPClient: NSObject, ObservableObject, RTCPeerConnectionDelegate {
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        
    }
    
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
//        switch newState {
//        case .checking:
//            print("ICE is checking paths, this might take a moment.")
//        case .connected:
//            print("ICE has found a viable connection.")
//        case .failed:
//            print("No viable ICE paths found, consider a retry or using TURN.")
//        case .disconnected:
//            print("ICE connection was disconnected, attempting to reconnect or refresh.")
//        case .new:
//            print("The ICE agent is gathering addresses or is waiting to be given remote candidates through calls")
//        case .completed:
//            print("The ICE agent has finished gathering candidates, has checked all pairs against one another, and has found a connection for all components.")
//        case .closed:
//            print("The ICE agent for this RTCPeerConnection has shut down and is no longer handling requests.")
//        default:
//            break
//        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        print("Nowy kandydat ICE:", candidate);

        guard candidate.sdpMLineIndex == 0 else {
            return
        }

        self.candidates.append(candidate)

        if candidate.sdp.isEmpty {
            self.endOfCandidates = true
        }

        if iceTrickleTimer == nil && !restartIce! {
            print("here")
            schedulePatch()
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCPeerConnectionState) {
        switch stateChanged {
        case .connected:
            print("Connection is fully connected")
            fetchConnectionStats()
        case .disconnected:
            print("One or more transports has disconnected unexpectedly")
        case .failed:
            print("One or more transports has encountered an error")
        case .closed:
            print("Connection has been closed")
        case .new:
            print("New connection")
        case .connecting:
            print("Connecting")
        default:
            print("Some other state: \(stateChanged.rawValue)")
        }
    }
    
    var iceUsername: String?
    var icePassword: String?
    var candidates: [RTCIceCandidate] = []
    var endOfCandidates: Bool = false
    var pc: RTCPeerConnection?
    var token: String?
    var iceTrickleTimer: Timer?
    var restartIce: Bool?
    var resourceURL: URL?
    var etag: String?
    
    private var patchQueue = DispatchQueue(label: "patchQueue")
    private var patchSemaphore = DispatchSemaphore(value: 1)
    
    override init() {
        self.iceUsername = nil
        self.icePassword = nil
        self.candidates = []
        self.endOfCandidates = false
        self.restartIce = false
    }

    func onOffer(_ offer: String) -> String {
        return offer
    }

    func onAnswer(_ answer: String) -> String {
        return answer
    }
    
    func view(pc: RTCPeerConnection, url: URL, token: String?) async throws {
        guard self.pc == nil else {
            throw NSError(domain: "WHIPClient", code: 0, userInfo: [NSLocalizedDescriptionKey: "Already publishing"])
        }
        self.pc = pc
        self.token = token
        let constraints = RTCMediaConstraints(mandatoryConstraints: ["OfferToReceiveAudio": "true", "OfferToReceiveVideo": "true"], optionalConstraints: nil)

        
        let offer = try await pc.offer(for: constraints)
        print(offer)
        
        var headers = ["Content-Type": "application/sdp"]
        if let authToken = token {
            headers["Authorization"] = "Bearer \(authToken)"
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = offer.sdp.data(using: .utf8)
        request.allHTTPHeaderFields  = headers
        request.timeoutInterval = 120
        
        let session = URLSession.shared

        let (data, response) = try await session.data(for: request)
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
        self.resourceURL = resourceURL
        
        print("Resource URL: \(resourceURL)")
        
        //let links = processLinkHeaders(from: httpResponse)

        guard let answerSDP = String(data: data, encoding: .utf8), !answerSDP.isEmpty else {
            throw NSError(domain: "SDPError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to decode SDP answer from HTTP response"])
        }
        print(answerSDP)
        
        try await pc.setLocalDescription(offer)
        if let iceUsername = extractFromSDP(sdp: offer.sdp, pattern: "a=ice-ufrag:(.*)\r\n") {
            print("ICE Username: \(iceUsername)")
        } else {
            print("ICE Username not found")
        }

        if let icePassword = extractFromSDP(sdp: offer.sdp, pattern: "a=ice-pwd:(.*)\r\n") {
            print("ICE Password: \(icePassword)")
        } else {
            print("ICE Password not found")
        }
        
        let remoteDescription = RTCSessionDescription(type: .answer, sdp: answerSDP)
        try await pc.setRemoteDescription(remoteDescription)
        
//        guard let etag = httpResponse.allHeaderFields["etag"] as? String else {
//            throw NSError(domain: "HTTPError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Response missing etag header"])
//        }
        
        if iceTrickleTimer == nil {
            schedulePatch()
        }
    }
    
    func patch() async throws {
        print("Started patch")
        self.iceTrickleTimer?.invalidate()
        self.iceTrickleTimer = nil
        
        if !(self.candidates.isEmpty || endOfCandidates || (restartIce != nil)) || resourceURL == nil {
            print(!(self.candidates.isEmpty || endOfCandidates || (restartIce != nil)))
            print(resourceURL == nil)
            return
        }
        
        let candidates = self.candidates
        let endOfCandidates = self.endOfCandidates
        let restartIce = self.restartIce

        self.candidates = []
        self.endOfCandidates = false
        guard let iceUsername = self.iceUsername, let icePassword = self.icePassword else { return }
        var fragment = "a=ice-ufrag:\(iceUsername)\r\n" + "a=ice-pwd:\(icePassword)\r\n"
        guard let transceivers = self.pc?.transceivers else { return }
        
        var medias = [String: MediaObject]()
            if !candidates.isEmpty || endOfCandidates {
                if let firstTransceiver = transceivers.first {
                    let media = MediaObject(
                        mid: firstTransceiver.mid ,
                        kind: firstTransceiver.receiver.track!.kind,
                        candidates: []
                    )
                    medias[firstTransceiver.mid] = media
                }
            }
        
        print(medias)
        for candidate in candidates {
            guard let mid = candidate.sdpMid else { continue }

            // Znajdź odpowiedni transceiver z tym samym mid
            if let transceiver = transceivers.first(where: { $0.mid == mid }) {

                // Pobierz media lub stwórz nowy obiekt MediaObject, jeśli nie istnieje
                let media = medias[mid] ?? MediaObject(mid: mid,
                                                       kind: transceiver.receiver.track!.kind,
                                                      candidates: [])

                // Dodaj kandydata do listy kandydatów w obiekcie Media
                var updatedMedia = media
                updatedMedia.candidates.append(candidate)
                medias[mid] = updatedMedia
            }
        }

                // Przechodzenie przez wszystkie obiekty mediów
        for (_, media) in medias {
            // Dodawanie definicji mediów do fragmentu
            fragment += "m=\(media.kind) 9 UDP/TLS/RTP/SAVPF 0\r\n"
            fragment += "a=mid:\(media.mid)\r\n"
            
            // Dodawanie kandydatów
            for candidate in media.candidates {
                fragment += "a=\(candidate.sdp)\r\n"
            }

            // Dodawanie znacznika końca kandydatów, jeśli jest potrzebny
            if endOfCandidates {
                fragment += "a=end-of-candidates\r\n"
            }
        }
        
        var headers = [
                    "Content-Type": "application/trickle-ice-sdpfrag"
                ]

        if restartIce! {
            headers["If-Match"] = "*"
        } else if let etag = self.etag {
            headers["If-Match"] = etag
        }
        
        // Dodanie nagłówka autoryzacji, jeśli token istnieje
        if let token = self.token {
            headers["Authorization"] = "Bearer \(token)"
        }

        var request = URLRequest(url: self.resourceURL!)
        request.httpMethod = "PATCH"
        request.httpBody = fragment.data(using: .utf8)
        request.allHTTPHeaderFields = headers
        
        print(request)

        let task = URLSession.shared.dataTask(with: request) { [self] data, response, error in
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Error: No response from server")
                return
            }
            
            print(httpResponse)

            if !(200...299).contains(httpResponse.statusCode) && httpResponse.statusCode != 501 && httpResponse.statusCode != 405 {
                print("Request rejected with status \(httpResponse.statusCode)")
                return
            }

            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                print("Response: \(responseString)")
            }
            
            guard restartIce!, httpResponse.statusCode == 200 else {
                    return
                }

            let fetchedText = String(data: data!, encoding: .utf8) ?? ""
                
                // Parse iceUsername and icePassword
                let iceUsernamePattern = "a=ice-ufrag:(.*)\\r\\n"
                let icePasswordPattern = "a=ice-pwd:(.*)\\r\\n"
            let iceUsername = fetchedText.matchingStrings(regex: "a=ice-ufrag:(.*)\\r\\n").first?[1] ?? ""
                let icePassword = fetchedText.matchingStrings(regex: "a=ice-pwd:(.*)\\r\\n").first?[1] ?? ""

//            guard var remoteDescription = pc?.remoteDescription else {
//                    return
//                }
//
//                let modifiedSDP = modifySDP(remoteDescription.sdp, fetchedText: fetchedText, iceUsername: iceUsername, icePassword: icePassword)
//
//                // Create new RTCSessionDescription
//                if let newRemoteDescription = RTCSessionDescription(type: remoteDescription.type, sdp: modifiedSDP) {
//                    do {
//                        try pc!.setRemoteDescription(newRemoteDescription)
//
//                        // After updating, clean flags and trigger patch if needed
//                        if self.restartIce == restartIce {
//                            self.restartIce = nil
//                            if !candidates.isEmpty || endOfCandidates {
//                                Task {
//                                    do {
//                                        try await self.patch()
//                                    } catch {
//                                        print("An error occurred: \(error)")
//                                    }
//                                }
//                            }
//                        }
//                    } catch {
//                        print("Failed to set remote description: \(error)")
//                    }
//                }
        }
        task.resume()
        


    }
    
    func createLocalVideoTrack(factory: RTCPeerConnectionFactory) -> RTCVideoTrack? {
        let videoSource = factory.videoSource()
        videoSource.adaptOutputFormat(toWidth: 640, height: 480, fps: 30)

        if let captureDevice = AVCaptureDevice.default(for: .video),
           let deviceInput = try? AVCaptureDeviceInput(device: captureDevice) {
            
            // Konfiguracja Capturer
            let capturer = RTCCameraVideoCapturer(delegate: videoSource)
            capturer.startCapture(with: captureDevice, format: deviceInput.device.activeFormat, fps: 30)
            
            let videoTrack = factory.videoTrack(with: videoSource, trackId: "video0")
            return videoTrack
        }
        return nil
    }
    
    func startCaptureLocalMedia(captureSession: AVCaptureSession, peerFactory: RTCPeerConnectionFactory) -> (RTCVideoTrack?, RTCAudioTrack?) {
        let videoSource = peerFactory.videoSource()
        let videoTrack = peerFactory.videoTrack(with: videoSource, trackId: "video0")
        captureSession.addOutput(AVCaptureVideoDataOutput())
        
        let capturer = RTCCameraVideoCapturer(delegate: videoSource)
        if let device = AVCaptureDevice.devices().first(where: { $0.position == .front }) {
            let formats = RTCCameraVideoCapturer.supportedFormats(for: device)
            let format = formats.first!
            let fps = format.videoSupportedFrameRateRanges.first { range in
                range.maxFrameRate >= 15.0
            }?.maxFrameRate ?? 30.0
            
            capturer.startCapture(with: device, format: format, fps: Int(fps))
        }

        return (videoTrack, nil)
    }
    
    func extractFromSDP(sdp: String, pattern: String) -> String? {
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        let matches = regex.matches(in: sdp, options: [], range: NSRange(sdp.startIndex..., in: sdp))
        
        if let match = matches.first {
            if let range = Range(match.range(at: 1), in: sdp) {
                return String(sdp[range])
            }
        }
        return nil
    }
    
    func processLinkHeaders(from httpResponse: HTTPURLResponse) -> [String: [(url: URL, params: [String: String])]] {
        guard let linkHeader = httpResponse.allHeaderFields["Link"] as? String else {
            print("No link header found")
            return [:]
        }
        
        let linkHeaders = linkHeader.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        
        var links: [String: [(url: URL, params: [String: String])]] = [:]
        
        for header in linkHeaders {
            let parts = header.split(separator: ";").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            guard let urlString = parts.first(where: { $0.starts(with: "<") && $0.hasSuffix(">") })?.trimmingCharacters(in: CharacterSet(charactersIn: "<>")) else {
                continue
            }
            
            guard let url = URL(string: urlString) else {
                print("Invalid URL in link header: \(urlString)")
                continue
            }
            
            var params: [String: String] = [:]
            for part in parts.dropFirst() {
                let keyValPair = part.split(separator: "=", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                if keyValPair.count == 2 {
                    let key = keyValPair[0].trimmingCharacters(in: .whitespacesAndNewlines)
                    let val = keyValPair[1].trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
                    params[key] = val
                }
            }
            
            if let rel = params["rel"] {
                if links[rel] == nil {
                    links[rel] = []
                }
                links[rel]?.append((url, params))
            }
        }
        
        print(links)
        return links
    }
    
    private func replaceIceAttributes(_ sdp: String, username: String, password: String) -> String {
        var modifiedSdp = sdp
        modifiedSdp = modifiedSdp.replacingOccurrences(of: "(a=ice-ufrag:)(.*)\\r\\n", with: "$1\(username)\\r\\n")
        modifiedSdp = modifiedSdp.replacingOccurrences(of: "(a=ice-pwd:)(.*)\\r\\n", with: "$1\(password)\\r\\n")
        return modifiedSdp
    }

    private func removeCandidates(_ sdp: String) -> String {
        return sdp.replacingOccurrences(of: "(a=candidate:.*\\r\\n)", with: "")
    }
    
    private func modifySDP(_ sdp: String, fetchedText: String, iceUsername: String, icePassword: String) -> String {
        var modifiedSDP = sdp

        modifiedSDP = modifiedSDP.replacingOccurrences(of: "(a=ice-ufrag:)(.*)\\r\\n", with: "$1\(iceUsername)\\r\\n", options: .regularExpression)
        modifiedSDP = modifiedSDP.replacingOccurrences(of: "(a=ice-pwd:)(.*)\\r\\n", with: "$1\(icePassword)\\r\\n", options: .regularExpression)
        modifiedSDP = modifiedSDP.replacingOccurrences(of: "(a=candidate:.*\\r\\n)", with: "", options: .regularExpression)

        let candidates = fetchedText.matchingStrings(regex: "(a=candidate:.*\\r\\n)").map { $0[0] }
        if let mLine = modifiedSDP.matchingStrings(regex: "(m=.*\\r\\n)").first?[0] {
            modifiedSDP = modifiedSDP.replacingOccurrences(of: mLine, with: mLine + candidates.joined(), options: .regularExpression)
        }

        return modifiedSDP
    }
    
    private func schedulePatch() {
        patchQueue.async { [weak self] in
            guard let self = self else { return }

            Task {
                do {
                    try await self.patch()
                    print("Patch operation completed successfully.")
                } catch {
                    print("An error occurred during the patch operation: \(error)")
                }
            }
        }
    }
    
    func fetchConnectionStats() {
        pc?.statistics { report in
            for stats in report.statistics.values {
                if stats.type == "candidate-pair" && stats.values["state"] as! String == "succeeded" {
                    print("Active Candidate Pair:")
                    print("Local Candidate ID: \(stats.values["localCandidateId"] )")
                    print("Remote Candidate ID: \(stats.values["remoteCandidateId"] )")
                    self.printCandidateDetails(stats.values["localCandidateId"] as? String, in: report)
                    self.printCandidateDetails(stats.values["remoteCandidateId"] as? String, in: report)
                }
            }
        }
    }

    func printCandidateDetails(_ candidateId: String?, in report: RTCStatisticsReport) {
        guard let candidateId = candidateId,
              let candidateStats = report.statistics[candidateId] else {
            print("Candidate details not found.")
            return
        }
        
        print("Candidate ID: \(candidateId)")
        print("Type: \(candidateStats.values["candidateType"] )")
        print("Protocol: \(candidateStats.values["protocol"] )")
        print("Address: \(candidateStats.values["ip"])")
        print("Port: \(candidateStats.values["port"])")
    }
    
    struct MediaObject {
        var mid: String
        var kind: String
        var candidates: [RTCIceCandidate]
    }
}

