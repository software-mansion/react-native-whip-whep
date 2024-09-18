# WhipWhepDemo

A simple expo app showing the main functionalities of the WHIP/WHEP package. It consists of a view that, depending of whether WHIP or WHEP has been chosen, shows a camera preview or current media stream.

## Server configuration

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

## Get started

1. Create a `.env` file in `examples/react-native/WhipWhepDemo` directory and put there server URLs details:
```
EXPO_PUBLIC_WHEP_SERVER_URL = <YOUR WHEP SERVER URL>
EXPO_PUBLIC_WHIP_SERVER_URL = <YOUR WHIP SERVER URL>
```
3. Install node_modules in project root directory:
```
yarn
```
2. Install node_modules in `examples/react-native/WhipWhepDemo` directory:
```
cd examples/react-native/WhipWhepDemo && yarn
```
3. Initialize the `android` and `ios` folders with native packages linked using expo prebuild:
```
expo prebuild
```
4. Install cocoapods:
```
cd ios && pod install
```
5. Start Metro bundler in `examples/react-native/WhipWhepDemo` directory:
```
yarn start
```
6. To run the application use
```
yarn android
```

or

```
yarn ios
```

depending on the platform.



