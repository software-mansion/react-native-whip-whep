//
//  ContentView.swift
//  iOSExample
//
//  Created by Justyna Gręda on 18/07/2024.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    var body: some View {
        VStack {
            let whipClient = WHIPClient()
            CameraPreview(whipClient: whipClient) // Dodajemy uchwyt kamery do naszego UI.
                            .frame(height: 300) // Określamy wysokość podglądu kamery.
                            .cornerRadius(12)
                            .padding()
                            
//            Button("List Devices") {
//                        Task {
//                            let whipClient = WHIPClient()
//                            let url = URL(string: "http://192.168.83.130:8829/whip/")!
//                            let token = "example"
//
//                            do {
//                                try await whipClient.publish(url: url, token: token)
//                                listDevices()
//                            } catch {
//                                print("Wystąpił błąd podczas publikacji: \(error)")
//                            }
//                        }
//                    }
        }
        .padding()
    }
    
    func listDevices() {
        let audioDevices = AVCaptureDevice.DiscoverySession(
            deviceTypes: [AVCaptureDevice.DeviceType.microphone],
            mediaType: .audio,
            position: .unspecified
        ).devices
        print("Available audio devices:")
        for device in audioDevices {
            print(device.localizedName)
        }
        
        let videoDevices = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .builtInTelephotoCamera, .builtInUltraWideCamera, .builtInDualCamera, .builtInDualWideCamera, .builtInTripleCamera, .builtInLiDARDepthCamera, .builtInTrueDepthCamera, .builtInWideAngleCamera],
            mediaType: .video,
            position: .unspecified
        ).devices
        print("Available video devices:")
        for device in videoDevices {
            print(device.localizedName)
        }
    }
}

#Preview {
    ContentView()
}
