const {
  withDangerousMod,
  createRunOncePlugin,
} = require("@expo/config-plugins");
const fs = require("fs");
const path = require("path");

const pkg = require("./package.json");

const withIosPodfile = (config) => {
  return withDangerousMod(config, [
    "ios",
    async (config) => {
      const podfilePath = path.join(
        config.modRequest.platformProjectRoot,
        "Podfile",
      );
      const podfileContent = fs.readFileSync(podfilePath, "utf-8");

      // Check if the line is already added
      if (
        !podfileContent.includes(
          "pod 'MobileWhepClient', :path => '../../../../'",
        )
      ) {
        const updatedPodfileContent =
          podfileContent +
          "\npod 'MobileWhepClient', :path => '../../../../'\n";
        fs.writeFileSync(podfilePath, updatedPodfileContent);
      }

      return config;
    },
  ]);
};

module.exports = createRunOncePlugin(withIosPodfile, pkg.name, pkg.version);
