import SwiftUI
import MobileWhipWhepClient
import AVFoundation
import WebRTC

struct ContentView: View {
    enum PlayerType {
        case whep_broadcaster
        case whep
        case whip
    }
    
    @State private var selectedPlayerType = PlayerType.whep_broadcaster {
            didSet {
                disconnectAll()
            }
        }
    @State var whepBroadcaster = WhepClient(serverUrl: URL(string: "https://broadcaster.elixir-webrtc.org/api/whep")!, configurationOptions: ConfigurationOptions(authToken: "example"))
    @State var whepPlayer = WhepClient(serverUrl: URL(string: Bundle.main.infoDictionary?["WhepServerUrl"] as? String ?? "")!, configurationOptions: ConfigurationOptions(authToken: "example"))
    @State var whipPlayer = WhipClient(serverUrl: URL(string: Bundle.main.infoDictionary?["WhipServerUrl"] as? String ?? "")!, configurationOptions: ConfigurationOptions(authToken: "example"), videoDevice: WhipClient.getCaptureDevices().first)
    
    var body: some View {
        VStack {
            Picker("Choose Player", selection: $selectedPlayerType) {
                Text("WHEP (broadcaster").tag(PlayerType.whep_broadcaster)
                Text("WHEP").tag(PlayerType.whep)
                Text("WHIP").tag(PlayerType.whip)
            }
            .pickerStyle(SegmentedPickerStyle())
            .onChange(of: selectedPlayerType) { _ in
                            disconnectAll()
                        }
            
            VStack {
                switch selectedPlayerType {
                case .whep_broadcaster:
                    VideoView(player: whepBroadcaster)
                        .frame(width: 200, height: 200)
                    Button("Connect WHEP") {
                        Task {
                            do {
                                try await whepBroadcaster.connect()
                            } catch is SessionNetworkError{
                                print("Session Network Error")
                            }
                        }
                    }
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
    
    func disconnectAll() {
        switch selectedPlayerType {
        case .whep_broadcaster:
            whepPlayer.disconnect()
        case .whep:
            whepBroadcaster.disconnect()
        case .whip:
            whepBroadcaster.disconnect()
            whepPlayer.disconnect()
            
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
