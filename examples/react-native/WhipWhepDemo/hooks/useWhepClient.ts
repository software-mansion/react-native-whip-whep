import { useEffect, useRef, useState, useCallback } from 'react';
import { WhepClientViewRef } from 'react-native-whip-whep';

export const useWhepClient = (serverUrl: string) => {
  const [isLoading, setIsLoading] = useState(false);
  const [shouldShowPlayBtn, setShouldShowPlayBtn] = useState(true);
  const [isInitialized, setIsInitialized] = useState(false);
  const [isConnected, setIsConnected] = useState(false);
  const [isPaused, setIsPaused] = useState(false);

  const whepViewRef = useRef<WhepClientViewRef | null>(null);
  const isConnectingRef = useRef(false);

  const handlePlayBtnClick = useCallback(async () => {
    if (isConnectingRef.current || isLoading) {
      return;
    }

    isConnectingRef.current = true;
    setShouldShowPlayBtn(false);
    setIsLoading(true);

    try {
      if (!isInitialized) {
        await whepViewRef.current?.createWhepClient({
          audioEnabled: true,
          videoEnabled: true,
        });
        setIsInitialized(true);
      }

      await whepViewRef.current?.connect({ serverUrl });
      setIsLoading(false);
      setIsConnected(true);
    } catch (error) {
      console.error('Failed to connect to WHEP Client', error);
      setIsLoading(false);
      setShouldShowPlayBtn(true);
    } finally {
      isConnectingRef.current = false;
    }
  }, [serverUrl, isInitialized, isLoading]);

  const handlePause = useCallback(async () => {
    try {
      await whepViewRef.current?.pause();
      setIsPaused(true);
    } catch (error) {
      console.error('Failed to pause WHEP Client', error);
    }
  }, []);

  const handleResume = useCallback(async () => {
    try {
      await whepViewRef.current?.unpause();
      setIsPaused(false);
    } catch (error) {
      console.error('Failed to resume WHEP Client', error);
    }
  }, []);

  const handleDisconnect = useCallback(async () => {
    try {
      await whepViewRef.current?.disconnect();
      setIsConnected(false);
      setIsPaused(false);
      setShouldShowPlayBtn(true);
    } catch (error) {
      console.error('Failed to disconnect WHEP Client', error);
    }
  }, []);

  useEffect(() => {
    const ref = whepViewRef.current;
    return () => {
      ref?.disconnect();
    };
  }, []);

  return {
    isLoading,
    shouldShowPlayBtn,
    isConnected,
    isPaused,
    handlePlayBtnClick,
    handlePause,
    handleResume,
    handleDisconnect,
    whepViewRef,
  };
};
