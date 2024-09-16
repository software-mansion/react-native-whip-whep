#!/bin/bash
set -e

echo "Running eslint for react-native javascript files \n"
eslint . --ext .ts,.tsx --fix

echo "Running prettier for react-native javascript files \n"
prettier --write . --ignore-path ./.eslintignore