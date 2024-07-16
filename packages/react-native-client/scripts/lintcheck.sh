echo "Running eslint:check for react-native javascript files \n"
eslint . --ext .ts,.tsx

echo "Running prettier:check for react-native javascript files \n"
prettier --check . --ignore-path ./.eslintignore

echo "Running ktlint:check for react-native android files \n"
cd android
ktlint **/*.kt
cd ..

echo "Running swift-format:check for react-native ios files \n"
cd ios
swift-format lint -r -s ./*.swift --configuration swift-format-config.json