import { StyleSheet, Button, View, ActivityIndicator } from 'react-native';

import React, { useEffect, useState } from 'react';
import {
  connectWhepClient,
  createWhepClient,
  disconnectWhepClient,
  pauseWhepClient,
  restartWhepClient,
  WhepClientView,
} from 'react-native-whip-whep';
import { checkPermissions } from '@/utils/CheckPermissions';

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
      console.error('Failed to connect to WHEP Client', error);
    }
  };

  const handlePauseBtnClick = async () => {
    try {
      pauseWhepClient();
    } catch (error) {
      console.error('Failed to pause WHEP Client', error);
    }
  };

  const handleRestartBtnClick = async () => {
    try {
      restartWhepClient();
    } catch (error) {
      console.error('Failed to restart WHEP Client', error);
    }
  };

  const initialize = async () => {
    await checkPermissions();
    createWhepClient(process.env.EXPO_PUBLIC_WHEP_SERVER_URL ?? '', {
      authToken: 'example',
    });
  };

  useEffect(() => {
    initialize();
    return () => {
      disconnectWhepClient();
    };
  }, []);

  return (
    <View style={styles.container}>
      <View style={styles.box}>
        <WhepClientView style={styles.clientView} />
        {shouldShowPlayBtn && (
          <Button title="Play" onPress={handlePlayBtnClick} />
        )}
        {!shouldShowPlayBtn && !isLoading && (
          <Button title="Pause" onPress={handlePauseBtnClick} />
        )}
        {!shouldShowPlayBtn && !isLoading && (
          <Button title="Play" onPress={handleRestartBtnClick} />
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
