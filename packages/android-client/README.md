<img src="../../.github/images/whipwhep_github.png" width="100%">

# WHIP/WHEP android-client

An implementation of WHIP and WHEP protocols for Android. Provides basic methods for establishing a connection in order to stream or receive media.

## Components

The repository consists of 7 main components:

- `WhepClient` - a class that handles WHEP connection and receiving media stream,
- `WhipClient` - a class that handles WHIP connection and sending media stream,
- `ClientBase` - provides methods that are shared by both players,
- `ConfigurationOptions` - a structure that holds optional initial connection configuration options, like STUN server URL, authorization token or stream limitations, for example sending only audio or video track,
- `Errors` - contains all the errors that can be thrown by the package,
- `SuspendableSdpObserver` - implements the SdpObserver interface used by the WebRTC library,
- `VideoView` - provides a basic view for WHIP camera/WHEP player.

## Examples

The `examples/android` folder provides an example app that allows to stream media using phone's default video and audio devices and receive remote stream.

## Usage

In order to use the package functionalities and run the example app, a WHIP/WHEP server is necessary. It is recommended to use the [WHIP/WHEP server](https://github.com/elixir-webrtc/ex_webrtc/tree/9e1888185211c8da7128db7309584af8e863fafa/examples/whip_whep) provided by `elixir-webrtc`, as it was utilized during the development.

## License

Licensed under the [MIT License](LICENSE)

## Android Whip Whep is created by Software Mansion

Since 2012 [Software Mansion](https://swmansion.com) is a software agency with experience in building web and mobile apps. We are Core React Native Contributors and experts in dealing with all kinds of React Native issues. We can help you build your next dream product – [Hire us](https://swmansion.com/contact/projects?utm_source=whip-whep-client&utm_medium=mobile-readme).

[![Software Mansion](https://logo.swmansion.com/logo?color=white&variant=desktop&width=200&tag=react-client)](https://swmansion.com/contact/projects?utm_source=whip-whep-client&utm_medium=mobile-readme)
