import { useEffect, useState } from 'react';
import {
  connectWhepClient,
  createWhepClient,
  disconnectWhepClient,
  pauseWhepClient,
  unpauseWhepClient,
} from 'react-native-whip-whep';
import { checkPermissions } from '@/utils/CheckPermissions';

export const useWhepClient = (serverUrl: string) => {
  const [isLoading, setIsLoading] = useState(false);
  const [shouldShowPlayBtn, setShouldShowPlayBtn] = useState(true);
  const [isPaused, setIsPaused] = useState(false);

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
      setIsPaused(true);
    } catch (error) {
      console.error('Failed to pause WHEP Client', error);
    }
  };

  const handleRestartBtnClick = async () => {
    try {
      unpauseWhepClient();
      setIsPaused(false);
    } catch (error) {
      console.error('Failed to unpause WHEP Client', error);
    }
  };

  useEffect(() => {
    const initialize = async () => {
      await checkPermissions();
      createWhepClient(serverUrl, {
        authToken: 'example',
      });
    };
    initialize();

    return () => {
      disconnectWhepClient();
    };
  }, [serverUrl]);

  return {
    isLoading,
    shouldShowPlayBtn,
    isPaused,
    handlePlayBtnClick,
    handlePauseBtnClick,
    handleRestartBtnClick,
  };
};
