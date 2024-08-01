# iOSExample

A simple example app showing the main functionalities of the WHIP/WHEP package. It consists of a viewtha, depending of whether WHIP or WHEP has been chosen, shows a camera preview or current media stream.

## WHEP

In order to initialize a player, a `StateObject` instance of a `WHEPClientPlayer` has to be created using a server URL and its token, if necessary. One can provide here some optional configuration, such as STUN server address.

```swift
 @StateObject var whepPlayer = WHEPClientPlayer(serverUrl: URL(string: "http://192.168.1.23:8829/whep")!,
authToken: "example")
```

After creating a player, all that has to be done is to invoke the `connect` method:

```swift
do {
    try await whepPlayer.connect()
} catch is SessionNetworkError {
    print("Session Network Error")
}
```

And display the stream, using `RTCMTLVideoView`:

```swift
if let videoTrack = whepPlayer.videoTrack {
    WebRTCVideoView(videoTrack: videoTrack)
        .frame(width: 200, height: 200)
}
```

### Screenshots:

<img width="600" alt="image" src="https://github.com/user-attachments/assets/2bba7323-c890-448e-90ef-f49a895020ee">
<img width="600" alt="image" src="https://github.com/user-attachments/assets/68a98b2c-76e1-4b4b-8daf-8b84ed7a6b82">


## WHIP 

To initialize a WHIP player, `audioDevice` and `videoDevice` should also be passed to `WHIPClientPlayer` constructor, as it has to be specified which devices will be used for the stream. Here, the default ones have been used. Remember to also check for the access to the camera and microphone, and request it and grant it if necessary.

```swift
   @StateObject var whipPlayer = WHIPClientPlayer(serverUrl: URL(string: "http://192.168.1.23:8829/whip")!, 
authToken: "example",
audioDevice: AVCaptureDevice.default(for: .audio),
videoDevice: AVCaptureDevice.default(for: .video))
```

For the connection, the flow is the same as for the WHEP player:
```swift
do {
    try await whipPlayer.connect()
} catch is SessionNetworkError {
    print("Session Network Error")
}
```

### Screenshots:

<img width="600" alt="image" src="https://github.com/user-attachments/assets/2ce68d9e-c6e2-4780-9301-69971659ada5">
<img width="600" alt="image" src="https://github.com/user-attachments/assets/30a403fb-9998-4a1a-9644-555324f028b6">
