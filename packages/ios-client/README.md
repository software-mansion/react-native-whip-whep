# WHIP/WHEP ios-client

An implementation of WHIP and WHEP protocols for iOS. Provides basic methods for establishing a connection in order to stream or receive media.

## Components

The repository consists of 6 main components:

- `WhepClient` - a class that handles WHEP connection and receiving media stream,
- `WhipClient` - a class that handles WHIP connection and sending media stream,
- `ClientBase` - provides methods that are shared by both players,
- `ConfigurationOptions` - a structure that holds optional initial connection configuration options, like STUN server URL, authorization token or stream limitations, for example sending only audio or video track,
- `Errors` - contains all the errors that can be thrown by the package,
- `VideoView` - provides a basic view for WHIP camera/WHEP player.

## Examples

The `examples/ios` folder provides an example app that allows to stream media using phone's default video and audio devices and receive remote stream.

## Usage

In order to use the package functionalities and run the example app, a WHIP/WHEP server is necessary. It is recommended to use the [WHIP/WHEP server](https://github.com/elixir-webrtc/ex_webrtc/tree/9e1888185211c8da7128db7309584af8e863fafa/examples/whip_whep) provided by `elixir-webrtc`, as it was utilized during the development.

## Copyright and License

Copyright 2024, [Software Mansion](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=whip-whep-client)

[![Software Mansion](https://logo.swmansion.com/logo?color=white&variant=desktop&width=200&tag=react-client)](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=whip-whep-client)

Licensed under the [MIT License](LICENSE)
