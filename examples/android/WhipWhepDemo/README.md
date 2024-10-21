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
The server URLs are saved to environment variables. To use them, it is necessary to modify `local.properties` file and add the URLs to the bottom of the file:

```
WHEP_SERVER_URL=<your WHEP server URL>
WHIP_SERVER_URL=<your WHIP server URL>
```

## WHEP

In order to initialize a player, an instance of a `WhepClient` has to be created using a server URL and application context. One can provide here some optional configuration, such as authorization token or STUN server address if necessary.

```kotlin
val whepClient = remember {
  WhepClient(
    appContext = context,
    serverUrl = context.getString(R.string.WHEP_SERVER_URL),
    configurationOptions = ConfigurationOptions(authToken = "example")
  )
}
```

After creating a player, all that has to be done is to invoke the `connect` method:

```kotlin
whepClient.connect()
```

And display the stream using provided `VideoView`:

```kotlin
AndroidView(
  factory = { ctx ->
    VideoView(ctx).apply {
      player = whepPlayer
      this.setScalingType(RendererCommon.ScalingType.SCALE_ASPECT_FIT)
      this.setEnableHardwareScaler(true)
    }
  }
)
```

### Screenshots:

An OBS player streaming media to the server URL:

<img width="600" alt="image" src="https://github.com/user-attachments/assets/8ed00f4c-63d1-4888-978f-34bbaebda539">

An Android device receiving the stream from the server:

<img width="600" alt="image" src="https://github.com/user-attachments/assets/05e76005-066f-4286-9ab1-f39edeb58c07">

## WHIP

To initialize a WHIP client, `videoDevice` should also be passed to `WhipClient` constructor, as it has to be specified which device will be used for the stream. Remember to also check for the access to the camera and microphone, and request it and grant it if necessary.

```kotlin
val whipClient = remember {
  WhipClient(
    appContext = context,
    serverUrl = context.getString(R.string.WHIP_SERVER_URL),
    configurationOptions = ConfigurationOptions(authToken = "example"),
    videoDevice = deviceName?.let {
        VideoDevice(
            cameraEnumerator = cameraEnumerator,
            deviceName = it
        )
    }
  )
}
```

For the connection, the flow is the same as for the WHEP player:

```swift
whipClient.connect()
```

### Screenshots:

An Android device streaming back camera footage to the server:

<img width="600" alt="image" src="https://github.com/user-attachments/assets/09c19390-f77e-4ab3-b6ce-35d6767849bb">

Server website receiving the stream from the Android device:

<img width="600" alt="image" src="https://github.com/user-attachments/assets/420e8d70-9a38-4312-963a-df9b1dd10c8a">
