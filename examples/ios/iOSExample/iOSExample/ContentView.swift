import SwiftUI

struct ContentView: View {
    @StateObject var player = WHEPPlayer(connectionOptions: ConnectionOptions(serverUrl: URL(string: "http://192.168.83.180:8829")!, whepEndpoint: "/whep", authToken: "example"))
    @StateObject var whipPlayer = WHIPPlayer(connectionOptions: ConnectionOptions(serverUrl: URL(string: "http://192.168.83.180:8829")!, whepEndpoint: "/whip", authToken: "example"))
    

    var body: some View {
        VStack {
            Text("WHEP:")
            if let videoTrack = player.videoTrack {
                    WebRTCVideoView(videoTrack: videoTrack)
                        .frame(width: 150, height: 150)
                } else {
                    Text("Stream loading...")
                }
            Button("Connect WHEP") {
                Task {
                    try await player.connect()
                }
            }
            Text("WHIP:")
            if whipPlayer.videoTrack != nil {
                CameraPreview(videoTrack: whipPlayer.videoTrack)
                    .frame(width: 150, height: 150)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.blue, lineWidth: 2))
            }else {
                Text("Preview loading...")
            }
            
            Button("Connect WHIP") {
                Task {
                    try await whipPlayer.connect()
                }
            }
        }
        .padding()
    }
    
}

#Preview {
    ContentView()
}
