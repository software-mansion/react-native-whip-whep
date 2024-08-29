const pak = require('../../../package.json');
const path = require('path');

module.exports = {
  presets: ['module:@react-native/babel-preset'],
  plugins: [
    [
      'module-resolver',
      {
        root: ['.'],
        alias: {
          [pak.name]: path.join(__dirname, '..', 'src/index.tsx'),
        },
      },
    ],
  ],
};
