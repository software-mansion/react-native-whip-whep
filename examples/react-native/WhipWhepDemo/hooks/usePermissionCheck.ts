import { useEffect } from 'react';
import { Platform, PermissionsAndroid } from 'react-native';

export function usePermissionCheck() {
  useEffect(() => {
    async function request() {
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

    request();
  }, []);
}
