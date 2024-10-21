![WhipWhep logo](./../../../.github/images/main_dark.png#gh-dark-mode-only)
![WhipWhep logo](./../../../.github/images/main_ligth.png#gh-light-mode-only)

# WhipWhepDemo

A simple example app showing the main functionalities of the WHIP/WHEP package. It consists of a view that, depending of whether WHIP or WHEP has been chosen, shows a camera preview or current media stream.

## Initial configuration

As stated in the package README file, for the server it is recommended to use the [ex_webrtc](https://github.com/elixir-webrtc/ex_webrtc/tree/9e1888185211c8da7128db7309584af8e863fafa/examples/whip_whep) server, as it is simple, easy to use and it was used during the package development. In order to run the server:

- Clone the `ex_webrtc` repo
- In the folder `examples/whip_whep/config` modify the file `config.exs` to use your IP address:
  ```
  config :whip_whep,
  ip: <your IP address>,
  port: 8829,
  token: "example"
  ```
- From the `whip_whep` folder run commands `mix deps.get` and `mix run --no-halt` (running the commands requires Elixir installed on your device, for example using `brew install elixir`)

To see the stream from your device, enter `http://<your IP address>:8829/index.html`. These instructions are available in the `ex_webrtc` repo as well.

The server URLs are saved to environment variables. To use them, it is necessary to modify template file `ServerSettings.xcconfig` with your URLs.
When the URLs are defined, it is required to edit the `Info.plist` file, either through text editor:

```
<key>WhepServerUrl</key>
<string>$(WHEP_SERVER_URL)</string>
<key>WhipServerUrl</key>
<string>$(WHIP_SERVER_URL)</string>
<key>NSCameraUsageDescription</key>
<string>This application requires camera access to gather information about available video devices.</string>
<key>NSMicrophoneUsageDescription</key>
<string>This application requires microphone access to gather information about available audio devices.</string>
```

or directly using Xcode:

<img width="600" alt="image" src="https://github.com/user-attachments/assets/0d9b7079-e0ff-43dd-ac53-1202dc5ee1ee">
 
The created configuration has to be added to target. After clicking on the `WhipWhepDemo` name in the project navigator on the left side of the editor window, there appears a `Info` tab with a `Configurations` section. The created `ServerSettings.xcconfig` file has to be added to both debug and release configurations:

<img width="600" alt="image" src="https://github.com/user-attachments/assets/9c2dc234-4d1a-48cc-bdf6-75825dc0111e">

## WHEP

In order to initialize a player, an instance of a `WhepClient` has to be created using a server URL. One can provide here some optional configuration, such as authorization token or STUN server address if necessary. In the example app, SwiftUI is used.

```swift
@State var whepPlayer = WhepClient(
    serverUrl: URL(string: "\(Bundle.main.infoDictionary?["WhepServerUrl"] as? String ?? "")")!,
    configurationOptions: ConfigurationOptions(authToken: "example")
)
```

After creating a player, all that has to be done is to invoke the `connect` method:

```swift
Task {
    do {
        try await whepPlayer.connect()
    } catch is SessionNetworkError{
        print("Session Network Error")
    }
}
```

And display the stream, using `VideoView`:

```swift
VideoView(player: whepPlayer)
    .frame(width: 200, height: 200)

```

### Screenshots:

An OBS player streaming media to the server URL:

<img width="600" alt="image" src="https://github.com/user-attachments/assets/2bba7323-c890-448e-90ef-f49a895020ee">

An iOS device receiving the stream from the server:

<img width="600" alt="image" src="https://github.com/user-attachments/assets/68a98b2c-76e1-4b4b-8daf-8b84ed7a6b82">

## WHIP

To initialize a WHIP player, `videoDevice` should also be passed to `WhipClient` constructor, as it has to be specified which device will be used for the stream. Here, the default one has been used. Remember to also check for the access to the camera and microphone, and request it and grant it if necessary.

```swift
@State var whipPlayer = WhipClient(
    serverUrl: URL(string: "\(Bundle.main.infoDictionary?["WhipServerUrl"] as? String ?? "")")!,
    configurationOptions: ConfigurationOptions(authToken: "example"),
    videoDevice: AVCaptureDevice.default(for: .video)
)
```

For the connection, the flow is the same as for the WHEP player:

```swift
Task {
    do {
        try await whipPlayer.connect()
    } catch is SessionNetworkError {
        print("Session Network Error")
    }
}
```

### Screenshots:

An iOS device streaming back camera footage to the server:

<img width="600" alt="image" src="https://github.com/user-attachments/assets/2ce68d9e-c6e2-4780-9301-69971659ada5">

Server website receiving the stream from the iOS device:

<img width="600" alt="image" src="https://github.com/user-attachments/assets/30a403fb-9998-4a1a-9644-555324f028b6">
