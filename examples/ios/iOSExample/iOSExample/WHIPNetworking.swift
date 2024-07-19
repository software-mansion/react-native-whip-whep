import Foundation
import WebRTC

extension WHIPClient {
    func sendCreateOffer(offer: RTCSessionDescription, to url: URL) {
        // Implementacja żądania POST
    }

    func sendPatchIceCandidates(url: URL, candidates: [RTCIceCandidate]) {
        // Implementacja żądania PATCH
    }

    func sendDeleteRequest(url: URL) {
        // Implementacja żądania DELETE
    }
}
