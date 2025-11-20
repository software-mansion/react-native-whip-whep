import {
  AndroidConfig,
  ConfigPlugin,
  withAndroidManifest,
} from '@expo/config-plugins';
import { getMainApplicationOrThrow } from '@expo/config-plugins/build/android/Manifest';
import { WhipWhepPluginOptions } from './types';

/**
 * Adds the FOREGROUND_SERVICE permission required for screen sharing.
 * 
 * This permission is required on Android 9+ (API 28+) to start a foreground service.
 */
const withWhipWhepForegroundServicePermission: ConfigPlugin<WhipWhepPluginOptions> = (
  config,
  props,
) =>
  withAndroidManifest(config, (configuration) => {
    if (!props?.android?.enableScreensharing) {
      return configuration;
    }

    const mainApplication = configuration.modResults;
    if (!mainApplication.manifest) {
      return configuration;
    }

    if (!mainApplication.manifest['uses-permission']) {
      mainApplication.manifest['uses-permission'] = [];
    }

    const permissions = mainApplication.manifest['uses-permission'];

    const hasForegroundServicePermission = permissions.some(
      (perm) => perm.$?.['android:name'] === 'android.permission.FOREGROUND_SERVICE',
    );

    if (!hasForegroundServicePermission) {
      permissions.push({
        $: {
          'android:name': 'android.permission.FOREGROUND_SERVICE',
        },
      });
    }

    return configuration;
  });

/**
 * Adds foreground service configuration for screen sharing on Android.
 * 
 * Android requires a foreground service with mediaProjection type to capture the screen.
 * This service must:
 * - Show a persistent notification while screen sharing is active
 * - Declare mediaProjection as foregroundServiceType
 * - Stop when the app task is removed (stopWithTask: true)
 * 
 * The service will be used by MediaProjection API to capture screen frames.
 */
const withWhipWhepForegroundService: ConfigPlugin<WhipWhepPluginOptions> = (
  config,
  props,
) =>
  withAndroidManifest(config, async (configuration) => {
    if (!props?.android?.enableScreensharing) {
      return configuration;
    }

    const mainApplication = getMainApplicationOrThrow(configuration.modResults);
    mainApplication.service = mainApplication.service || [];

    const newService = {
      $: {
        'android:name':
          'com.swmansion.reactnativeclient.foregroundService.ScreenCaptureService',
        'android:foregroundServiceType': 'mediaProjection',
      },
    };

    const existingServiceIndex = mainApplication.service.findIndex(
      (service) => service.$['android:name'] === newService.$['android:name'],
    );

    if (existingServiceIndex !== -1) {
      mainApplication.service[existingServiceIndex] = newService;
    } else {
      mainApplication.service.push(newService);
    }

    return configuration;
  });

/**
 * Adds Picture-in-Picture support to the main activity.
 * 
 * When enabled, allows the app to enter PiP mode during video streaming.
 */
const withWhipWhepPictureInPicture: ConfigPlugin<WhipWhepPluginOptions> = (
  config,
  props,
) =>
  withAndroidManifest(config, (configuration) => {
    const activity = AndroidConfig.Manifest.getMainActivityOrThrow(
      configuration.modResults,
    );

    if (props?.android?.supportsPictureInPicture) {
      activity.$['android:supportsPictureInPicture'] = 'true';
    } else {
      delete activity.$['android:supportsPictureInPicture'];
    }
    return configuration;
  });

/**
 * Main Android plugin function.
 * Applies all Android-specific configurations based on options.
 * 
 * This orchestrates:
 * - Foreground service permission (if screen sharing enabled)
 * - Foreground service setup (if screen sharing enabled)
 * - Picture-in-Picture support
 */
export const withWhipWhepAndroid: ConfigPlugin<WhipWhepPluginOptions> = (
  config,
  props,
) => {
  config = withWhipWhepForegroundServicePermission(config, props);
  config = withWhipWhepForegroundService(config, props);
  config = withWhipWhepPictureInPicture(config, props);
  return config;
};

