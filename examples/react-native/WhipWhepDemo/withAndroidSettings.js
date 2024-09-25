const {
  withSettingsGradle,
  withAppBuildGradle,
  createRunOncePlugin,
  withProjectBuildGradle,
} = require('@expo/config-plugins');
const fs = require('fs');
const path = require('path');

const pkg = require('./package.json');

console.log('Starting the plugin!');

const withAndroidSettings = (config) => {
  config = withSettingsGradle(config, (config) => {
    let contents = config.modResults.contents;

    if (!contents.includes("include ':android-client'")) {
      console.log('Adding android-client to settings.gradle...');
      contents +=
        `\ninclude ':android-client'\n` +
        `project(':android-client').projectDir = new File(rootProject.projectDir, '../../../../packages/android-client/MobileWhepClient')\n`;
      config.modResults.contents = contents;
      console.log('✔ Added android-client to settings.gradle.');
    } else {
      console.log('android-client already included in settings.gradle');
    }

    return config;
  });

  config = withAppBuildGradle(config, (config) => {
    let contents = config.modResults.contents;
    if (
      !contents.includes(
        "implementation project(':mobile-whep-react-native-client')",
      )
    ) {
      console.log(
        'Adding mobile-whep-react-native-client to app/build.gradle...',
      );
      const dependenciesBlock = 'dependencies {';
      const addition =
        "implementation project(':mobile-whep-react-native-client')";

      const updatedContents = contents.replace(
        dependenciesBlock,
        `${dependenciesBlock}\n    ${addition}`,
      );
      config.modResults.contents = updatedContents;
      console.log(
        '✔ Added mobile-whep-react-native-client to app/build.gradle.',
      );
    } else {
      console.log(
        'mobile-whep-react-native-client already included in app/build.gradle',
      );
    }

    contents = config.modResults.contents;
    if (contents.includes('namespace "com.whipwhepdemo"')) {
      console.log('Changing namespace...');
      const updatedContents = contents.replace(
        'namespace "com.whipwhepdemo"',
        "namespace 'com.swmansion.mobilewhepclient'",
      );
      config.modResults.contents = updatedContents;
      console.log('✔ Changed namespace to com.swmansion.mobilewhepclient');
    } else {
      console.log('Namespace already changed');
    }

    return config;
  });

  config = withProjectBuildGradle(config, (config) => {
    let contents = config.modResults.contents;
    if (
      contents.includes(
        "minSdkVersion = Integer.parseInt(findProperty('android.minSdkVersion') ?: '23')",
      )
    ) {
      console.log('Changing minSdkVersion...');
      const targetVersion =
        "minSdkVersion = Integer.parseInt(findProperty('android.minSdkVersion') ?: '24')";
      const updatedContents = contents.replace(
        "minSdkVersion = Integer.parseInt(findProperty('android.minSdkVersion') ?: '23')",
        targetVersion,
      );
      config.modResults.contents = updatedContents;
      console.log('✔ Changed minSdkVersion.');
    } else {
      console.log('minSdkVersion already satisfied');
    }

    return config;
  });

  return config;
};

console.log('Registering the plugin...');
module.exports = createRunOncePlugin(
  withAndroidSettings,
  pkg.name,
  pkg.version,
);
console.log('Plugin registered successfully!');
