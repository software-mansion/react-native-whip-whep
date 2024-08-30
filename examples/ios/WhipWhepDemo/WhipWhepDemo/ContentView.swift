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
    @State var whepPlayer = WhepClient(serverUrl: URL(string: "\(Bundle.main.infoDictionary?["WhepServerUrl"] as? String ?? "")")!, configurationOptions: ConfigurationOptions(authToken: "example"))
    @State var whipPlayer = WhipClient(serverUrl: URL(string: "\(Bundle.main.infoDictionary?["WhipServerUrl"] as? String ?? "")")!, configurationOptions: ConfigurationOptions(authToken: "example"), videoDevice: AVCaptureDevice.default(for: .video))
    
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
                    VideoView(player: whepPlayer)
                        .frame(width: 200, height: 200)
                    Button("Connect WHEP") {
                        Task {
                            do {
                                try await whepPlayer.connect()
                            } catch is SessionNetworkError{
                                print("Session Network Error")
                            }
                        }
                    }
                case .whip:
                    VideoView(player: whipPlayer)
                        .frame(width: 200, height: 200)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.blue, lineWidth: 2))
                        .padding([.top, .bottom], 50)
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
