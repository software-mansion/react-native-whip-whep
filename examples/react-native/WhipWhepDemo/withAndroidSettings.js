const {
  withSettingsGradle,
  createRunOncePlugin,
} = require("@expo/config-plugins");

const pkg = require("./package.json");

const withAndroidSettings = (config) => {
  config = withSettingsGradle(config, (config) => {
    if (config.modResults.contents) {
      config.modResults.contents += "\ninclude ':android-client'\n";
      config.modResults.contents +=
        "project(':android-client').projectDir = new File(rootProject.projectDir, '../../../../packages/android-client/MobileWhepClient')\n";
    }
    return config;
  });

  config = withAppBuildGradle(config, (config) => {
    if (
      !config.modResults.contents.includes(
        "implementation project(':mobile-whep-react-native-client')",
      )
    ) {
      const dependenciesBlock = "dependencies {";
      const addition =
        "implementation project(':mobile-whep-react-native-client')";

      const updatedContents = config.modResults.contents.replace(
        dependenciesBlock,
        `${dependenciesBlock}\n    ${addition}`,
      );

      config.modResults.contents = updatedContents;
    }
    return config;
  });

  return config;
};

module.exports = createRunOncePlugin(
  withAndroidSettings,
  pkg.name,
  pkg.version,
);
