//
//  ContentView.swift
//  iOSExample
//
//  Created by Justyna Gręda on 18/07/2024.
//

import SwiftUI
import AVFoundation
import WebRTC

struct ContentView: View {
    @State private var videoTrack: RTCVideoTrack?

    var body: some View {
        VStack {
                    Text("kotki")
                }
                .onAppear {
                    Task {
                        await startReceivingVideo()

                    }
                }
//        VStack {
//            let whipClient = WHIPClient()
//
//            CameraPreview(whipClient: whipClient)
//                            .frame(height: 300)
//                            .cornerRadius(12)
//                            .padding()
//                            
////            Button("List Devices") {
////                        Task {
////                            let whipClient = WHIPClient()
////                            let url = URL(string: "http://192.168.83.130:8829/whip/")!
////                            let token = "example"
////
////                            do {
////                                try await whipClient.publish(url: url, token: token)
////                                listDevices()
////                            } catch {
////                                print("Wystąpił błąd podczas publikacji: \(error)")
////                            }
////                        }
////                    }
//        }
        .padding()
        
    }
    
    
    func startReceivingVideo() async {
        let whepClient = WHEPClient()
        let url = URL(string: "http://192.168.83.130:8829/whep/")!
        let token = "example"
        let configuration = RTCConfiguration()
        configuration.iceServers = [RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"])]
        let constraints = RTCMediaConstraints(mandatoryConstraints: ["OfferToReceiveAudio": "true", "OfferToReceiveVideo": "true"], optionalConstraints: nil)
        let peerFactory = RTCPeerConnectionFactory()
        let pc = peerFactory.peerConnection(with: configuration, constraints: constraints, delegate: whepClient)
        try? await whepClient.view(pc: pc!, url: url, token: token)
    }
    
}

#Preview {
    ContentView()
}
