import { Platform, PermissionsAndroid } from 'react-native';

export async function checkPermissions() {
  if (Platform.OS === 'ios') {
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
