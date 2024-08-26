import SwiftUI
import MobileWhepClient
import AVFoundation
import WebRTC

struct ContentView: View {
    enum PlayerType {
        case whep
        case whip
    }

    @State private var selectedPlayerType = PlayerType.whep
    @StateObject var whepPlayerViewModel = WhipWhepViewModel(player: WhepClient(serverUrl: URL(string: "http://\(Bundle.main.infoDictionary?["WhepServerUrl"] as? String ?? "")")!, configurationOptions: ConfigurationOptions(authToken: "example")))
    @StateObject var whipPlayerViewModel = WhipWhepViewModel(player: WhipClient(serverUrl: URL(string: "http://\(Bundle.main.infoDictionary?["WhipServerUrl"] as? String ?? "")")!, configurationOptions: ConfigurationOptions(authToken: "example"), videoDevice: AVCaptureDevice.default(for: .video)))
    
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
                        WhipWhepView(videoTrack: videoTrack)
                            .frame(width: 200, height: 200)
                    } else {
                        Text("Stream loading...")
                            .padding([.top, .bottom], 140)
                    }
                    Button("Connect WHEP") {
                        Task {
                            do {
                                try await whepPlayerViewModel.connect()
                            } catch is SessionNetworkError{
                                print("Session Network Error")
                            }
                        }
                    }
                case .whip:
                    if let videoTrack = whipPlayerViewModel.videoTrack  {
                        WhipWhepView(videoTrack: videoTrack)
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
                                try await whipPlayerViewModel.connect()
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
