# react-native-whip-whep

An implementation of WHIP and WHEP protocols for React Native. Provides basic methods for establishing a connection in order to stream or receive media.

This repository is an expo module that makes use of native Android and iOS packages and allows to use them in a React Native App with the code provided in `src/ReactNativeMobileWhepClientModule.ts` and the exports in `src/index.ts`. It also provides two simple native views - `WhepClientView` and `WhipClientView` to show the stream or camera preview.

## Setup

```
$ npm install --save react-native-whip-whep
# --- or ---
$ yarn add react-native-whip-whep
```

It is necessary to configure app permissions in order to stream a preview from the camera or sound:

### Android

Modify `app.json` file to request necessary permissions:

```json
{
  "expo": {
    ...
    "android": {
      ...
      "permissions": {
        "android.permission.CAMERA",
        "android.permission.RECORD_AUDIO"
      }
    }
  }
}
```

### iOS

Add the following lines to `app.json`:

```json
{
  "expo": {
    ...
   "ios": {
      ...
      "infoPlist": {
        "NSCameraUsageDescription": "This application requires camera access to gather information about available video devices.",
        "NSMicrophoneUsageDescription": "This application requires microphone access to gather information about available audio devices."
      }
    },
  }
}
```

## Usage

In order to use the package functionalities and run the example app, a WHIP/WHEP server is necessary. It is recommended to use the [WHIP/WHEP server](https://github.com/elixir-webrtc/ex_webrtc/tree/9e1888185211c8da7128db7309584af8e863fafa/examples/whip_whep) provided by `elixir-webrtc`, as it was utilized during the development.

## Examples

The `examples/react-native` folder provides an example app that allows to stream media using phone's default video and audio devices and receive remote stream.

To create a WHEP client able to receive media stream use the following code. It requires a server URL and takes optional parameters, such as `authToken`, `audioEnabled`, `videoEnabled` (both of which defaults to true), `stunServerUrl` and `videoParameters`:

```typescript
createWhepClient(<WHEP_SERVER_URL>, {
  authToken: "example",
});
```

To receive a stream, simply connect the client to the server:

```typescript
await connectWhepClient();
```

After the stream is finished, it is recommended to disconnect the client to free the resources:

```typescript
disconnectWhepClient();
```

The process of creating a WHIP client is similar to the WHEP one, but the function takes one more parameter: a `videoDevice` that will be used to stream the video to the server. `react-native-whip-whep` shares a property to obtain all available video devices:

```typescript
import { cameras } from "@mobile-whep/react-native-client";

const availableDevices = cameras;
```

```typescript
createWhipClient(
  <WHIP_SERVER_URL>,
  {
    authToken: "example",
  },
  availableDevices[0].id,
);
```

## Copyright and License

Copyright 2024, [Software Mansion](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=whip-whep-client)

[![Software Mansion](https://logo.swmansion.com/logo?color=white&variant=desktop&width=200&tag=react-client)](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=whip-whep-client)

Licensed under the [MIT License](LICENSE)
