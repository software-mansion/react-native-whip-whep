# WHIP/WHEP ios-client

An implementation of WHIP and WHEP protocols for iOS. Provides basic methods for establishing a connection in order to stream or receive media.

## Components

The repository consists of 4 components:
- `WHEPPlayer` - a class that handles WHEP connection and receiving media stream
- `WHIPPlayer` - a class that handles WHIP connection and sending media stream
- `Helper` - provides methods that are shared by both players
- `ConfigurationOptions` - a structure that holds optional initial connection configuration options, like STUN server URL.

## Examples
The `examples/ios` folder provides an example app that allows to stream media using phone's default video and audio devices and receive remote stream. 

## Usage
In order to use the package functionalities and run the example app, a WHIP/WHEP server is necessary. It is recommended to use the [WHIP/WHEP server](https://github.com/elixir-webrtc/ex_webrtc/tree/9e1888185211c8da7128db7309584af8e863fafa/examples/whip_whep) provided by `elixir-webrtc`, as it was utilized during the development.
