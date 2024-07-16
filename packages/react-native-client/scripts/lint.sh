#!/bin/bash
set -e

echo "Running eslint for react-native javascript files \n"
eslint . --ext .ts,.tsx --fix

echo "Running prettier for react-native javascript files \n"
prettier --write . --ignore-path ./.eslintignore

echo "Running ktlint for react-native android files \n"
cd android
ktlint -F **/*.kt
cd ..

echo "Running swift-format for react-native ios files \n"
cd ios
swift-format format -i -r ./*.swift --configuration swift-format-config.json
cd ..