import { StyleSheet, Button, View, ActivityIndicator } from 'react-native';

import { useEffect, useState } from 'react';
import {
  cameras,
  connectWhipClient,
  createWhipClient,
  disconnectWhipClient,
  WhipClientView,
} from '@mobile-whep/react-native-client';
import { usePermissionCheck } from '@/hooks/usePermissionCheck';

export default function HomeScreen() {
  const [isLoading, setIsLoading] = useState(false);
  const [shouldShowStreamBtn, setShouldShowStreamBtn] = useState(true);

  usePermissionCheck();

  const handleStreamBtnClick = async () => {
    setShouldShowStreamBtn(false);
    try {
      setIsLoading(true);
      await connectWhipClient();
      setIsLoading(false);
    } catch (error) {
      console.error('Failed to connect to WHIP Client', error);
    }
  };

  useEffect(() => {
    const initialize = async () => {
      const availableDevices = cameras;
      createWhipClient(
        process.env.EXPO_PUBLIC_WHIP_SERVER_URL ?? '',
        {
          authToken: 'example',
        },
        availableDevices[0].id,
      );
    };

    initialize();
    return () => {
      disconnectWhipClient();
    };
  }, []);

  return (
    <View style={styles.container}>
      <View style={styles.box}>
        <WhipClientView style={styles.clientView} />
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
    justifyContent: 'center',
    alignItems: 'center',
  },
  clientView: {
    width: '100%',
    height: 200,
    marginBottom: 20,
  },
});
