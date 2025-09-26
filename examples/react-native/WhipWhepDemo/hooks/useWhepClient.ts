import { useEffect, useRef, useState, useCallback } from 'react';
import { WhepClientViewRef } from 'react-native-whip-whep';
import { checkPermissions } from '@/utils/CheckPermissions';

export const useWhepClient = (serverUrl: string) => {
  const [isLoading, setIsLoading] = useState(false);
  const [shouldShowPlayBtn, setShouldShowPlayBtn] = useState(true);
  const [isInitialized, setIsInitialized] = useState(false);

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

      await whepViewRef.current?.connectWhep({serverUrl});
      setIsLoading(false);
    } catch (error) {
      console.error('Failed to connect to WHEP Client', error);
      setIsLoading(false);
      setShouldShowPlayBtn(true);
    } finally {
      isConnectingRef.current = false;
    }
  }, [serverUrl, isInitialized, isLoading]);

  useEffect(() => {
    const initialize = async () => {
      await checkPermissions();
    };
    initialize();
    
    return () => {
      whepViewRef.current?.disconnectWhep();
    };
  }, []);

  return {
    isLoading,
    shouldShowPlayBtn,
    handlePlayBtnClick,
    whepViewRef,
  };
};
