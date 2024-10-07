import { Button, View, ActivityIndicator } from 'react-native';
import { useWhepClient } from '@/hooks/useWhepClient';
import { WhepClientView } from 'react-native-whip-whep';
import { styles } from '../../styles/styles';

export default function HomeScreen() {
  const {
    isLoading,
    shouldShowPlayBtn,
    isPaused,
    handlePlayBtnClick,
    handlePauseBtnClick,
    handleRestartBtnClick,
  } = useWhepClient('https://broadcaster.elixir-webrtc.org/api/whep');

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
