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
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
            Button("List Devices") {
                listDevices()
            }
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
