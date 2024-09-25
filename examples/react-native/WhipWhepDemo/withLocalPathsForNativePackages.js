const {
  withSettingsGradle,
  withAppBuildGradle,
  createRunOncePlugin,
  withPodfile,
} = require('@expo/config-plugins');
const fs = require('fs');
const path = require('path');

const pkg = require('./package.json');

const withLocalPathsForNativePackages = (config) => {
  config = withSettingsGradle(config, (config) => {
    let contents = config.modResults.contents;

    if (!contents.includes("include ':android-client'")) {
      console.log('Adding android-client to settings.gradle...');
      contents +=
        `\ninclude ':android-client'\n` +
        `project(':android-client').projectDir = new File(rootProject.projectDir, '../../../../packages/android-client/MobileWhepClient')\n`;
      config.modResults.contents = contents;
      console.log('\x1b[32m✔\x1b[0m Added android-client to settings.gradle.');
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
        '\x1b[32m✔\x1b[0m Added mobile-whep-react-native-client to app/build.gradle.',
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
      console.log(
        '\x1b[32m✔\x1b[0m Changed namespace to com.swmansion.mobilewhepclient',
      );
    } else {
      console.log('Namespace already changed');
    }

    return config;
  });

  config = withPodfile(config, (config) => {
    let podfile = config.modResults.contents;
    console.log('Adding MobileWhepClient pod to Podfile...');

    const mainAppTarget = /target ['"]WhipWhepDemo['"] do/g;
    const podToAdd = `pod 'MobileWhepClient', :path => '../../../../'`;

    podfile = podfile.replace(mainAppTarget, (match) => {
      return `${match}\n${podToAdd}`;
    });

    config.modResults.contents = podfile;
    console.log('\x1b[32m✔\x1b[0m MobileWhepClient added.');
    return config;
  });

  return config;
};

module.exports = createRunOncePlugin(
  withLocalPathsForNativePackages,
  pkg.name,
  pkg.version,
);
