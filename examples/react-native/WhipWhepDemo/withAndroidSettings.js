const {
  withSettingsGradle,
  withAppBuildGradle,
  createRunOncePlugin,
} = require("@expo/config-plugins");
const fs = require("fs");
const path = require("path");

const pkg = require("./package.json");

console.log("Starting the plugin!");

const withAndroidSettings = (config) => {
  console.log("Modifying settings.gradle...");
  config = withSettingsGradle(config, (config) => {
    let contents = config.modResults.contents;

    if (!contents.includes("include ':android-client'")) {
      console.log("Adding android-client to settings.gradle");
      contents +=
        `\ninclude ':android-client'\n` +
        `project(':android-client').projectDir = new File(rootProject.projectDir, '../../../../packages/android-client/MobileWhepClient')\n`;
      config.modResults.contents = contents;
    } else {
      console.log("android-client already included in settings.gradle");
    }

    return config;
  });

  console.log("Modifying app/build.gradle...");
  config = withAppBuildGradle(config, (config) => {
    const appBuildGradlePath = path.join(
      config.modRequest.platformProjectRoot,
      "app",
      "build.gradle",
    );
    console.log("App build.gradle path:", appBuildGradlePath);

    if (fs.existsSync(appBuildGradlePath)) {
      let contents = fs.readFileSync(appBuildGradlePath, "utf-8");

      if (
        !contents.includes(
          "implementation project(':mobile-whep-react-native-client')",
        )
      ) {
        console.log(
          "Adding mobile-whep-react-native-client to app/build.gradle",
        );
        const dependenciesBlock = "dependencies {";
        const addition =
          "implementation project(':mobile-whep-react-native-client')";

        const updatedContents = contents.replace(
          dependenciesBlock,
          `${dependenciesBlock}\n    ${addition}`,
        );

        fs.writeFileSync(appBuildGradlePath, updatedContents);
      } else {
        console.log(
          "mobile-whep-react-native-client already included in app/build.gradle",
        );
      }
    } else {
      console.error(
        "app/build.gradle file does not exist:",
        appBuildGradlePath,
      );
    }

    return config;
  });

  return config;
};

console.log("Registering the plugin...");
module.exports = createRunOncePlugin(
  withAndroidSettings,
  pkg.name,
  pkg.version,
);
console.log("Plugin registered successfully!");
