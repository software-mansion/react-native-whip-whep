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
    //@State private var videoTrack: RTCVideoTrack?
    @StateObject var player = WHEPPlayer(connectionOptions: ConnectionOptions(serverUrl: URL(string: "http://192.168.83.105:8829")!, whepEndpoint: "/whep", authToken: "example"))

    var body: some View {
        VStack {
            if let videoTrack = player.videoTrack {
                            WebRTCVideoView(videoTrack: videoTrack)
                                .frame(width: 300, height: 300)
                        } else {
                            Text("Ładowanie strumienia...")
                        }
                    Text("kotki")
                }
                .onAppear {
                    Task {
                        //await startReceivingVideo()
                        Task {
                            try await player.connect()
                        }

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
        .padding()
        
    }
    
    
//    func startReceivingVideo() async {
//        let whepClient = WHEPClient()
//        let url = URL(string: "http://192.168.83.130:8829/whep/")!
//        let token = "example"
//        let configuration = RTCConfiguration()
//        configuration.iceServers = [RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"])]
//        let constraints = RTCMediaConstraints(mandatoryConstraints: ["OfferToReceiveAudio": "true", "OfferToReceiveVideo": "true"], optionalConstraints: nil)
//        let peerFactory = RTCPeerConnectionFactory()
//        let pc = peerFactory.peerConnection(with: configuration, constraints: constraints, delegate: whepClient)
//        do {
//            try await whepClient.view(pc: pc!, url: url, token: token)
//        } catch {
//            print("Wystąpił błąd: \(error)")
//        }
//    }
    
}

#Preview {
    ContentView()
}
