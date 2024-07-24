import SwiftUI
import AVFoundation
import WebRTC

struct ContentView: View {
    @StateObject var player = WHEPPlayer(connectionOptions: ConnectionOptions(serverUrl: URL(string: "http://192.168.83.105:8829")!, whepEndpoint: "/whep", authToken: "example"))
    @StateObject var whipPlayer = WHIPPlayer(connectionOptions: ConnectionOptions(serverUrl: URL(string: "http://192.168.83.105:8829")!, whepEndpoint: "/whip", authToken: "example"))

    var body: some View {
        VStack {
            Text("WHEP:")
            if let videoTrack = player.videoTrack {
                    WebRTCVideoView(videoTrack: videoTrack)
                        .frame(width: 300, height: 300)
                } else {
                    Text("Ładowanie strumienia...")
                }
            Button("Connect WHEP") {
                Task {
                    try await player.connect()
                }
            }
            Text("WHIP:")
            Button("Connect WHIP") {
                Task {
                    whipPlayer.setupLocalMedia()
                    try await whipPlayer.connect()
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
