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

  const whipClient = useRef<WhipClient | null>();

  useEffect(() => {
    whipClient.current = new WhipClient({
      audioEnabled: true,
      videoEnabled: true,
      videoParameters: VideoParameters.presetFHD169,
      videoDeviceId: cameras[0].id,
    });

    return () => {
      whipClient.current?.disconnect();
      whipClient.current?.cleanup();
      whipClient.current = null;
    };
  }, []);

  const { tint } = useThemeColor();

  const handleStreamBtnClick = async () => {
    setShouldShowStreamBtn(false);
    try {
      setIsLoading(true);
      await whipClient.current?.connect({
        serverUrl: process.env.EXPO_PUBLIC_WHIP_SERVER_URL ?? '',
        authToken: 'example',
      });
      setIsLoading(false);
    } catch (error) {
      console.error('Failed to connect to WHIP Client', error);
    }
  };

  const handleSwitchCamera = useCallback(() => {
    // Find the opposite camera (front/back)
    const currentCamera = cameras.find((cam) => cam.id === whipClient.current?.getCurrentCameraDeviceId());
    const oppositeCamera = cameras.find(
      (cam) =>
        cam.facingDirection !== currentCamera?.facingDirection &&
        cam.facingDirection !== 'unspecified',
    );

    if (oppositeCamera && whipClient.current) {
      whipClient.current.switchCamera(oppositeCamera.id);
    }
  }, []);

  const handleFlipCamera = useCallback(async () => {
    if (whipClient.current) {
      try {
         await whipClient.current.flipCamera();
      } catch (error) {
        console.error('Failed to flip camera:', error);
      }
    }
  }, []);

  useEffect(() => {
    checkPermissions();
    return () => {
      // eslint-disable-next-line react-hooks/exhaustive-deps
      whipClient.current?.disconnect();
    };
  }, [whipClient]);

  return (
    <View style={styles.container}>
      <View style={styles.box}>
        <View style={styles.videoWrapper}>
          <WhipClientView style={styles.clientView} />
        </View>
        <Button title="Switch Camera" onPress={handleSwitchCamera} />
        <Button title="Flip Camera" onPress={handleFlipCamera} />
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
  videoWrapper: {
    width: '100%',
    paddingHorizontal: 16,
    paddingVertical: 16,
  },
  clientView: {
    alignSelf: 'center',
    height: '80%',
    aspectRatio: 9 / 16,
    marginBottom: 20,
  },
});
