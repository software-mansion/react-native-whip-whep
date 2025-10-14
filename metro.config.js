const { getDefaultConfig } = require('expo/metro-config');
const path = require('path');

// Monorepo root configuration
const monorepoRoot = __dirname;

const config = getDefaultConfig(monorepoRoot);

// Extend Expo's default watchFolders instead of overriding them
config.watchFolders = [
  ...config.watchFolders, // Keep Expo's default watch folders
  path.resolve(monorepoRoot, 'packages'),
  path.resolve(monorepoRoot, 'examples'),
];

// Resolve packages from monorepo structure
config.resolver.nodeModulesPaths = [
  path.resolve(monorepoRoot, 'node_modules'),
];

// Enable package exports for better module resolution
config.resolver.unstable_enablePackageExports = true;

// Platform support
config.resolver.platforms = ['ios', 'android', 'native', 'web'];

// Performance optimizations
config.maxWorkers = require('os').cpus().length;

// Asset handling
config.transformer.assetPlugins = ['expo-asset/tools/hashAssetFiles'];

module.exports = config;
