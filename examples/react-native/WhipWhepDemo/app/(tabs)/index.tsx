import {
  StyleSheet,
  Button,
  View,
  ActivityIndicator,
  Platform,
} from "react-native";

import { useEffect, useState } from "react";
import { requestPermissions } from "@/utils/RequestPermissions";
import {
  connectWhepClient,
  createWhepClient,
  disconnectWhepClient,
  PlayerType,
  WhipWhepClientView,
} from "@mobile-whep/react-native-client";

export default function HomeScreen() {
  const [isLoading, setIsLoading] = useState(false);
  const [shouldShowPlayBtn, setShouldShowPlayBtn] = useState(true);

  const handlePlayBtnClick = async () => {
    setShouldShowPlayBtn(false);
    setIsLoading(true);
    try {
      await connectWhepClient();
      setIsLoading(false);
    } catch (error) {
      console.error("Failed to connect to WHEP Client", error);
    }
  };

  useEffect(() => {
    const initialize = async () => {
      const hasPermissions = await requestPermissions();
      if (hasPermissions) {
        createWhepClient(process.env.EXPO_PUBLIC_WHEP_SERVER_URL ?? "", {
          authToken: "example",
        });
      }
    };

    initialize();

    return () => {
      disconnectWhepClient();
    };
  }, []);

  return (
    <View style={styles.container}>
      <View style={styles.box}>
        <WhipWhepClientView
          style={styles.clientView}
          playerType={PlayerType.WHEP}
        />
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
