const {
  withSettingsGradle,
  createRunOncePlugin,
} = require("@expo/config-plugins");

const pkg = require("./package.json");

const withAndroidSettings = (config) => {
  return withSettingsGradle(config, (config) => {
    if (config.modResults.contents) {
      config.modResults.contents += "\ninclude ':android-client'\n";
      config.modResults.contents +=
        "project(':android-client').projectDir = new File(rootProject.projectDir, '../../../../packages/android-client/MobileWhepClient')\n";
    }
    return config;
  });
};

module.exports = createRunOncePlugin(
  withAndroidSettings,
  pkg.name,
  pkg.version,
);
