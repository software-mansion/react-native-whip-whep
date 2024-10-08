import { Button, View, ActivityIndicator } from 'react-native';

import React from 'react';
import { WhepClientView } from 'react-native-whip-whep';
import { useWhepClient } from '@/hooks/useWhepClient';
import { styles } from '../../styles/styles';

export default function HomeScreen() {
  const {
    isLoading,
    shouldShowPlayBtn,
    isPaused,
    handlePlayBtnClick,
    handlePauseBtnClick,
    handleRestartBtnClick,
  } = useWhepClient(process.env.EXPO_PUBLIC_WHEP_SERVER_URL ?? '');

  return (
    <View style={styles.container}>
      <View style={styles.box}>
        <WhepClientView style={styles.clientView} />
        {shouldShowPlayBtn && (
          <Button title="Play" onPress={handlePlayBtnClick} />
        )}
        {!shouldShowPlayBtn &&
          !isLoading &&
          (isPaused ? (
            <Button title="Play" onPress={handleRestartBtnClick} />
          ) : (
            <Button title="Pause" onPress={handlePauseBtnClick} />
          ))}
        {isLoading && <ActivityIndicator size="large" color="#2196F3" />}
      </View>
    </View>
  );
}
