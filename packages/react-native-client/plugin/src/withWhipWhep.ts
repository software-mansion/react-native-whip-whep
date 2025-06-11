import {
  AndroidConfig,
  ConfigPlugin,
  withAndroidManifest,
  withInfoPlist,
} from "@expo/config-plugins";

export type WhipWhepPluginOptions = {
  supportsPictureInPicture?: boolean;
};

const withWhipWhep: ConfigPlugin<WhipWhepPluginOptions> = (
  config,
  { supportsPictureInPicture },
) => {
  withInfoPlist(config, (configuration) => {
    const currentBackgroundModes =
      configuration.modResults.UIBackgroundModes ?? [];

    if (supportsPictureInPicture) {
      configuration.modResults.UIBackgroundModes = [
        ...currentBackgroundModes,
        "audio",
      ];
    }

    return configuration;
  });

  withAndroidManifest(config, (configuration) => {
    const activity = AndroidConfig.Manifest.getMainActivityOrThrow(
      configuration.modResults,
    );

    if (supportsPictureInPicture) {
      activity.$["android:supportsPictureInPicture"] = "true";
    } else {
      delete activity.$["android:supportsPictureInPicture"];
    }
    return configuration;
  });

  return config;
};

export default withWhipWhep;
