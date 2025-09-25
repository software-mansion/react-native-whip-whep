import { StyleSheet, Button, View, ActivityIndicator } from 'react-native';

import { useEffect, useRef, useState, useCallback } from 'react';
import {
  cameras,
  getCurrentCameraDeviceId,
  VideoParameters,
  WhipClient,
  WhipClientView,
  WhipClientViewRef,
} from 'react-native-whip-whep';
import { checkPermissions } from '@/utils/CheckPermissions';
import { useThemeColor } from '@/hooks/useThemeColor';

export default function HomeScreen() {
  const [isLoading, setIsLoading] = useState(false);
  const [shouldShowStreamBtn, setShouldShowStreamBtn] = useState(true);

  const whipClient = useRef<WhipClientViewRef>(null);

  const { tint } = useThemeColor();

  const initializeCamera = useCallback(async () => {
    try {
      setIsLoading(true);
      
      // Initialize camera with configuration when view appears
      await whipClient.current?.initializeCamera(
        true,
        true,
        cameras[0].id,
        VideoParameters.presetHD169,
      );
      
      setIsLoading(false);
    } catch (error) {
      console.error('Failed to initialize camera', error);
      setIsLoading(false);
    }
  }, []);

  const handleStreamBtnClick = async () => {
    setShouldShowStreamBtn(false);
    try {
      setIsLoading(true);
      
      await whipClient.current?.connect(
        process.env.EXPO_PUBLIC_WHIP_SERVER_URL ?? '',
        'example',
      );
      setIsLoading(false);
    } catch (error) {
      console.error('Failed to connect to WHIP Client', error);
      setIsLoading(false);
    }
  };

  const handleSwitchCamera = useCallback(() => {
    // Find the opposite camera (front/back)
    const currentCamera = cameras.find(
      (cam) => cam.id === getCurrentCameraDeviceId(),
    );

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
    initializeCamera();
    return () => {
      whipClient.current?.disconnect();
      whipClient.current?.cleanup();
    };
  }, [whipClient, initializeCamera]);

  return (
    <View style={styles.container}>
      <View style={styles.box}>
        <View style={styles.videoWrapper}>
          <WhipClientView
            style={styles.clientView}
            ref={whipClient}
          />
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
    flex: 1,
    paddingHorizontal: 16,
    paddingTop: 16,
  },
  clientView: {
    alignSelf: 'center',
    height: '100%',
    aspectRatio: 9 / 16,
  },
});
