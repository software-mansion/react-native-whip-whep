import { StyleSheet, Button, View, ActivityIndicator } from "react-native";

import { useEffect, useState } from "react";
import { requestPermissions } from "@/utils/RequestPermissions";
import {
  captureDevices,
  connectWhipClient,
  createWhipClient,
  disconnectWhipClient,
  PlayerType,
  WhipWhepClientView,
} from "@mobile-whep/react-native-client";

export default function HomeScreen() {
  const [isLoading, setIsLoading] = useState(false);
  const [shouldShowStreamBtn, setShouldShowStreamBtn] = useState(true);

  const handleStreamBtnClick = async () => {
    setShouldShowStreamBtn(false);
    try {
      setIsLoading(true);
      await connectWhipClient();
      setIsLoading(false);
    } catch (error) {
      console.error("Failed to connect to WHIP Client", error);
    }
  };

  useEffect(() => {
    const initialize = async () => {
      const hasPermissions = await requestPermissions();
      if (hasPermissions) {
        const availableDevices = captureDevices;
        console.log(availableDevices);

        createWhipClient(
          process.env.EXPO_PUBLIC_WHIP_SERVER_URL ?? "",
          {
            authToken: "example",
          },
          availableDevices[0],
        );
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
