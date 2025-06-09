import { Button, View, ActivityIndicator } from 'react-native';

import React, { useRef } from 'react';
import { WhepClientView, WhepClientViewRef } from 'react-native-whip-whep';
import { useWhepClient } from '@/hooks/useWhepClient';
import { styles } from '../../styles/styles';
import { useThemeColor } from '@/hooks/useThemeColor';

export default function HomeScreen() {
  const {
    isLoading,
    shouldShowPlayBtn,
    isPaused,
    handlePlayBtnClick,
    handlePauseBtnClick,
    handleRestartBtnClick,
  } = useWhepClient(process.env.EXPO_PUBLIC_WHEP_SERVER_URL ?? '');
  const { tint } = useThemeColor();

  const whepViewRef = useRef<WhepClientViewRef | null>(null);

  return (
    <View style={styles.container}>
      <View style={styles.box}>
        <WhepClientView
          pipEnabled
          autoStartPip
          autoStopPip
          pipSize={{ width: 1920, height: 1080 }}
          ref={whepViewRef}
          style={styles.clientView}
        />
        {shouldShowPlayBtn && (
          <Button title="Play" onPress={handlePlayBtnClick} color={tint} />
        )}
        {!shouldShowPlayBtn &&
          !isLoading &&
          (isPaused ? (
            <Button title="Play" onPress={handleRestartBtnClick} color={tint} />
          ) : (
            <Button title="Pause" onPress={handlePauseBtnClick} color={tint} />
          ))}
        {isLoading && <ActivityIndicator size="large" color={tint} />}
      </View>
    </View>
  );
}
