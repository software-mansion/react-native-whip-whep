import SwiftUI
import AVFoundation
import MobileWhepClient

struct ContentView: View {
    @StateObject var player = WHEPClientPlayer(serverUrl: URL(string: "http://192.168.83.40:8829/whep")!,authToken: "example")
    
    @StateObject var whipPlayer = WHIPClientPlayer(serverUrl: URL(string: "http://192.168.83.40:8829/whip")!,authToken: "example", audioDevice: AVCaptureDevice.default(for: .audio), videoDevice: AVCaptureDevice.default(for: .video))
    
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
