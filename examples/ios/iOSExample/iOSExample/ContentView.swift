import SwiftUI
import AVFoundation
import MobileWhepClient
import WebRTC

struct ContentView: View {
    enum PlayerType {
        case whep
        case whip
    }

    @State private var selectedPlayerType = PlayerType.whep
    @StateObject var whepPlayerViewModel = WHEPPlayerViewModel(player: WHEPClientPlayer(serverUrl: URL(string: ProcessInfo.processInfo.environment["WHEP_SERVER_URL"] ?? "")!, authToken: "example"))

    @StateObject var whipPlayer = WHIPClientPlayer(serverUrl: URL(string: ProcessInfo.processInfo.environment["WHIP_SERVER_URL"] ?? "")!, authToken: "example", audioDevice: AVCaptureDevice.default(for: .audio), videoDevice: AVCaptureDevice.default(for: .video))
    
    var body: some View {
        VStack {
            Picker("Choose Player", selection: $selectedPlayerType) {
                Text("WHEP").tag(PlayerType.whep)
                Text("WHIP").tag(PlayerType.whip)
            }
            .pickerStyle(SegmentedPickerStyle())
            
            VStack {
                switch selectedPlayerType {
                case .whep:
                    if let videoTrack = whepPlayerViewModel.videoTrack {
                        WebRTCVideoView(videoTrack: videoTrack)
                            .frame(width: 200, height: 200)
                    } else {
                        Text("Stream loading...")
                            .padding([.top, .bottom], 140)
                    }
                    Button("Connect WHEP") {
                        Task {
                            if whipPlayer.isConnected {
                                do {
                                    try whipPlayer.release()
                                } catch {
                                    print(error)
                                }
                            }
                            do {
                                try await whepPlayerViewModel.connect()
                            } catch is SessionNetworkError{
                                print("Session Network Error")
                            }
                        }
                    }
                case .whip:
                    if whipPlayer.videoTrack != nil {
                        CameraPreview(videoTrack: whipPlayer.videoTrack)
                            .frame(width: 200, height: 200)
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.blue, lineWidth: 2))
                            .padding([.top, .bottom], 50)
                    } else {
                        Text("Preview loading...")
                    }
                    
                    Button("Connect WHIP") {
                        Task {
                            do {
                                try await whipPlayer.connect()
                            } catch is SessionNetworkError {
                                print("Session Network Error")
                            }
                            
                        }
                    }
                }
            }
            
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
