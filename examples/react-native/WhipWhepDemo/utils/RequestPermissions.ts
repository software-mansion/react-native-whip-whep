import { Platform } from "react-native";
import {
  Permission,
  PERMISSIONS,
  request,
  RESULTS,
} from "react-native-permissions";

export const requestPermissions = async (): Promise<boolean> => {
  try {
    const cameraPermission = await request(
      Platform.select({
        android: PERMISSIONS.ANDROID.CAMERA,
        ios: PERMISSIONS.IOS.CAMERA,
      }) as Permission,
    );

    const microphonePermission = await request(
      Platform.select({
        android: PERMISSIONS.ANDROID.RECORD_AUDIO,
        ios: PERMISSIONS.IOS.MICROPHONE,
      }) as Permission,
    );

    if (
      cameraPermission === RESULTS.GRANTED &&
      microphonePermission === RESULTS.GRANTED
    ) {
      console.log("All permissions granted");
      return true;
    } else {
      console.log("Please provide camera and microphone permissions.");
      return false;
    }
  } catch (error) {
    console.error("Failed to request permission", error);
    return false;
  }
};
