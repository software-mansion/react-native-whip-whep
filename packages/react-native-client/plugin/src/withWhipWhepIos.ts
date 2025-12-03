import {
  ConfigPlugin,
  withEntitlementsPlist,
  withXcodeProject,
  withInfoPlist,
  withPodfileProperties,
} from '@expo/config-plugins';
import * as fs from 'promise-fs';
import * as path from 'path';
import { WhipWhepPluginOptions } from './types';

/**
 * Gets the name of the Broadcast Upload Extension target.
 * This can be customized via plugin options or defaults to 'WhipWhepScreenBroadcastExtension'.
 */
function getSbeTargetName(props: WhipWhepPluginOptions) {
  return (
    props?.ios?.broadcastExtensionTargetName ||
    'WhipWhepScreenBroadcastExtension'
  );
}

/**
 * Generates the Podfile snippet that adds the broadcast extension target.
 * This snippet adds the necessary WebRTC dependency to the extension.
 */
export function getSbePodfileSnippet(props: WhipWhepPluginOptions) {
  const targetName = getSbeTargetName(props);
  // The extension needs access to WebRTC for handling video frames via the MobileWhipWhepBroadcastClient
  return `\ntarget '${targetName}' do\n  pod 'MobileWhipWhepBroadcastClient', :path => '../../../../'\nend`;
}

const TARGETED_DEVICE_FAMILY = `"1,2"`; // 1=iPhone, 2=iPad
const IPHONEOS_DEPLOYMENT_TARGET = '15.1'; // Minimum iOS version
const GROUP_IDENTIFIER_TEMPLATE_REGEX = /{{GROUP_IDENTIFIER}}/gm; // Template placeholder for app group
const BUNDLE_IDENTIFIER_TEMPLATE_REGEX = /{{BUNDLE_IDENTIFIER}}/gm; // Template placeholder for bundle ID

/**
 * Helper function for updating template placeholders in extension files.
 * Replaces template variables like {{GROUP_IDENTIFIER}} with actual values.
 *
 * @param iosPath - Path to the iOS project directory
 * @param fileName - Name of the file to update
 * @param regex - Regular expression to find the placeholder
 * @param value - The actual value to replace the placeholder with
 * @param props - Plugin configuration options
 */
async function updateFileWithRegex(
  iosPath: string,
  fileName: string,
  regex: RegExp,
  value: string,
  props: WhipWhepPluginOptions,
) {
  const targetName = getSbeTargetName(props);
  const filePath = `${iosPath}/${targetName}/${fileName}`;
  let file = await fs.readFile(filePath, { encoding: 'utf-8' });
  file = file.replace(regex, value);
  await fs.writeFile(filePath, file);
}

/**
 * Updates the Podfile to include the broadcast extension target.
 * This ensures the extension has access to necessary dependencies (WebRTC).
 * The extension runs in a separate process and needs its own dependencies.
 *
 * @param iosPath - Path to the iOS project directory
 * @param props - Plugin configuration options
 */
async function updatePodfile(iosPath: string, props: WhipWhepPluginOptions) {
  const podfileSnippet = getSbePodfileSnippet(props);
  let matches;
  try {
    const podfile = await fs.readFile(`${iosPath}/Podfile`, {
      encoding: 'utf-8',
    });
    matches = podfile.match(podfileSnippet);
  } catch (e) {
    console.error('Error reading from Podfile: ', e);
  }

  if (matches) {
    console.log(
      `${getSbeTargetName(props)} target already added to Podfile. Skipping...`,
    );
    return;
  }
  try {
    await fs.appendFile(`${iosPath}/Podfile`, podfileSnippet);
  } catch (e) {
    console.error('Error writing to Podfile: ', e);
  }
}

/**
 * Adds "App Group" permission to the main app.
 * 
 * The app group identifier is typically in the format: group.{bundle.identifier}
 */
const withAppGroupPermissions: ConfigPlugin<WhipWhepPluginOptions> = (
  config,
  props,
) => {
  const APP_GROUP_KEY = 'com.apple.security.application-groups';
  const bundleIdentifier = config.ios?.bundleIdentifier || '';
  const groupIdentifier =
    props?.ios?.appGroupContainerId || `group.${bundleIdentifier}`;
  const mainTarget = props?.ios?.mainTargetName || '';

  // Add to the config object for Expo
  config.ios ??= {};
  config.ios.entitlements ??= {};
  config.ios.entitlements[APP_GROUP_KEY] ??= [];

  const entitlementsArray = config.ios.entitlements[APP_GROUP_KEY] as string[];
  if (!entitlementsArray.includes(groupIdentifier)) {
    entitlementsArray.push(groupIdentifier);
  }

  config = withEntitlementsPlist(config, (newConfig) => {
    const modResultsArray =
      (newConfig.modResults[APP_GROUP_KEY] as string[]) || [];
    if (!modResultsArray.includes(groupIdentifier)) {
      modResultsArray.push(groupIdentifier);
    }
    newConfig.modResults[APP_GROUP_KEY] = modResultsArray;
    return newConfig;
  });

  config = withXcodeProject(config, (props) => {
    const xcodeProject = props.modResults;
    const targets = xcodeProject.getFirstTarget();
    const project = xcodeProject.getFirstProject();

    if (!targets || !project) {
      return props;
    }

    const targetUuid = targets.uuid;
    const projectUuid = project.uuid;

    const projectObj =
      xcodeProject.hash.project.objects.PBXProject[projectUuid];
    projectObj.attributes ??= {};
    projectObj.attributes.TargetAttributes ??= {};
    projectObj.attributes.TargetAttributes[targetUuid] ??= {};
    projectObj.attributes.TargetAttributes[targetUuid].SystemCapabilities ??=
      {};

    projectObj.attributes.TargetAttributes[targetUuid].SystemCapabilities[
      'com.apple.ApplicationGroups.iOS'
    ] = {
      enabled: 1,
    };

    const mainTargetName = mainTarget || props.modRequest.projectName;
    const entitlementsFilePath = `${mainTargetName}/${mainTargetName}.entitlements`;
    const configurations = xcodeProject.pbxXCBuildConfigurationSection();

    Object.keys(configurations).forEach((key) => {
      const config = configurations[key];
      if (config.buildSettings?.PRODUCT_NAME?.includes(mainTargetName)) {
        if (!config.buildSettings.CODE_SIGN_ENTITLEMENTS) {
          config.buildSettings.CODE_SIGN_ENTITLEMENTS = entitlementsFilePath;
        }
      }
    });

    return props;
  });

  return config;
};

const withInfoPlistConstants: ConfigPlugin<WhipWhepPluginOptions> = (
  config,
  props,
) =>
  withInfoPlist(config, (configuration) => {
    const bundleIdentifier = configuration.ios?.bundleIdentifier || '';
    const groupIdentifier =
      props?.ios?.appGroupContainerId || `group.${bundleIdentifier}`;
    configuration.modResults['AppGroupName'] = groupIdentifier;
    configuration.modResults['ScreenShareExtensionBundleId'] =
      `${bundleIdentifier}.${getSbeTargetName(props)}`;
    return configuration;
  });


const withWhipWhepSBE: ConfigPlugin<WhipWhepPluginOptions> = (config, options) =>
  withXcodeProject(config, async (props) => {
    const appName = props.modRequest.projectName || '';
    const iosPath = props.modRequest.platformProjectRoot;
    const bundleIdentifier = props.ios?.bundleIdentifier;
    const groupIdentifier =
      options?.ios?.appGroupContainerId || `group.${bundleIdentifier}`;
    const xcodeProject = props.modResults;
    const targetName = getSbeTargetName(options);

    const pluginDir = require.resolve(
      'react-native-whip-whep/package.json',
    );
    const extensionSourceDir = path.join(
      pluginDir,
      '../plugin/broadcastExtensionFiles/',
    );

    await updatePodfile(iosPath, options);

    const projPath = `${iosPath}/${appName}.xcodeproj/project.pbxproj`;
    const templateTargetName = 'WhipWhepScreenBroadcastExtension';

    const extFiles = [
      'WhipWhepBroadcastSampleHandler.swift',
      `${templateTargetName}.entitlements`,
      `Info.plist`,
    ];

    const destFiles = [
      'WhipWhepBroadcastSampleHandler.swift',
      `${targetName}.entitlements`,
      `Info.plist`,
    ];

    await xcodeProject.parse(async function (err: Error) {
      if (err) {
        console.error(`Error parsing iOS project: ${JSON.stringify(err)}`);
        return;
      }
      if (xcodeProject.pbxTargetByName(targetName)) {
        console.log(`${targetName} already exists in project. Skipping...`);
        return;
      }
      try {
        await fs.mkdir(`${iosPath}/${targetName}`, { recursive: true });
        for (let i = 0; i < extFiles.length; i++) {
          const srcFile = `${extensionSourceDir}${extFiles[i]}`;
          const destFile = `${iosPath}/${targetName}/${destFiles[i]}`;
          await fs.copyFile(srcFile, destFile);
        }
      } catch (e) {
        console.error('Error copying extension files: ', e);
      }

      await updateFileWithRegex(
        iosPath,
        `${targetName}.entitlements`,
        GROUP_IDENTIFIER_TEMPLATE_REGEX,
        groupIdentifier,
        options,
      );
      await updateFileWithRegex(
        iosPath,
        'WhipWhepBroadcastSampleHandler.swift',
        GROUP_IDENTIFIER_TEMPLATE_REGEX,
        groupIdentifier,
        options,
      );
      await updateFileWithRegex(
        iosPath,
        'WhipWhepBroadcastSampleHandler.swift',
        BUNDLE_IDENTIFIER_TEMPLATE_REGEX,
        bundleIdentifier || '',
        options,
      );

      const extGroup = xcodeProject.addPbxGroup(
        extFiles,
        targetName,
        targetName,
      );

      const groups = xcodeProject.hash.project.objects['PBXGroup'];
      Object.keys(groups).forEach(function (key) {
        if (groups[key].name === undefined) {
          xcodeProject.addToPbxGroup(extGroup.uuid, key);
        }
      });

      // WORKAROUND for xcodeProject.addTarget bug
      // Xcode projects don't contain these if there is only one target
      const projObjects = xcodeProject.hash.project.objects;
      projObjects['PBXTargetDependency'] =
        projObjects['PBXTargetDependency'] || {};
      projObjects['PBXContainerItemProxy'] =
        projObjects['PBXContainerItemProxy'] || {};

      const sbeTarget = xcodeProject.addTarget(
        targetName,
        'app_extension',
        targetName,
        `${bundleIdentifier}.${targetName}`,
      );

      xcodeProject.addBuildPhase(
        ['WhipWhepBroadcastSampleHandler.swift'],
        'PBXSourcesBuildPhase',
        'Sources',
        sbeTarget.uuid,
      );
      xcodeProject.addBuildPhase(
        [],
        'PBXResourcesBuildPhase',
        'Resources',
        sbeTarget.uuid,
      );

      xcodeProject.addBuildPhase(
        [],
        'PBXFrameworksBuildPhase',
        'Frameworks',
        sbeTarget.uuid,
      );

      xcodeProject.addFramework('ReplayKit.framework', {
        target: sbeTarget.uuid,
      });

      const configurations = xcodeProject.pbxXCBuildConfigurationSection();
      for (const key in configurations) {
        if (
          typeof configurations[key].buildSettings !== 'undefined' &&
          configurations[key].buildSettings.PRODUCT_NAME === `"${targetName}"`
        ) {
          const buildSettingsObj = configurations[key].buildSettings;
          buildSettingsObj.IPHONEOS_DEPLOYMENT_TARGET =
            options?.ios?.iphoneDeploymentTarget ?? IPHONEOS_DEPLOYMENT_TARGET;
          buildSettingsObj.TARGETED_DEVICE_FAMILY = TARGETED_DEVICE_FAMILY;
          buildSettingsObj.CODE_SIGN_ENTITLEMENTS = `${targetName}/${targetName}.entitlements`;
          buildSettingsObj.CODE_SIGN_STYLE = 'Automatic';
          buildSettingsObj.INFOPLIST_FILE = `${targetName}/Info.plist`;
          buildSettingsObj.SWIFT_VERSION = '5.0';
          buildSettingsObj.MARKETING_VERSION = '1.0.0';
          buildSettingsObj.CURRENT_PROJECT_VERSION = '1';
          buildSettingsObj.ENABLE_BITCODE = 'NO';
        }
      }

      await fs.writeFile(projPath, xcodeProject.writeSync());
    });

    return props;
  });

/**
 * Adds Picture-in-Picture support by enabling audio background mode.
 * This allows the app to continue playing audio when in PiP mode.
 */
const withWhipWhepPictureInPicture: ConfigPlugin<WhipWhepPluginOptions> = (
  config,
  props,
) =>
  withInfoPlist(config, (configuration) => {
    if (props?.ios?.supportsPictureInPicture) {
      const backgroundModes = new Set(
        configuration.modResults.UIBackgroundModes ?? [],
      );
      backgroundModes.add('audio');
      configuration.modResults.UIBackgroundModes = Array.from(backgroundModes);
    }

    return configuration;
  });

/**
 * Main iOS plugin function.
 * Applies all iOS-specific configurations conditionally based on options.
 * 
 * This orchestrates:
 * - Screen sharing setup (if enabled)
 * - Deployment target configuration
 * - Picture-in-Picture support
 */
const withWhipWhepIos: ConfigPlugin<WhipWhepPluginOptions> = (config, props) => {
  if (props?.ios?.enableScreensharing) {
    config = withAppGroupPermissions(config, props);
    config = withInfoPlistConstants(config, props);
    config = withWhipWhepSBE(config, props);
  }
  
  config = withPodfileProperties(config, (configuration) => {
    configuration.modResults['ios.deploymentTarget'] =
      props?.ios?.iphoneDeploymentTarget ?? IPHONEOS_DEPLOYMENT_TARGET;
    return configuration;
  });
  
  config = withWhipWhepPictureInPicture(config, props);

  return config;
};

export default withWhipWhepIos;

