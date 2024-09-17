import { StyleSheet, Button, View, ActivityIndicator } from "react-native";

import { useEffect, useState } from "react";
import { requestPermissions } from "@/utils/RequestPermissions";
import {
  addTrackListener,
  captureDevices,
  PlayerType,
  useWhipClient,
  WhipWhepClientView,
} from "@mobile-whep/react-native-client";

export default function HomeScreen() {
  const [isLoading, setIsLoading] = useState(false);
  const [shouldShowStreamBtn, setShouldShowStreamBtn] = useState(true);
  const availableDevices = captureDevices;

  const { connectWhipClient, disconnectWhipClient } = useWhipClient(
    process.env.EXPO_PUBLIC_WHIP_SERVER_URL ?? "",
    {
      authToken: "example",
    },
    availableDevices[0],
  );

  const handleStreamBtnClick = async () => {
    setShouldShowStreamBtn(false);
    try {
      setIsLoading(true);
      await connectWhipClient();
      console.log("Connected to WHIP Client");
      setIsLoading(false);
    } catch (error) {
      console.error("Failed to connect to WHIP Client", error);
    }
  };

  useEffect(() => {
    const initialize = async () => {
      const hasPermissions = await requestPermissions();
      if (hasPermissions) {
        console.log("WHIP Client created");

        addTrackListener((event) => {
          console.log("Track added:", event);
        });
      }
    };

    initialize();
    return () => {
      disconnectWhipClient();
    };
  }, []);

  return (
    <View style={styles.container}>
      <View style={styles.box}>
        <WhipWhepClientView
          style={styles.clientView}
          playerType={PlayerType.WHIP}
        />
        {shouldShowStreamBtn && (
          <Button title="Stream" onPress={handleStreamBtnClick} />
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
