import { Image, StyleSheet, Platform, Button } from "react-native";

import { HelloWave } from "@/components/HelloWave";
import ParallaxScrollView from "@/components/ParallaxScrollView";
import { ThemedText } from "@/components/ThemedText";
import { ThemedView } from "@/components/ThemedView";

import * as MobileWhepClient from "mobile-whep-client";
import { MobileWhepClientView } from "mobile-whep-client";
import { PERMISSIONS, request, RESULTS } from "react-native-permissions";
import { useEffect } from "react";
import { VideoParameters } from "mobile-whep-client/build/MobileWhepClient.types";

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

  const whepClient = MobileWhepClient.createWhepClient(
    "http://192.168.83.201:8829/whep",
    {
      authToken: "example",
      audioEnabled: true,
      videoEnabled: true,
      videoParameters: VideoParameters.presetFHD43,
    },
  );
  // const whipClient = MobileWhepClient.createWhipClient(
  //   "http://192.168.83.201:8829/whip",
  //   {
  //     authToken: "example",
  //     audioEnabled: true,
  //     videoEnabled: true,
  //     videoParameters: VideoParameters.presetFHD43,
  //   },
  // );
  const clientToPass = whepClient;

  console.log(whepClient);
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
          onPress={async () => await MobileWhepClient.connectWhepClient()}
          title="whep"
        />
        <Button
          onPress={async () => await MobileWhepClient.connectWhipClient()}
          title="whip"
        />
      </ThemedView>
      <ThemedView style={styles.stepContainer}>
        <ThemedText type="subtitle">xd</ThemedText>
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
      <MobileWhepClientView client={clientToPass} />
      {/* <MobileWhepClientView client={whipClient} /> */}
      <ThemedView style={styles.stepContainer}>
        <ThemedText type="subtitle">Step 3: Get a fresh start</ThemedText>
        <ThemedText>
          When you're ready, run{" "}
          <ThemedText type="defaultSemiBold">npm run reset-project</ThemedText>{" "}
          to get a fresh <ThemedText type="defaultSemiBold">app</ThemedText>{" "}
          directory. This will move the current{" "}
          <ThemedText type="defaultSemiBold">app</ThemedText> to{" "}
          <ThemedText type="defaultSemiBold">app-example</ThemedText>.
        </ThemedText>
      </ThemedView>
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
