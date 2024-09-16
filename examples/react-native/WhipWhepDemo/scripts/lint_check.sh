#!/bin/bash
set -e

echo "Running eslint:check for react-native javascript files \n"
eslint . --ext .ts,.tsx --max-warnings 0

echo "Running prettier:check for react-native javascript files \n"
prettier --check . --ignore-path ./.eslintignore