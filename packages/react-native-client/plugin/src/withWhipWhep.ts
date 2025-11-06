import {
  AndroidConfig,
  ConfigPlugin,
  withAndroidManifest,
} from "@expo/config-plugins";
import { WhipWhepPluginOptions } from './types';
import withWhipWhepIos from './withWhipWhepIos';

/**
 * Main WHIP/WHEP Expo config plugin.
 * 
 * This plugin configures both iOS and Android platforms for:
 * - Screen sharing (iOS only for now)
 * - Picture-in-Picture support
 * 
 * Usage in app.json/app.config.js:
 * {
 *   "plugins": [
 *     [
 *       "react-native-whip-whep",
 *       {
 *         "ios": {
 *           "enableScreensharing": true,
 *           "supportsPictureInPicture": true,
 *           "appGroupContainerId": "group.com.example.myapp" // optional
 *         },
 *         "android": {
 *           "supportsPictureInPicture": true
 *         }
 *       }
 *     ]
 *   ]
 * }
 */
const withWhipWhep: ConfigPlugin<WhipWhepPluginOptions> = (
  config,
  options,
) => {
  // Apply iOS-specific configurations
  config = withWhipWhepIos(config, options);

  // Apply Android-specific configurations
  config = withAndroidManifest(config, (configuration) => {
    const activity = AndroidConfig.Manifest.getMainActivityOrThrow(
      configuration.modResults,
    );

    if (options?.android?.supportsPictureInPicture) {
      activity.$["android:supportsPictureInPicture"] = "true";
    } else {
      delete activity.$["android:supportsPictureInPicture"];
    }
    return configuration;
  });

  return config;
};

export default withWhipWhep;
