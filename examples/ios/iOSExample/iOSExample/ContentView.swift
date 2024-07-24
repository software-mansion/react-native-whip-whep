import SwiftUI
import AVFoundation
import WebRTC

struct ContentView: View {
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
    
}

#Preview {
    ContentView()
}
