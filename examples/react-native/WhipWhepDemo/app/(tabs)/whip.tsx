import { StyleSheet, Button, View, ActivityIndicator } from 'react-native';

import { useEffect, useRef, useState, useCallback } from 'react';
import {
  cameras,
  VideoParameters,
  WhipClient,
  WhipClientView,
} from 'react-native-whip-whep';
import { checkPermissions } from '@/utils/CheckPermissions';
import { useThemeColor } from '@/hooks/useThemeColor';

export default function HomeScreen() {
  const [isLoading, setIsLoading] = useState(false);
  const [shouldShowStreamBtn, setShouldShowStreamBtn] = useState(true);

  const whipClient = useRef<WhipClient>(
    new WhipClient({
      audioEnabled: true,
      videoEnabled: true,
      videoParameters: VideoParameters.presetFHD169,
      videoDeviceId: cameras[0].id,
    }),
  );

  const { tint } = useThemeColor();

  const handleStreamBtnClick = async () => {
    setShouldShowStreamBtn(false);
    try {
      setIsLoading(true);
      await whipClient.current.connect({
        serverUrl: process.env.EXPO_PUBLIC_WHIP_SERVER_URL ?? '',
        authToken: 'example',
      });
      setIsLoading(false);
    } catch (error) {
      console.error('Failed to connect to WHIP Client', error);
    }
  };

  const handleToggleCamera = useCallback(() => {
    whipClient.current.flipCamera()
  }, []);

  useEffect(() => {
    checkPermissions();
    return () => {
      // eslint-disable-next-line react-hooks/exhaustive-deps
      whipClient.current.disconnect();
    };
  }, [whipClient]);

  return (
    <View style={styles.container}>
      <View style={styles.box}>
        <WhipClientView style={styles.clientView} />
        <Button title="Toggle Camera" onPress={handleToggleCamera} />
        {shouldShowStreamBtn && (
          <Button title="Stream" onPress={handleStreamBtnClick} color={tint} />
        )}
        {isLoading && <ActivityIndicator size="large" color={tint} />}
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
