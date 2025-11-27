#!/bin/bash

echo "───────────────────────────────────────────────"
echo "Now we are going to make sure that this distribution"
echo "is based on Debian/Ubuntu."

if [ $(uname) != "Linux" ]; then
  echo "This installation process must be run on Linux"
  exit 1
fi

if [ ! -n $(lsb_release -d | grep Ubuntu/Debian) ]; then
  echo "This installation process must be run on a Debian/Ubuntu distribution."
  exit 1
fi

echo "Correct distribution."
