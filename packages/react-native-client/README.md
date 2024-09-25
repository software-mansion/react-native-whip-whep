# WHIP/WHEP react-native-client

An implementation of WHIP and WHEP protocols for React Native. Provides basic methods for establishing a connection in order to stream or receive media.

This repository is an expo module that makes use of native Android and iOS packages and allows to use them in a React Native App with the code provided in `src/ReactNativeMobileWhepClientModule.ts` and the exports in `src/index.ts`. It also provides two simple native views - `WhepClientView` and `WhipClientView` to show the stream or camera preview.

## Examples

The `examples/react-native` folder provides an example app that allows to stream media using phone's default video and audio devices and receive remote stream.

## Usage

In order to use the package functionalities and run the example app, a WHIP/WHEP server is necessary. It is recommended to use the [WHIP/WHEP server](https://github.com/elixir-webrtc/ex_webrtc/tree/9e1888185211c8da7128db7309584af8e863fafa/examples/whip_whep) provided by `elixir-webrtc`, as it was utilized during the development.

## Copyright and License

Copyright 2024, [Software Mansion](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=whip-whep-client)

[![Software Mansion](https://logo.swmansion.com/logo?color=white&variant=desktop&width=200&tag=react-client)](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=whip-whep-client)

Licensed under the [MIT License](LICENSE)
