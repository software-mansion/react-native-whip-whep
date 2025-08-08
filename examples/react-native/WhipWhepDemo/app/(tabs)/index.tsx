import { Button, View, ActivityIndicator } from 'react-native';
import { useWhepClient } from '@/hooks/useWhepClient';
import { WhepClientView } from 'react-native-whip-whep';
import { styles } from '../../styles/styles';
import { useThemeColor } from '@/hooks/useThemeColor';

export default function HomeScreen() {
  const { isLoading, shouldShowPlayBtn, handlePlayBtnClick } = useWhepClient(
    'https://broadcaster.elixir-webrtc.org/api/whep',
  );
  const { tint } = useThemeColor();

  return (
    <View style={styles.container}>
      <View style={styles.box}>
        <WhepClientView
          pipEnabled
          autoStartPip
          autoStopPip
          pipSize={{ width: 1920, height: 1080 }}
          style={styles.clientView}
        />
        {shouldShowPlayBtn && (
          <Button title="Play" onPress={handlePlayBtnClick} color={tint} />
        )}
        {isLoading && <ActivityIndicator size="large" color={tint} />}
      </View>
    </View>
  );
}
