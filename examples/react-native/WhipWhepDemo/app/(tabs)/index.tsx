import {
  StyleSheet,
  Platform,
  Button,
  View,
  ActivityIndicator,
} from "react-native";

import * as ReactNativeClient from "@mobile-whep/react-native-client";
import {
  Permission,
  PERMISSIONS,
  request,
  RESULTS,
} from "react-native-permissions";
import { useEffect, useState } from "react";
import { VideoParameters } from "@mobile-whep/react-native-client/build/ReactNativeClient.types";
import { ReactNativeClientView } from "@mobile-whep/react-native-client";

const requestPermissions = async (): Promise<boolean> => {
  try {
    const cameraPermission = await request(
      Platform.select({
        android: PERMISSIONS.ANDROID.CAMERA,
        ios: PERMISSIONS.IOS.CAMERA,
      }) as Permission,
    );

    const microphonePermission = await request(
      Platform.select({
        android: PERMISSIONS.ANDROID.RECORD_AUDIO,
        ios: PERMISSIONS.IOS.MICROPHONE,
      }) as Permission,
    );

    if (
      cameraPermission === RESULTS.GRANTED &&
      microphonePermission === RESULTS.GRANTED
    ) {
      console.log("All permissions granted");
      return true;
    } else {
      console.log("Please provide camera and microphone permissions.");
      return false;
    }
  } catch (error) {
    console.error("Failed to request permission", error);
    return false;
  }
};

export default function HomeScreen() {
  const [isLoading, setIsLoading] = useState(false);
  const [shouldShowPlayBtn, setShouldShowPlayBtn] = useState(true);

  const handlePlayBtnClick = async () => {
    setShouldShowPlayBtn(false);
    setIsLoading(true);
    try {
      await ReactNativeClient.connectWhepClient();
      console.log("Connected to WHEP Client");
      setIsLoading(false);
    } catch (error) {
      console.error("Failed to connect to WHEP Client", error);
    }
  };

  useEffect(() => {
    const initialize = async () => {
      const hasPermissions = await requestPermissions();
      if (hasPermissions) {
        ReactNativeClient.createWhepClient("http://192.168.1.23:8829/whep", {
          authToken: "example",
          audioEnabled: true,
          videoEnabled: true,
          videoParameters: VideoParameters.presetFHD43,
        });

        console.log("WHEP Client created");

        ReactNativeClient.addTrackListener((event) => {
          console.log("Track added:", event);
        });

        return () => {
          ReactNativeClient.disconnectWhepClient();
        };
      }
    };

    initialize();
  }, []);

  return (
    <View style={styles.container}>
      <View style={styles.box}>
        {!isLoading && <ReactNativeClientView style={styles.clientView} />}
        {shouldShowPlayBtn && (
          <Button title="Play" onPress={handlePlayBtnClick} />
        )}
        {isLoading && <ActivityIndicator size="large" color="#2196F3" />}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    paddingTop: 50,
  },
  box: {
    flex: 1,
    justifyContent: "center",
    alignItems: "center",
  },
  clientView: {
    width: "100%",
    height: 200,
    marginBottom: 20,
  },
});
