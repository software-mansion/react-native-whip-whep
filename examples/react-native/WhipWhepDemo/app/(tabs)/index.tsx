import { Image, StyleSheet, Platform, Button, View } from "react-native";

import { HelloWave } from "@/components/HelloWave";
import ParallaxScrollView from "@/components/ParallaxScrollView";
import { ThemedText } from "@/components/ThemedText";
import { ThemedView } from "@/components/ThemedView";

import * as ReactNativeClient from "@mobile-whep/react-native-client";
import { PERMISSIONS, request, RESULTS } from "react-native-permissions";
import { useEffect, useState } from "react";
import { VideoParameters } from "@mobile-whep/react-native-client/build/ReactNativeClient.types";
import { ReactNativeClientView } from "@mobile-whep/react-native-client";

const requestPermissions = async () => {
  try {
    const cameraPermission = await request(
      Platform.select({
        android: PERMISSIONS.ANDROID.CAMERA,
        ios: PERMISSIONS.IOS.CAMERA,
      }),
    );

    const microphonePermission = await request(
      Platform.select({
        android: PERMISSIONS.ANDROID.RECORD_AUDIO,
        ios: PERMISSIONS.IOS.MICROPHONE,
      }),
    );

    if (
      cameraPermission === RESULTS.GRANTED &&
      microphonePermission === RESULTS.GRANTED
    ) {
      console.log("All permissions granted");
    } else {
      console.log("Please provide camera and microphone permissions.");
    }
  } catch (error) {
    console.error("Failed to request permission", error);
  }
};

export default function HomeScreen() {
  useEffect(() => {
    requestPermissions();
  }, []);

  useEffect(() => {
    ReactNativeClient.addTrackListener((event) => {
      console.log("Track added");
      console.log(event);
    });
  }, []);

  const [isConnected, setIsConnected] = useState(false);

  const whepClient = ReactNativeClient.createWhepClient(
    "http://192.168.1.23:8829/whep",
    {
      authToken: "example",
      audioEnabled: true,
      videoEnabled: true,
      videoParameters: VideoParameters.presetFHD43,
    },
  );
  // const whipClient = ReactNativeClient.createWhipClient(
  //   "http://192.168.83.48:8829/whip",
  //   {
  //     authToken: "example",
  //     audioEnabled: true,
  //     videoEnabled: true,
  //     videoParameters: VideoParameters.presetFHD43,
  //   },
  // );
  // const clientToPass = whepClient;

  // console.log(whepClient);
  return (
    <ParallaxScrollView
      headerBackgroundColor={{ light: "#A1CEDC", dark: "#1D3D47" }}
      headerImage={
        <Image
          source={require("@/assets/images/partial-react-logo.png")}
          style={styles.reactLogo}
        />
      }
    >
      <ThemedView style={styles.titleContainer}>
        <ThemedText type="title">Welcome!</ThemedText>
        <HelloWave />
        <Button
          onPress={async () => {
            try {
              await ReactNativeClient.connectWhepClient();
              setIsConnected(true);
              console.log("Connected to WHEP Client");
            } catch (error) {
              console.error("Failed to connect to WHEP Client", error);
            }
          }}
          title="WHEP"
        />
        <Button
          onPress={async () => {
            try {
              await ReactNativeClient.connectWhipClient();
              console.log("Connected to WHIP Client");
            } catch (error) {
              console.error("Failed to connect to WHIP Client", error);
            }
          }}
          title="WHIP"
        />
      </ThemedView>
      <ThemedView style={styles.stepContainer}>
        <ThemedText type="subtitle">{ReactNativeClient.hello()}</ThemedText>
        <ThemedText>
          Edit{" "}
          <ThemedText type="defaultSemiBold">app/(tabs)/index.tsx</ThemedText>{" "}
          to see changes. Press{" "}
          <ThemedText type="defaultSemiBold">
            {Platform.select({ ios: "cmd + d", android: "cmd + m" })}
          </ThemedText>{" "}
          to open developer tools.
        </ThemedText>
      </ThemedView>

      <View style={{ width: 200, height: 200 }}>
        <ReactNativeClientView style={{ flex: 1 }} />
      </View>

      {/* <ReactNativeClientView client={whipClient} /> */}
    </ParallaxScrollView>
  );
}

const styles = StyleSheet.create({
  titleContainer: {
    flexDirection: "row",
    alignItems: "center",
    gap: 8,
  },
  stepContainer: {
    gap: 8,
    marginBottom: 8,
  },
  reactLogo: {
    height: 178,
    width: 290,
    bottom: 0,
    left: 0,
    position: "absolute",
  },
});
