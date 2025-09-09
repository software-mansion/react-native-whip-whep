import { Platform, PermissionsAndroid } from 'react-native';
import { Camera } from 'expo-camera';
import { Audio } from 'expo-av';

export async function checkPermissions() {
  if (Platform.OS === 'ios') {
    try {
      const { status: cameraStatus } = await Camera.requestCameraPermissionsAsync();
      const { status: micStatus } = await Audio.requestPermissionsAsync();
      if (cameraStatus !== 'granted' || micStatus !== 'granted') {
        console.warn('Camera/Microphone permissions not granted');
      }
    } catch (err) {
      console.warn(err);
    }
    return;
  }
  try {
    await PermissionsAndroid.requestMultiple([
      PermissionsAndroid.PERMISSIONS.CAMERA,
      PermissionsAndroid.PERMISSIONS.RECORD_AUDIO,
    ]);
  } catch (err) {
    console.warn(err);
  }
}
