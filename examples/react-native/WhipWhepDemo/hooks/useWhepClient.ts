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
      console.log(
        '### useWhepClient handlePlayBtnClick - connecting whep client',
      );
      await whepClient.current?.connect({
        serverUrl,
      });
      setIsLoading(false);
    } catch (error) {
      console.error('Failed to connect to WHEP Client', error);
    }
  };

  const disconnect = () => {
    console.log('### useWhepClient disconnecting in disconnect');
    whepClient.current?.disconnect();
  };

  useEffect(() => {
    const initialize = async () => {
      console.log('### useWhepClient initialize - checking permissisons');
      await checkPermissions();

      console.log('### useWhepClient initialize - creating whep client');
      whepClient.current = new WhepClient({
        audioEnabled: true,
        videoEnabled: true,
      });
    };
    initialize();
  }, [serverUrl]);

  return {
    isLoading,
    shouldShowPlayBtn,
    handlePlayBtnClick,
    disconnect,
  };
};
