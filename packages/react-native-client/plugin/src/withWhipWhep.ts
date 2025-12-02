import { ConfigPlugin } from "@expo/config-plugins";
import { WhipWhepPluginOptions } from './types';
import withWhipWhepIos from './withWhipWhepIos';
import { withWhipWhepAndroid } from './withWhipWhepAndroid';

/**
 * Main WHIP/WHEP Expo config plugin.
 * 
 * This plugin configures both iOS and Android platforms for:
 * - Screen sharing (iOS and Android)
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
 *           "enableScreensharing": true,
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
  config = withWhipWhepIos(config, options);
  
  config = withWhipWhepAndroid(config, options);

  return config;
};

export default withWhipWhep;
