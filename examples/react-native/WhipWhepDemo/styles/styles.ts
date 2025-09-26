import { StyleSheet } from 'react-native';

export const styles = StyleSheet.create({
  container: {
    flex: 1,
    paddingTop: 50,
  },
  box: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  videoWrapper: {
    width: '100%',
    paddingHorizontal: 16,
    paddingVertical: 16,
  },
  clientView: {
    alignSelf: 'center',
    height: '80%',
    aspectRatio: 9 / 16,
    marginBottom: 20,
  },
  controlsContainer: {
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    gap: 10,
    paddingHorizontal: 20,
    paddingBottom: 20,
  },
});
