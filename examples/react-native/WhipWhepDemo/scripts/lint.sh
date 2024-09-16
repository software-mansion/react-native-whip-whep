#!/bin/bash
set -e

echo "Running eslint for fishjam-chat javascript files \n"
eslint . --ext .ts,.tsx --fix --max-warnings 0

echo "Running prettier for fishjam-chat javascript files \n"
prettier --write . --ignore-path ./.eslintignore