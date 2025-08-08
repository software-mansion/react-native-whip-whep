import { useEffect, useRef, useState } from 'react';
import { WhepClient } from 'react-native-whip-whep';
import { checkPermissions } from '@/utils/CheckPermissions';

export const useWhepClient = (serverUrl: string) => {
  const [isLoading, setIsLoading] = useState(false);
  const [shouldShowPlayBtn, setShouldShowPlayBtn] = useState(true);

  const whepClient = useRef<WhepClient | null>(null);

  const handlePlayBtnClick = async () => {
    setShouldShowPlayBtn(false);
    setIsLoading(true);
    try {
      await whepClient.current?.connect({
        serverUrl,
      });
      setIsLoading(false);
    } catch (error) {
      console.error('Failed to connect to WHEP Client', error);
    }
  };

  useEffect(() => {
    const initialize = async () => {
      await checkPermissions();
      whepClient.current = new WhepClient({
        audioEnabled: true,
        videoEnabled: true,
      });
    };
    initialize();

    return () => {
      whepClient.current?.disconnect();
    };
  }, [serverUrl]);

  return {
    isLoading,
    shouldShowPlayBtn,
    handlePlayBtnClick,
  };
};
