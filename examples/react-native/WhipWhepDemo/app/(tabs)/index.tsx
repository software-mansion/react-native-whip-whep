import { Button, View, ActivityIndicator } from 'react-native';
import React from 'react';
import { WhepClientView } from 'react-native-whip-whep';
import { useWhepClient } from '@/hooks/useWhepClient';
import { styles } from '../../styles/styles';
import { useThemeColor } from '@/hooks/useThemeColor';

export default function HomeScreen() {
  const {
    isLoading,
    shouldShowPlayBtn,
    isConnected,
    isPaused,
    handlePlayBtnClick,
    handlePause,
    handleResume,
    handleDisconnect,
    whepViewRef,
  } = useWhepClient(
    process.env.EXPO_PUBLIC_WHEP_SERVER_URL ??
      'https://broadcaster.elixir-webrtc.org/api/whep',
  );
  const { tint } = useThemeColor();

  return (
    <View style={styles.container}>
      <View style={styles.box}>
        <View style={styles.videoWrapper}>
          <WhepClientView
            ref={whepViewRef}
            pipEnabled
            autoStartPip
            autoStopPip
            pipSize={{ width: 1920, height: 1080 }}
            style={styles.clientView}
          />
        </View>

        <View style={styles.controlsContainer}>
          {shouldShowPlayBtn && (
            <Button
              title="Play"
              onPress={handlePlayBtnClick}
              color={tint}
              disabled={isLoading}
            />
          )}

          {isConnected && !shouldShowPlayBtn && (
            <>
              <Button
                title={isPaused ? 'Resume' : 'Pause'}
                onPress={isPaused ? handleResume : handlePause}
                color={tint}
                disabled={isLoading}
              />
              <Button
                title="Disconnect"
                onPress={handleDisconnect}
                color={tint}
                disabled={isLoading}
              />
            </>
          )}

          {isLoading && <ActivityIndicator size="large" color={tint} />}
        </View>
      </View>
    </View>
  );
}
