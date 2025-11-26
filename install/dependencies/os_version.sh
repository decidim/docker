#!/bin/bash

if [ ! -f /etc/os-release ]; then
  echo "Error: Unable to determine OS. /etc/os-release file not found."
  echo "Installation stopped."
  exit 1
fi

cat /etc/os-release
