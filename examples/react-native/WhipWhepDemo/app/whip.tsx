import {
  StyleSheet,
  Button,
  View,
  ActivityIndicator,
  Text,
  Platform,
  ScrollView,
} from 'react-native';

import { useEffect, useRef, useState, useCallback } from 'react';
import {
  cameras,
  VideoParameters,
  WhipClientView,
  WhipClientViewRef,
  SenderVideoCodecName,
  SenderAudioCodecName,
  useWhipConnectionState,
} from 'react-native-whip-whep';
import { useThemeColor } from '@/hooks/useThemeColor';

export default function WhipScreen() {
  const [isLoading, setIsLoading] = useState(false);
  const [shouldShowStreamBtn, setShouldShowStreamBtn] = useState(true);

  const whipClient = useRef<WhipClientViewRef | null>(null);

  const peerConnectionState = useWhipConnectionState();

  useEffect(() => {
    console.log('WHIP Peer Connection State Changed:', peerConnectionState);
  }, [peerConnectionState]);

  const { tint } = useThemeColor();

  const getConnectionStatusDisplay = (state: string) => {
    switch (state) {
      case 'new':
        return { text: 'Ready', color: '#6B7280' };
      case 'connecting':
        return { text: 'Connecting...', color: '#F59E0B' };
      case 'connected':
        return { text: 'Connected', color: '#10B981' };
      case 'disconnected':
        return { text: 'Disconnected', color: '#6B7280' };
      case 'failed':
        return { text: 'Connection Failed', color: '#EF4444' };
      case 'closed':
        return { text: 'Connection Closed', color: '#6B7280' };
      default:
        return { text: 'Unknown', color: '#6B7280' };
    }
  };

  const initializeCamera = useCallback(async () => {
    try {
      setIsLoading(true);

      await whipClient.current?.initializeCamera({
        audioEnabled: true,
        videoEnabled: true,
        videoDeviceId: cameras[0].id,
        videoParameters: VideoParameters.presetHD169,
      });

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

      await whipClient.current?.connect({
        serverUrl: process.env.EXPO_PUBLIC_WHIP_SERVER_URL ?? '',
        authToken: 'example',
      });
      setIsLoading(false);
    } catch (error) {
      console.error('Failed to connect to WHIP Client', error);
      setShouldShowStreamBtn(true);
      setIsLoading(false);
    }
  };

  const handleDisconnectBtnClick = async () => {
    try {
      await whipClient.current?.disconnect();
      setShouldShowStreamBtn(true);
    } catch (error) {
      console.error('Failed to disconnect from WHIP Client', error);
    }
  };

  const handleSwitchCamera = useCallback(async () => {
    const currentCameraId = await whipClient.current?.currentCameraDeviceId();
    const currentCamera = cameras.find((cam) => cam.id === currentCameraId);

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

  const handleSetH264VideoCodec = useCallback(async () => {
    if (whipClient.current) {
      try {
        await whipClient.current.setPreferredSenderVideoCodecs([
          'H264' as SenderVideoCodecName,
        ]);
        console.log('Set preferred video codec to H264');
      } catch (error) {
        console.error('Failed to set video codec:', error);
      }
    }
  }, []);

  const handleSetOpusAudioCodec = useCallback(async () => {
    if (whipClient.current) {
      try {
        await whipClient.current.setPreferredSenderAudioCodecs([
          'OPUS' as SenderAudioCodecName,
        ]);
        console.log('Set preferred audio codec to OPUS');
      } catch (error) {
        console.error('Failed to set audio codec:', error);
      }
    }
  }, []);

  useEffect(() => {
    initializeCamera();

    const client = whipClient.current;
    return () => {
      client?.disconnect();
      client?.cleanup();
    };
  }, [initializeCamera]);

  return (
    <ScrollView>
      <View style={styles.container}>
        <View style={styles.box}>
          <View style={styles.videoWrapper}>
            <WhipClientView style={styles.clientView} ref={whipClient} />
          </View>

          <View style={styles.statusContainer}>
            <Text style={styles.statusLabel}>Connection Status:</Text>
            <Text
              style={[
                styles.statusText,
                {
                  color: getConnectionStatusDisplay(
                    peerConnectionState ?? 'unknown',
                  ).color,
                },
              ]}>
              {
                getConnectionStatusDisplay(peerConnectionState ?? 'unknown')
                  .text
              }
            </Text>
          </View>

          <Button title="Switch Camera" onPress={handleSwitchCamera} />
          <Button title="Flip Camera" onPress={handleFlipCamera} />
          {Platform.OS === 'ios' && (
            <>
              <Button
                title="Set H264 Video"
                onPress={handleSetH264VideoCodec}
              />
              <Button
                title="Set OPUS Audio"
                onPress={handleSetOpusAudioCodec}
              />
            </>
          )}
          {shouldShowStreamBtn && (
            <Button
              title="Stream"
              onPress={handleStreamBtnClick}
              color={tint}
            />
          )}
          {!shouldShowStreamBtn && !isLoading && (
            <Button
              title="Disconnect"
              onPress={handleDisconnectBtnClick}
              color={tint}
            />
          )}
          {isLoading && <ActivityIndicator size="large" color={tint} />}
        </View>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    paddingVertical: 20,
  },
  box: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  videoWrapper: {
    flex: 1,
    paddingHorizontal: 16,
    maxHeight: 500,
  },
  clientView: {
    alignSelf: 'center',
    height: '100%',
    aspectRatio: 9 / 16,
  },
  statusContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 10,
    paddingHorizontal: 16,
    backgroundColor: '#F3F4F6',
    borderRadius: 8,
    marginHorizontal: 16,
    marginBottom: 10,
  },
  statusLabel: {
    fontSize: 16,
    fontWeight: '600',
    color: '#374151',
    marginRight: 8,
  },
  statusText: {
    fontSize: 16,
    fontWeight: '500',
  },
});
